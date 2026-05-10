from __future__ import annotations

from pathlib import Path

import joblib
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score
from sklearn.model_selection import train_test_split
from sklearn.multioutput import MultiOutputClassifier
from sklearn.feature_extraction.text import TfidfVectorizer

try:
    from src.labels import BOOL_COLUMNS, LABEL_COLUMNS
except ModuleNotFoundError:
    from labels import BOOL_COLUMNS, LABEL_COLUMNS


ROOT = Path(__file__).resolve().parents[1]
DATASET_PATH = ROOT / "data" / "community_action_dataset.csv"
MODEL_PATH = ROOT / "models" / "community_action_planner.joblib"

POST_COLUMNS = ["postNature", "targetAudience", "postInputMode", "locationSharingMode", "dangerLevel"]
HELP_COLUMNS = ["helpType", "requesterProfile", "helpInputMode", "presetMessageKey"]


def _to_bool_hint(v: str | int | bool) -> str:
    if isinstance(v, bool):
        return "yes" if v else "no"
    s = str(v).strip().lower()
    return "yes" if s in {"1", "true", "yes"} else "no"


def _parse_bool_value(v: str | int | bool) -> str:
    if isinstance(v, bool):
        return "true" if v else "false"
    s = str(v).strip().lower()
    if s in {"1", "true", "yes", "y"}:
        return "true"
    return "false"


def normalize_dataset(df: pd.DataFrame) -> pd.DataFrame:
    df = df.fillna("")

    # Harmonize old placeholder values.
    df = df.replace({"na": "none", "NA": "none"})

    for c in BOOL_COLUMNS:
        df[c] = df[c].apply(_parse_bool_value)

    # Normalize irrelevant columns by action type.
    post_mask = df["actionType"] == "create_post"
    help_mask = df["actionType"] == "create_help_request"

    for c in HELP_COLUMNS:
        df.loc[post_mask, c] = "none"
    for c in POST_COLUMNS:
        df.loc[help_mask, c] = "none"

    # If any label column is still empty, fallback to "none".
    for c in LABEL_COLUMNS:
        df[c] = df[c].astype(str).str.strip()
        df.loc[df[c] == "", c] = "none"

    return df


def build_feature_text(row: pd.Series) -> str:
    text = str(row.get("text", "")).lower().strip()
    mode_hint = str(row.get("inputModeHint", "")).strip()
    another_hint = _to_bool_hint(row.get("isForAnotherPersonHint", 0))
    return f"{text} | input_mode_hint:{mode_hint} | for_another_person_hint:{another_hint}"


def main() -> None:
    if not DATASET_PATH.exists():
        raise FileNotFoundError(f"Dataset not found: {DATASET_PATH}")

    df = pd.read_csv(DATASET_PATH)
    df = normalize_dataset(df)
    missing = [c for c in LABEL_COLUMNS if c not in df.columns]
    if missing:
        raise ValueError(f"Missing label columns: {missing}")

    X_text = df.apply(build_feature_text, axis=1)
    y = df[LABEL_COLUMNS]

    X_train, X_test, y_train, y_test = train_test_split(
        X_text, y, test_size=0.25, random_state=42
    )

    vectorizer = TfidfVectorizer(ngram_range=(1, 2), min_df=1)
    X_train_vec = vectorizer.fit_transform(X_train)
    X_test_vec = vectorizer.transform(X_test)

    clf = MultiOutputClassifier(
        RandomForestClassifier(
            n_estimators=250,
            random_state=42,
            class_weight="balanced_subsample",
        )
    )
    clf.fit(X_train_vec, y_train)

    preds = clf.predict(X_test_vec)
    pred_df = pd.DataFrame(preds, columns=LABEL_COLUMNS, index=y_test.index)

    exact_match = (pred_df.values == y_test.values).all(axis=1).mean()
    print(f"Exact match accuracy: {exact_match:.3f}")

    for c in LABEL_COLUMNS:
        acc = accuracy_score(y_test[c], pred_df[c])
        print(f"{c:24s} accuracy: {acc:.3f}")

    MODEL_PATH.parent.mkdir(parents=True, exist_ok=True)
    artifact = {
        "vectorizer": vectorizer,
        "classifier": clf,
        "label_columns": LABEL_COLUMNS,
        "bool_columns": BOOL_COLUMNS,
        "version": "community-action-planner-v1",
    }
    joblib.dump(artifact, MODEL_PATH)
    print(f"Saved model to: {MODEL_PATH}")


if __name__ == "__main__":
    main()

