from __future__ import annotations

import sys
import unicodedata
from pathlib import Path
from typing import Any

import pandas as pd

try:
    from src.labels import (
        ACTION_LABELS,
        BOOL_COLUMNS,
        DANGER_LEVEL_LABELS,
        HELP_INPUT_MODE_LABELS,
        HELP_ONLY_COLUMNS,
        HELP_TYPE_LABELS,
        LABEL_COLUMNS,
        LOCATION_SHARING_MODE_LABELS,
        POST_INPUT_MODE_LABELS,
        POST_NATURE_LABELS,
        POST_ONLY_COLUMNS,
        POST_TARGET_AUDIENCE_LABELS,
        PRESET_MESSAGE_KEY_LABELS,
        REQUESTER_PROFILE_LABELS,
    )
except ModuleNotFoundError:
    from labels import (
        ACTION_LABELS,
        BOOL_COLUMNS,
        DANGER_LEVEL_LABELS,
        HELP_INPUT_MODE_LABELS,
        HELP_ONLY_COLUMNS,
        HELP_TYPE_LABELS,
        LABEL_COLUMNS,
        LOCATION_SHARING_MODE_LABELS,
        POST_INPUT_MODE_LABELS,
        POST_NATURE_LABELS,
        POST_ONLY_COLUMNS,
        POST_TARGET_AUDIENCE_LABELS,
        PRESET_MESSAGE_KEY_LABELS,
        REQUESTER_PROFILE_LABELS,
    )


ROOT = Path(__file__).resolve().parents[1]
DATASET_PATH = ROOT / "data" / "community_action_dataset.csv"

TEXT_COLUMNS = ["text", "inputModeHint", "isForAnotherPersonHint"]
REQUIRED_COLUMNS = [*TEXT_COLUMNS, *LABEL_COLUMNS]
EXPECTED_COLUMNS = set(REQUIRED_COLUMNS)
EMPTY_PLACEHOLDERS = {"", "none", "na", "unknown", "null", "n/a"}
BOOL_LIKE = {"true", "false", "1", "0", "yes", "no", "y", "n"}
INVISIBLE_CHARS = {
    "\u200b",  # zero width space
    "\u200c",  # zero width non-joiner
    "\u200d",  # zero width joiner
    "\ufeff",  # byte order mark
    "\u2060",  # word joiner
}

ENUM_RULES: dict[str, set[str]] = {
    "actionType": set(ACTION_LABELS),
    "postNature": set(POST_NATURE_LABELS),
    "targetAudience": set(POST_TARGET_AUDIENCE_LABELS),
    "postInputMode": set(POST_INPUT_MODE_LABELS),
    "locationSharingMode": set(LOCATION_SHARING_MODE_LABELS),
    "dangerLevel": set(DANGER_LEVEL_LABELS),
    "helpType": set(HELP_TYPE_LABELS),
    "requesterProfile": set(REQUESTER_PROFILE_LABELS),
    "helpInputMode": set(HELP_INPUT_MODE_LABELS),
    "presetMessageKey": set(PRESET_MESSAGE_KEY_LABELS),
}


def _norm(v: Any) -> str:
    if pd.isna(v):
        return ""
    s = str(v)
    s = unicodedata.normalize("NFKC", s)
    s = "".join(ch for ch in s if ch not in INVISIBLE_CHARS)
    s = s.strip()
    return s.lower()


ENUM_RULES_NORM: dict[str, set[str]] = {
    col: {_norm(v) for v in allowed} for col, allowed in ENUM_RULES.items()
}


def _is_bool_like(v: Any) -> bool:
    return _norm(v) in BOOL_LIKE


def _is_placeholder(v: Any) -> bool:
    return _norm(v) in EMPTY_PLACEHOLDERS


def _canonical_label_value_for_compare(col: str, v: Any) -> str:
    """
    Normalize label cell values so duplicate-text rows compare consistently.
    Bool-like columns map to 'true' or 'false' (aligned with train_model parsing).
    Other columns use _norm (NFKC, lower, strip, drop invisible chars).
    """
    if col in BOOL_COLUMNS:
        if isinstance(v, bool):
            return "true" if v else "false"
        s = _norm(v)
        if s in {"1", "true", "yes", "y"}:
            return "true"
        if s in {"0", "false", "no", "n"}:
            return "false"
        return s
    return _norm(v)


def find_duplicate_text_label_contradictions(df: pd.DataFrame) -> list[str]:
    """
    Rows that share the same normalized `text` must agree on every column in LABEL_COLUMNS.
    Returns human-readable error strings (CSV row numbers are 1-based including header row).
    """
    errors: list[str] = []
    if "text" not in df.columns:
        return errors

    label_cols = [c for c in LABEL_COLUMNS if c in df.columns]
    if not label_cols:
        return errors

    keys = df["text"].map(_norm)
    for key, indices in df.groupby(keys).groups.items():
        idx_list = list(indices)
        if len(idx_list) < 2:
            continue

        conflicting: list[tuple[str, dict[int, str]]] = []
        for col in label_cols:
            per_row = {
                int(i): _canonical_label_value_for_compare(col, df.at[i, col]) for i in idx_list
            }
            if len(set(per_row.values())) > 1:
                conflicting.append((col, per_row))

        if not conflicting:
            continue

        csv_rows = sorted(int(i) + 2 for i in idx_list)
        parts: list[str] = [
            "[duplicate_text_contradiction]",
            f"normalized_text={key!r}",
            f"csv_rows={csv_rows}",
        ]
        for col, per_row in conflicting:
            detail = " ".join(
                f"row_{int(i) + 2}={per_row[i]!r}" for i in sorted(per_row.keys())
            )
            parts.append(f"column={col}: {detail}")
        errors.append(" ".join(parts))

    return errors


def _action_balance_ok(action_counts: dict[str, int], total_rows: int) -> tuple[bool, str]:
    post_n = action_counts.get("create_post", 0)
    help_n = action_counts.get("create_help_request", 0)
    if post_n == 0 or help_n == 0:
        return False, "One action class is missing."

    diff = abs(post_n - help_n)
    allowed_gap = max(5, int(total_rows * 0.20))
    if diff > allowed_gap:
        return (
            False,
            f"Action distribution too imbalanced: diff={diff}, allowed_gap={allowed_gap}.",
        )
    return True, "Balanced enough."


def validate_dataset(df: pd.DataFrame) -> tuple[list[str], list[str], dict[str, int]]:
    header_errors: list[str] = []
    row_errors: list[str] = []

    missing = [c for c in REQUIRED_COLUMNS if c not in df.columns]
    unexpected = sorted([c for c in df.columns if c not in EXPECTED_COLUMNS])
    if missing:
        header_errors.append(f"Missing required columns: {missing}")
    if unexpected:
        header_errors.append(f"Unexpected columns: {unexpected}")

    # If columns are broken, still try best-effort row checks on intersection.
    cols_available = set(df.columns)

    # Generic enum checks
    for col, allowed in ENUM_RULES_NORM.items():
        if col not in cols_available:
            continue
        for idx, v in df[col].items():
            value = _norm(v)
            if value not in allowed:
                row_errors.append(
                    " ".join(
                        [
                            f"row={idx + 2}",
                            f"col={col}: invalid value",
                            f"raw={v!r}",
                            f"normalized={value!r}",
                            f"allowed_normalized={sorted(allowed)!r}",
                        ]
                    )
                )

    # Boolean checks
    for col in BOOL_COLUMNS:
        if col not in cols_available:
            continue
        for idx, v in df[col].items():
            if not _is_bool_like(v):
                row_errors.append(
                    f"row={idx + 2} col={col}: invalid boolean-like value '{v}'"
                )

    if "isForAnotherPersonHint" in cols_available:
        for idx, v in df["isForAnotherPersonHint"].items():
            if not _is_bool_like(v):
                row_errors.append(
                    f"row={idx + 2} col=isForAnotherPersonHint: invalid boolean-like value '{v}'"
                )

    # Action-specific checks
    if "actionType" in cols_available:
        for idx, action in df["actionType"].items():
            action_n = _norm(action)

            if action_n == "create_post":
                # post fields: enum validity is already checked globally.
                # Do not force "non-empty" because some valid values are "none"
                # (e.g. locationSharingMode, dangerLevel).
                # help fields should be none/placeholder
                for c in HELP_ONLY_COLUMNS:
                    if c not in cols_available:
                        continue
                    if not _is_placeholder(df.at[idx, c]):
                        row_errors.append(
                            f"row={idx + 2}: action=create_post expects '{c}' as none/empty, got '{df.at[idx, c]}'"
                        )

            elif action_n == "create_help_request":
                # help fields: enum validity is already checked globally.
                # Do not force non-empty because "none" can be an accepted placeholder
                # depending on data preparation stage.
                for c in POST_ONLY_COLUMNS:
                    if c not in cols_available:
                        continue
                    if not _is_placeholder(df.at[idx, c]):
                        row_errors.append(
                            f"row={idx + 2}: action=create_help_request expects '{c}' as none/empty, got '{df.at[idx, c]}'"
                        )

    row_errors.extend(find_duplicate_text_label_contradictions(df))

    action_counts: dict[str, int] = {}
    if "actionType" in cols_available:
        action_counts = {k: int(v) for k, v in df["actionType"].value_counts().to_dict().items()}

    return header_errors, row_errors, action_counts


def main() -> int:
    if not DATASET_PATH.exists():
        print(f"[ERROR] Dataset not found: {DATASET_PATH}")
        return 2

    df = pd.read_csv(DATASET_PATH)

    header_errors, row_errors, action_counts = validate_dataset(df)
    total_rows = len(df)
    invalid_rows = len({e.split()[0] for e in row_errors})  # row=...

    print("=== Community Action Dataset Validation Report ===")
    print(f"Dataset: {DATASET_PATH}")
    print(f"Total rows: {total_rows}")
    print("Action counts:")
    print(f"  - create_post: {action_counts.get('create_post', 0)}")
    print(f"  - create_help_request: {action_counts.get('create_help_request', 0)}")

    balance_ok, balance_msg = _action_balance_ok(action_counts, total_rows)
    print(f"Balance check: {'OK' if balance_ok else 'FAIL'} - {balance_msg}")

    print(f"Header errors: {len(header_errors)}")
    print(f"Invalid rows count: {invalid_rows}")
    print(f"Detailed row error lines: {len(row_errors)}")
    dup_txt_contra = sum(
        1 for e in row_errors if "[duplicate_text_contradiction]" in e
    )
    if dup_txt_contra:
        print(f"Duplicate-text label contradictions: {dup_txt_contra}")

    if header_errors:
        print("\nHeader issues:")
        for e in header_errors[:20]:
            print(f"  - {e}")

    if row_errors:
        print("\nSample row errors (up to 25):")
        priority = [e for e in row_errors if "[duplicate_text_contradiction]" in e]
        rest = [e for e in row_errors if e not in priority]
        for e in (priority + rest)[:25]:
            print(f"  - {e}")

    failed = bool(header_errors or row_errors or not balance_ok)
    if failed:
        print("\n[FAIL] Dataset validation failed.")
        return 1

    print("\n[OK] Dataset validation passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

