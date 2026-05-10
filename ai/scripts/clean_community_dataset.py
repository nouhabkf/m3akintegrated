"""
Remove redundant (var N) duplicate rows and replace with semantically distinct help examples.
Preserves schema and validation rules from labels.py / validate_dataset.py.
"""
from __future__ import annotations

import csv
import re
import sys
import unicodedata
from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
DATA_PATH = ROOT / "data" / "community_action_dataset.csv"

VAR_SUFFIX = re.compile(r"\s*\(var\s+\d+\)\s*$", re.IGNORECASE)

VALID_HINTS = [
    "keyboard",
    "voice",
    "headEyes",
    "vibration",
    "deafBlind",
    "caregiver",
    "text",
    "tap",
    "haptic",
    "volume_shortcut",
]


def _norm(s: str) -> str:
    return unicodedata.normalize("NFKC", str(s)).strip().lower()


def _bf(x: bool) -> str:
    return "true" if x else "false"


def replacement_help_rows() -> list[dict]:
    """26 new create_help_request rows: distinct texts, mostly standard French, few informal."""
    specs: list[tuple[str, str, str, str, str, bool]] = [
        (
            "je cherche la billetterie accessible au niveau zero",
            "orientation",
            "visual",
            "text",
            "lost",
            False,
        ),
        (
            "difficulte a rejoindre le quai en fauteuil besoin chemin plat",
            "orientation",
            "motor",
            "voice",
            "lost",
            False,
        ),
        (
            "hall aeroport sens unique je ne trouve pas la correspondance",
            "orientation",
            "unknown",
            "tap",
            "lost",
            False,
        ),
        (
            "porte automatique trop lente je reste bloque au milieu",
            "mobility",
            "motor",
            "haptic",
            "blocked",
            False,
        ),
        (
            "mon fils en fauteuil ne peut pas passer le tourniquet",
            "mobility",
            "caregiver",
            "caregiver",
            "cannot_reach",
            True,
        ),
        (
            "pente provisoire tres glissante sans main courante",
            "unsafe_access",
            "motor",
            "voice",
            "blocked",
            False,
        ),
        (
            "corridor mal eclaire je ne vois pas le sol correctement",
            "unsafe_access",
            "visual",
            "voice",
            "blocked",
            False,
        ),
        (
            "besoin video en langue des signes pour annonces de retard",
            "communication",
            "hearing",
            "text",
            "cannot_reach",
            False,
        ),
        (
            "procedure administrative trop longue merci de reformuler simplement",
            "communication",
            "cognitive",
            "voice",
            "cannot_reach",
            False,
        ),
        (
            "reaction allergique qui gonfle vite besoin avis medical",
            "medical",
            "unknown",
            "voice",
            "medical_urgent",
            False,
        ),
        (
            "personne agee desorientee merci raccompagnement jusqu a la sortie",
            "escort",
            "cognitive",
            "caregiver",
            "escort",
            False,
        ),
        (
            "besoin aide pour transfert du fauteuil vers le siege du taxi",
            "escort",
            "caregiver",
            "caregiver",
            "escort",
            True,
        ),
        (
            "panneau ecrit trop petit impossible a lire a distance",
            "orientation",
            "visual",
            "voice",
            "lost",
            False,
        ),
        (
            "tapis roulant arrete entre deux niveaux je suis bloque",
            "mobility",
            "motor",
            "volume_shortcut",
            "blocked",
            False,
        ),
        (
            "correspondance bus mal indiquee sur le plan papier",
            "orientation",
            "unknown",
            "text",
            "lost",
            False,
        ),
        (
            "guichet sans boucle magnetique audible pour mon appareil",
            "communication",
            "hearing",
            "tap",
            "cannot_reach",
            False,
        ),
        (
            "chute recente douleur au poignet besoin evaluation rapide",
            "medical",
            "unknown",
            "tap",
            "medical_urgent",
            False,
        ),
        (
            "carrefour large sans signal sonore aide pour traverser",
            "escort",
            "visual",
            "voice",
            "escort",
            False,
        ),
        (
            "ecart entre quai et train trop large avec fente dangereuse",
            "unsafe_access",
            "motor",
            "text",
            "blocked",
            False,
        ),
        (
            "question horaires navette PMR sans urgence vitale",
            "other",
            "unknown",
            "text",
            "none",
            False,
        ),
        (
            "annonces incomprehensibles merci repetition ecrite si possible",
            "orientation",
            "hearing",
            "voice",
            "lost",
            False,
        ),
        (
            "ascenseur trop petit pour chariot medical et patient ensemble",
            "mobility",
            "motor",
            "text",
            "cannot_reach",
            False,
        ),
        (
            "formulaire tres long merci aide pour remplir case par case",
            "communication",
            "cognitive",
            "text",
            "cannot_reach",
            False,
        ),
        (
            "montee raide jusqu a lentree secours besoin poussette fauteuil",
            "escort",
            "motor",
            "caregiver",
            "escort",
            False,
        ),
        (
            "zone travaux sans detour signale pour fauteuil bonjour",
            "unsafe_access",
            "motor",
            "voice",
            "blocked",
            False,
        ),
        (
            "svp ya denivele jarrive pas monter seul aide mobilité",
            "mobility",
            "motor",
            "text",
            "blocked",
            False,
        ),
    ]

    rows: list[dict] = []
    for i, (text, ht, rp, hm, pk, for_other) in enumerate(specs):
        hint = VALID_HINTS[i % len(VALID_HINTS)]
        na = ht == "orientation" and rp == "visual"
        nv = rp == "visual"
        np = rp == "motor"
        ns = rp == "cognitive" or i % 4 == 0
        rows.append(
            {
                "text": text[:500],
                "inputModeHint": hint,
                "isForAnotherPersonHint": _bf(for_other),
                "actionType": "create_help_request",
                "postNature": "none",
                "targetAudience": "none",
                "postInputMode": "none",
                "locationSharingMode": "none",
                "dangerLevel": "none",
                "helpType": ht,
                "requesterProfile": rp,
                "helpInputMode": hm,
                "presetMessageKey": pk,
                "needsAudioGuidance": _bf(na),
                "needsVisualSupport": _bf(nv),
                "needsPhysicalAssistance": _bf(np),
                "needsSimpleLanguage": _bf(ns),
                "isForAnotherPerson": _bf(for_other),
            }
        )
    return rows


def main() -> int:
    if not DATA_PATH.exists():
        print(f"Missing {DATA_PATH}", file=sys.stderr)
        return 2

    df = pd.read_csv(DATA_PATH)
    before = len(df)

    mask_var = df["text"].astype(str).apply(lambda s: bool(VAR_SUFFIX.search(s)))
    removed = int(mask_var.sum())

    df_clean = df.loc[~mask_var].copy()

    new_rows = pd.DataFrame(replacement_help_rows())
    existing_norm = {_norm(t) for t in df_clean["text"].astype(str)}
    for t in new_rows["text"]:
        if _norm(t) in existing_norm:
            print(f"[ERROR] replacement text collides with existing: {t!r}", file=sys.stderr)
            return 1
        existing_norm.add(_norm(t))

    out = pd.concat([df_clean, new_rows], ignore_index=True)

    post_n = int((out["actionType"] == "create_post").sum())
    help_n = int((out["actionType"] == "create_help_request").sum())
    if post_n != help_n:
        print(f"[ERROR] balance broken: post={post_n} help={help_n}", file=sys.stderr)
        return 1

    out["_t"] = out["text"].astype(str).map(_norm)
    dup_ct = out["_t"].duplicated(keep=False).sum()
    if dup_ct:
        print(f"[ERROR] duplicate normalized texts remain: {dup_ct}", file=sys.stderr)
        return 1
    out = out.drop(columns=["_t"])

    out.to_csv(
        DATA_PATH,
        index=False,
        quoting=csv.QUOTE_ALL,
        lineterminator="\n",
        encoding="utf-8",
    )

    print(f"Removed {removed} redundant (var N) rows; added {len(new_rows)} distinct replacements.")
    print(f"Rows before: {before}, after: {len(out)}")
    print(f"create_post: {post_n}, create_help_request: {help_n}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
