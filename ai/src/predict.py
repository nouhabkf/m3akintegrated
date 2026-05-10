from __future__ import annotations

import argparse
import logging
import re
import unicodedata
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import joblib
import pandas as pd

try:
    from src.labels import BOOL_COLUMNS, HELP_ONLY_COLUMNS, POST_ONLY_COLUMNS
except ModuleNotFoundError:
    from labels import BOOL_COLUMNS, HELP_ONLY_COLUMNS, POST_ONLY_COLUMNS

logger = logging.getLogger(__name__)

ROOT = Path(__file__).resolve().parents[1]
MODEL_PATH = ROOT / "models" / "community_action_planner.joblib"

POST_INPUT_MODES = {"keyboard", "voice", "headEyes", "vibration", "deafBlind", "caregiver"}
HELP_INPUT_MODES = {"text", "voice", "tap", "haptic", "volume_shortcut", "caregiver"}

# --- Hybrid layer ---
_STRONG_INTENT = 0.62
_MARGIN = 0.14
_LOCATION_DOMINANCE = 0.12

# --- Confidence heuristics (NOT calibrated probabilities; UI navigation hints) ---
_AUTO_NAV_FLOOR = 0.85  # aligns with Flutter shouldAutoNavigate default
_AMBIGUOUS_NAV_CAP = 0.58
_CONFIRMATION_NAV_CAP = 0.72


def _clamp(x: float, lo: float = 0.0, hi: float = 1.0) -> float:
    return float(max(lo, min(hi, x)))


def _to_bool(value: Any) -> bool:
    if isinstance(value, bool):
        return value
    if value is None:
        return False
    s = str(value).strip().lower()
    return s in {"1", "true", "yes", "y"}


def _normalize_for_match(text: str) -> str:
    """NFKC + lowercase + collapse whitespace."""
    s = unicodedata.normalize("NFKC", text)
    s = "".join(ch for ch in s if unicodedata.category(ch) != "Cf" or ch in {" ", "\n"})
    s = s.lower().strip()
    s = re.sub(r"\s+", " ", s)
    return s


def _norm_label(v: Any) -> str:
    if v is None:
        return ""
    return str(v).strip().lower()


def _strip_outer_punctuation(s: str) -> str:
    return re.sub(r"^[\s\.\!\?…,:;]+|[\s\.\!\?…,:;]+$", "", s).strip()


def _is_standalone_visual_profile_only(normalized_text: str) -> bool:
    t = _strip_outer_punctuation(normalized_text.strip())
    if len(t) > 56:
        return False
    return t in _STANDALONE_VISUAL_PROFILE_ONLY


def _mentions_visual_impairment_for_routing(normalized_text: str) -> bool:
    n = normalized_text
    if any(p in n for p in _VISUAL_IMPAIRMENT_PROFILE_PHRASES):
        return True
    return any(p in n for p in _TUNISIAN_CANT_SEE_PHRASES)


def _wants_photo_post_content(normalized_text: str) -> bool:
    n = normalized_text
    if any(p in n for p in ("nhabet taswira", "nhab taswira", "nhbt taswira", "nb3th taswira")):
        return True
    if any(
        p in n
        for p in (
            "je veux poster une photo",
            "poster une photo",
            "publier une photo",
            "envoyer une photo",
            "envoyer une image",
        )
    ):
        return True
    if "taswira" in n:
        return True
    if ("photo" in n or "image" in n) and any(
        x in n for x in ("poster", "publier", "veux envoyer", "envoyer", "veux")
    ):
        return True
    return False


def _wants_place_or_obstacle_report(normalized_text: str) -> bool:
    n = normalized_text
    if any(p in n for p in _PLACE_OR_OBSTACLE_REPORT_PHRASES):
        return True
    if ("place" in n or "lieu" in n) and any(
        x in n
        for x in (
            "signa",
            "obstacle",
            "inaccessible",
            "problème",
            "probleme",
            "bloque",
            "bloqué",
            "dangereux",
        )
    ):
        return True
    return False


def _visual_impairment_photo_or_place_signalement(normalized_text: str) -> bool:
    """Déficience visuelle explicite + photo ou signalement — parcours tête / yeux."""
    if _is_standalone_visual_profile_only(normalized_text):
        return False
    if not _mentions_visual_impairment_for_routing(normalized_text):
        return False
    return _wants_photo_post_content(normalized_text) or _wants_place_or_obstacle_report(
        normalized_text
    )


def _visual_impairment_voice_post_compound(normalized_text: str) -> bool:
    """
    Profil déficience visuelle + texte (pas phrase seule, pas parcours photo/signalement).
    → publication en dictée vocale (/create-post-voice-vibration).
    Ex. « ma nchoufech besoin pharmacie », « non voyante je veux un conseil ».
    """
    if _is_standalone_visual_profile_only(normalized_text):
        return False
    if _visual_impairment_photo_or_place_signalement(normalized_text):
        return False
    return _mentions_visual_impairment_for_routing(normalized_text)


def _apply_post_input_mode_accessibility_rules(
    out: dict[str, Any],
    *,
    normalized_text: str,
    input_mode_hint: str | None,
) -> None:
    """Sans indice client, oriente dictée vocale vs tête/yeux selon le libellé."""
    hint = (input_mode_hint or "").strip()
    if hint in POST_INPUT_MODES:
        return
    n = normalized_text
    if _is_standalone_visual_profile_only(n):
        out["postInputMode"] = "voice"
    elif _visual_impairment_photo_or_place_signalement(n):
        out["postInputMode"] = "headEyes"
    elif _visual_impairment_voice_post_compound(n):
        out["postInputMode"] = "voice"


# --- Accessibility flags: rule refinement (model first; rules adjust over/under-shooting) ---

_SIMPLE_LANGUAGE_PHRASES: tuple[str, ...] = (
    "langage simple",
    "phrases simples",
    "phrase simple",
    "plus simple",
    "expliquez simplement",
    "explique simplement",
    "expliquez moi simplement",
    "explique moi simplement",
    "je comprends pas",
    "j ai pas compris",
    "j'ai pas compris",
    "jarrive pas comprendre",
    "j'arrive pas à comprendre",
    "trop complique",
    "trop compliqué",
    "sans jargon",
    "avec des mots simples",
    "besoin de simplicité",
    "difficulte a comprendre",
    "difficulté à comprendre",
    "dites moi simplement",
    "dites le moi simplement",
)

_PHYSICAL_ASSIST_PHRASES: tuple[str, ...] = (
    "bloque",
    "bloqué",
    "bklé",
    "coince",
    "coincé",
    "escalier",
    "escaliers",
    "marche",
    "marches",
    "impossible d entrer",
    "impossible entrer",
    "pas acces",
    "pas d acces",
    "jarrive pas monter",
    "j'arrive pas à monter",
    "fauteuil",
    "roulant",
    "mobilite",
    "mobilité",
    "rampe",
    "seuil",
    "porte etroite",
    "porte étroite",
    "tourniquet",
)

_AUDIO_GUIDANCE_PHRASES: tuple[str, ...] = (
    "perdu",
    "perdue",
    "orientation",
    "je cherche",
    "ou est",
    "où est",
    "guide vocal",
    "guidage vocal",
    "pas entendu",
    "annonce",
    "bande sonore",
    "feu sonore",
)

# Déficience visuelle — oriente guidage audio / interface parlée (distinct du bloc LSF ci-dessous).
_VISUAL_IMPAIRMENT_PROFILE_PHRASES: tuple[str, ...] = (
    "non voyant",
    "non voyante",
    "non-voyant",
    "non-voyante",
    "malvoyant",
    "malvoyante",
    "mal voyant",
    "mal voyante",
    "aveugle",
    "deficience visuelle",
    "déficience visuelle",
    "handicap visuel",
)

# Tunisien — « je ne vois pas » / perception visuelle (aligné entrée vocale courte).
_TUNISIAN_CANT_SEE_PHRASES: tuple[str, ...] = (
    "ma nchoufech",
    "man nchoufech",
    "ma nchoufch",
    "manchoufech",
    "ma nchoufich",
    "man nchoufich",
)

# Message réduit au profil visuel uniquement → parcours dictée vocale (pas tête / yeux).
_STANDALONE_VISUAL_PROFILE_ONLY: frozenset[str] = frozenset(
    {
        "non voyant",
        "non voyante",
        "non-voyant",
        "non-voyante",
        "malvoyant",
        "malvoyante",
        "mal voyant",
        "mal voyante",
        "aveugle",
        "deficience visuelle",
        "déficience visuelle",
        "handicap visuel",
        *_TUNISIAN_CANT_SEE_PHRASES,
    }
)

# Signalement (FR + formulations orales tunisiennes).
_PLACE_OR_OBSTACLE_REPORT_PHRASES: tuple[str, ...] = (
    "signalement",
    "signaler",
    "obstacle",
    "je veux signaler",
    "signaler un obstacle",
    "signaler une place",
    "signaler le lieu",
    "problème d accès",
    "problème d'accès",
    "place inaccessible",
    "lieu inaccessible",
    "njm3lem",
    "njem3lem",
    "nheb nsn3el",
    "n7eb nsn3el",
    "norbet",
)

_VISUAL_SUPPORT_PHRASES: tuple[str, ...] = (
    "sourd",
    "sourde",
    "surdi",
    "malentendant",
    "lsf",
    "sous-titre",
    "sous titres",
    "langue des signes",
    "boucle magnetique",
    "boucle magnétique",
    "communication ecrite",
    "communication écrite",
)


def refine_accessibility_booleans(
    out: dict[str, Any],
    *,
    action: str,
    normalized_text: str,
    label_snapshot: dict[str, Any],
    input_mode_hint: str | None,
    context_hint: str | None,
) -> None:
    """
    Second-pass refinement on ML booleans using wording + label context.
    Call after final `action` is known, before clearing inactive-branch label columns.
    """
    ml_audio = bool(out.get("needsAudioGuidance"))
    ml_visual = bool(out.get("needsVisualSupport"))
    ml_phys = bool(out.get("needsPhysicalAssistance"))
    ml_simple = bool(out.get("needsSimpleLanguage"))

    ta = _norm_label(label_snapshot.get("targetAudience"))
    pn = _norm_label(label_snapshot.get("postNature"))
    ht = _norm_label(label_snapshot.get("helpType"))
    rp = _norm_label(label_snapshot.get("requesterProfile"))
    pmk = _norm_label(label_snapshot.get("presetMessageKey"))
    mode = (input_mode_hint or "").strip().lower()
    ctx = (context_hint or "").strip().lower()

    n = normalized_text

    # --- needsSimpleLanguage: avoid ML defaulting to true without support ---
    simple_explicit = any(p in n for p in _SIMPLE_LANGUAGE_PHRASES)
    simple_confusion = any(
        x in n
        for x in (
            "confus",
            "comprends rien",
            "c est flou",
            "c'est flou",
            "pas clair",
        )
    )
    cognitive_context = ta == "cognitive" or rp == "cognitive" or (
        ht == "communication"
        and ("comprend" in n or "comprends" in n or "explique" in n)
    )
    simple_positive_rule = simple_explicit or simple_confusion or cognitive_context

    ml_supports_simple = ml_simple and (
        ta == "cognitive"
        or rp == "cognitive"
        or ht == "communication"
    )
    # Prefer explicit / cognitive wording; allow ML true only when label context matches.
    out["needsSimpleLanguage"] = bool(simple_positive_rule or ml_supports_simple)

    # --- needsPhysicalAssistance: strengthen for mobility / access blockers ---
    phys_text = any(p in n for p in _PHYSICAL_ASSIST_PHRASES)
    phys_motor_post = action == "create_post" and ta == "motor" and (phys_text or ml_phys)
    phys_help_mobility = (
        action == "create_help_request"
        and ht in {"mobility", "unsafe_access", "escort"}
        and (phys_text or ml_phys)
    )
    # Presets are noisy alone; require wording or ML agreement before tying to physical assistance.
    phys_preset = pmk in {"blocked", "cannot_reach"} and (phys_text or ml_phys)
    phys_rule = phys_text or phys_motor_post or phys_help_mobility or phys_preset

    if phys_rule:
        out["needsPhysicalAssistance"] = True
    elif ml_phys and (
        ta == "motor"
        or rp == "motor"
        or ht in {"mobility", "unsafe_access", "escort", "medical"}
    ):
        out["needsPhysicalAssistance"] = True
    else:
        out["needsPhysicalAssistance"] = False

    # --- needsAudioGuidance: orientation / visual wayfinding / audio cues ---
    audio_text = any(p in n for p in _AUDIO_GUIDANCE_PHRASES)
    profile_visual_impairment = any(p in n for p in _VISUAL_IMPAIRMENT_PROFILE_PHRASES)
    audio_visual_post = action == "create_post" and ta == "visual"
    audio_help_orientation = action == "create_help_request" and ht == "orientation"
    audio_preset_lost = pmk == "lost"
    audio_mode = mode in {"voice", "headeyes"}
    audio_rule = (
        audio_text
        or audio_visual_post
        or audio_help_orientation
        or audio_preset_lost
        or (action == "create_help_request" and profile_visual_impairment)
    )

    if audio_rule:
        out["needsAudioGuidance"] = True
    elif ml_audio and (ta == "visual" or ht == "orientation" or audio_text):
        out["needsAudioGuidance"] = True
    elif ml_audio and ta in {"motor", "hearing", "cognitive", "caregiver", "all", "none", ""} and not audio_text:
        out["needsAudioGuidance"] = False
    else:
        out["needsAudioGuidance"] = ml_audio or audio_mode

    # --- needsVisualSupport: communication / hearing / written alternatives ---
    vis_text = any(p in n for p in _VISUAL_SUPPORT_PHRASES)
    vis_hearing_post = action == "create_post" and ta == "hearing"
    vis_help_comm = action == "create_help_request" and ht == "communication"
    vis_rp_hearing = rp == "hearing"
    vis_rule = vis_text or vis_hearing_post or vis_help_comm or vis_rp_hearing

    if vis_rule:
        out["needsVisualSupport"] = True
    elif ml_visual and (ta == "hearing" or ht == "communication" or vis_text):
        out["needsVisualSupport"] = True
    elif ml_visual and ta == "visual" and "visibilite" not in n and "visibilité" not in n and not vis_text:
        # ML often flags visual for own-vision posts; keep true only with cue or signalement visuel.
        if pn == "signalement" and ta == "visual":
            out["needsVisualSupport"] = True
        elif "vitre" in n or "contraste" in n or "mal voyant" in n or "malvoyant" in n:
            out["needsVisualSupport"] = True
        else:
            out["needsVisualSupport"] = False
    else:
        out["needsVisualSupport"] = ml_visual

    # Light context nudges (never override strong negatives above).
    if ctx in {"help", "aide", "sos"} and action == "create_help_request":
        if ht == "orientation" and not out["needsAudioGuidance"]:
            out["needsAudioGuidance"] = ml_audio or True
    if ctx in {"post", "publication", "community_post"} and ta == "hearing":
        out["needsVisualSupport"] = out["needsVisualSupport"] or True


def _build_feature_text(
    text: str,
    input_mode_hint: str | None = None,
    is_for_another_person_hint: bool | None = None,
) -> str:
    clean_text = text.lower().strip()
    mode = (input_mode_hint or "").strip()
    hint = "unknown" if is_for_another_person_hint is None else ("yes" if is_for_another_person_hint else "no")
    return f"{clean_text} | input_mode_hint:{mode} | for_another_person_hint:{hint}"


def _load_artifact() -> dict[str, Any]:
    if not MODEL_PATH.exists():
        raise FileNotFoundError(
            f"Model not found at {MODEL_PATH}. Run: python src/train_model.py"
        )
    return joblib.load(MODEL_PATH)


def _generated_post_text(pred: dict[str, Any], original_text: str) -> str:
    return (
        f"[{pred['postNature']}] {original_text.strip()} "
        f"(audience={pred['targetAudience']}, danger={pred['dangerLevel']})"
    ).strip()


def _generated_help_description(pred: dict[str, Any], original_text: str) -> str:
    ht = pred.get("helpType")
    label = ("" if ht is None else str(ht)).strip().lower()
    if label in {"", "none", "null"}:
        label = "non précisé"
    return f"Besoin d'aide ({label}) : {original_text.strip()}".strip()


def map_post_to_legacy(post_nature: str | None, target_audience: str | None) -> str:
    if target_audience == "motor":
        return "handicapMoteur"
    if target_audience == "visual":
        return "handicapVisuel"
    if target_audience == "hearing":
        return "handicapAuditif"
    if target_audience == "cognitive":
        return "handicapCognitif"
    if post_nature == "conseil":
        return "conseil"
    if post_nature == "temoignage":
        return "temoignage"
    return "general"


def infer_priority(text: str) -> str:
    t = text.lower().strip()
    critical_tokens = {"critical", "critique", "urgence medicale", "medical urgent", "respire plus", "inconscient"}
    high_tokens = {"bloqué", "bloquee", "bloque", "bklé", "bklee", "urgent", "urgence", "danger"}
    low_tokens = {"conseil", "information", "info", "astuce", "tips"}
    if any(tok in t for tok in critical_tokens):
        return "critical"
    if any(tok in t for tok in high_tokens):
        return "high"
    if any(tok in t for tok in low_tokens):
        return "low"
    return "medium"


def infer_recommended_route(
    action: str,
    post_input_mode: str | None,
    help_input_mode: str | None,
) -> tuple[str, str, float]:
    """Returns (route, routeReason, routeTechnicalConfidence). Last value is a heuristic prior, not ML probability."""
    post_mode = (post_input_mode or "").strip()
    help_mode = (help_input_mode or "").strip()

    if action == "create_post":
        if post_mode == "headEyes":
            return (
                "/create-post-head-gesture",
                "Mode headEyes détecté : parcours tête / yeux adapté.",
                0.92,
            )
        if post_mode in {"vibration", "deafBlind"}:
            return (
                "/create-post-vibration",
                "Mode vibration ou deafBlind détecté : parcours vibrations adapté.",
                0.92,
            )
        if post_mode == "voice":
            return (
                "/create-post-voice-vibration",
                "Mode voix détecté : parcours voix et vibrations adapté.",
                0.90,
            )
        return (
            "/create-post",
            "Parcours de publication standard adapté.",
            0.75,
        )

    if help_mode == "haptic":
        return (
            "/haptic-help",
            "Mode haptique détecté : parcours d'aide avec retours tactiles.",
            0.90,
        )
    return (
        "/create-help-request",
        "Parcours demande d'aide standard adapté.",
        0.75,
    )


@dataclass(frozen=True)
class EntryIntentScores:
    publish: float
    help: float
    location: float


_PUBLISH_PHRASES: tuple[tuple[str, float], ...] = (
    ("je veux signaler un obstacle", 1.0),
    ("je veux poster une photo", 1.0),
    ("voir les derniers posts", 0.96),
    ("voir les posts", 0.95),
    ("dernier post", 0.95),
    ("fama obstacle", 0.95),
    ("nheb nposti taswira", 0.98),
    ("nhabet post", 0.95),
    ("nheb nposti", 0.94),
    # Tunisien / arabizi — « je veux poster / envoyer une photo »
    ("nhabet taswira", 0.96),
    ("nhab taswira", 0.93),
    ("nhbt taswira", 0.92),
    ("nb3th taswira", 0.91),
    ("je veux faire une publication", 0.98),
    ("je veux publier", 0.95),
    ("je veux poster", 0.95),
    ("signaler un obstacle", 0.85),
    ("faire une publication", 0.82),
    ("publication", 0.55),
    ("publier", 0.68),
    ("poster", 0.68),
    ("obstacle", 0.42),
    ("photo", 0.38),
)

_HELP_PHRASES: tuple[tuple[str, float], ...] = (
    ("je veux demander de l'aide", 0.98),
    ("je veux demander de laide", 0.96),
    ("j'ai besoin d'aide", 0.96),
    ("j ai besoin d aide", 0.94),
    ("jai besoin daide", 0.92),
    ("besoin daide", 0.82),
    ("besoin aide", 0.78),
    ("aidez moi", 0.88),
    ("aidez-moi", 0.88),
    ("je suis bloqué", 0.85),
    ("je suis bloque", 0.85),
    ("je suis perdu", 0.88),
    ("je suis perdue", 0.88),
    ("urgence", 0.72),
    ("secours", 0.88),
    # Profil / situation — formulations courtes (souvent seules en entrée vocale)
    ("non voyant", 0.76),
    ("non-voyant", 0.76),
    ("malvoyant", 0.74),
    ("mal voyant", 0.74),
    ("aveugle", 0.72),
    ("deficience visuelle", 0.70),
    ("déficience visuelle", 0.70),
    ("handicap visuel", 0.72),
    ("je suis sourd", 0.74),
    ("je suis sourde", 0.74),
    ("malentendant", 0.72),
    ("mal entendant", 0.72),
)

_LOCATION_PHRASES: tuple[tuple[str, float], ...] = (
    ("je cherche un lieu accessible", 1.0),
    ("lieu accessible", 0.82),
    ("je veux voir les lieux", 0.92),
    ("je veux un lieu proche", 0.92),
    ("trouver un lieu", 0.85),
)

_POST_ENTRY_CONTEXTS = {"post", "community_entry_post"}


def _is_post_entry_context(context_hint: str | None) -> bool:
    return (context_hint or "").strip().lower() in _POST_ENTRY_CONTEXTS


def _detect_post_entry_route_signal(normalized_text: str) -> tuple[str, str, str, float] | None:
    """Returns (route, summary, reason, confidence) for post-only entry mode."""
    n = normalized_text

    feed_signals = (
        "dernier post",
        "derenier post",
        "voir les posts",
        "voir les derniers posts",
        "voir les dereniers posts",
        "voir post",
        "lire commentaire dernier poste",
        "lire commentaires dernier poste",
        "lire commentaire derenier poste",
        "lire resume dernier poste",
        "lire resume derenier poste",
        "nheb nchouf les posts",
        "nheb nchouf akher post",
        "nheb nchouf dernier post",
        "akher post",
    )
    if any(p in n for p in feed_signals):
        return (
            "/community-posts",
            "Consultation des posts détectée.",
            "Entrée communauté orientée publication : consultation du fil des posts.",
            0.92,
        )

    obstacle_signals = (
        "signaler un obstacle",
        "fama obstacle",
        "obstacle",
        "escalier sans rampe",
        "entree inaccessible",
        "entrée inaccessible",
        "rampe absente",
        "rampe manquante",
        "ma famech rampe",
        "acces difficile",
        "accès difficile",
        "pas de rampe",
    )
    if any(p in n for p in obstacle_signals):
        return (
            "/create-post-head-gesture",
            "Signalement d’obstacle détecté.",
            "Entrée communauté orientée publication : signalement d’obstacle.",
            0.93,
        )

    photo_signals = (
        "poster une photo",
        "publier une photo",
        "ouvre camera",
        "ouvrir camera",
        "open camera",
        "camera tete yeux",
        "camera tete et yeux",
        "nheb nposti taswira",
        "nhabet taswira",
        "taswira",
        "photo",
    )
    if any(p in n for p in photo_signals):
        return (
            "/create-post-voice-vibration",
            "Publication détectée.",
            "Entrée communauté orientée publication : parcours photo et dictée.",
            0.91,
        )

    publish_signals = (
        "je veux publier",
        "je veux poster",
        "nhabet post",
        "nheb nposti",
        "publier",
        "poster",
    )
    if any(p in n for p in publish_signals):
        return (
            "/create-post",
            "Publication détectée.",
            "Entrée communauté orientée publication : création de post.",
            0.90,
        )

    return None


def _utterance_is_too_ambiguous(normalized_text: str) -> bool:
    """Very short isolated 'aide' — not enough to pick a flow without confirmation."""
    t = normalized_text.strip()
    if t == "aide":
        return True
    if len(t) <= 6 and t in {"aide.", "aide!", "aide ?"}:
        return True
    return False


def detect_entry_intent_strength(
    text: str,
    context_hint: str | None = None,
    input_mode_hint: str | None = None,
    is_for_another_person_hint: bool | None = None,
) -> EntryIntentScores:
    n = _normalize_for_match(text)

    def _max_from_phrases(phrases: tuple[tuple[str, float], ...]) -> float:
        best = 0.0
        for phrase, weight in phrases:
            if phrase in n:
                best = max(best, weight)
        return min(1.0, best)

    publish = _max_from_phrases(_PUBLISH_PHRASES)
    help_s = _max_from_phrases(_HELP_PHRASES)
    location = _max_from_phrases(_LOCATION_PHRASES)

    if _utterance_is_too_ambiguous(n):
        publish = min(publish, 0.22)
        help_s = min(help_s, 0.35)
        location = min(location, 0.22)

    ctx = (context_hint or "").strip().lower()
    if ctx in {"post", "publication", "community_post"}:
        publish = min(1.0, publish + 0.18)
    elif ctx in {"help", "aide", "sos"}:
        help_s = min(1.0, help_s + 0.18)

    if is_for_another_person_hint is True:
        help_s = min(1.0, help_s + 0.06)

    mode = (input_mode_hint or "").strip().lower()
    if mode in {"headeyes", "vibration", "deafblind"}:
        publish = min(1.0, publish + 0.12)
    if mode in {"tap", "haptic", "volume_shortcut"}:
        help_s = min(1.0, help_s + 0.08)
    if mode == "haptic":
        help_s = min(1.0, help_s + 0.04)

    return EntryIntentScores(publish=publish, help=help_s, location=location)


def enhance_prediction_with_rules(
    predicted: dict[str, Any],
    *,
    action_from_model: str,
    intents: EntryIntentScores,
) -> tuple[str, dict[str, float]]:
    p, h = intents.publish, intents.help
    meta = {
        "intent_publish": p,
        "intent_help": h,
        "intent_location": intents.location,
        "model_action_prior": 1.0 if action_from_model == "create_post" else 0.0,
    }

    resolved = action_from_model

    if h >= _STRONG_INTENT and h >= p + _MARGIN and action_from_model == "create_post":
        resolved = "create_help_request"

    if p >= _STRONG_INTENT and p >= h + _MARGIN and action_from_model == "create_help_request":
        resolved = "create_post"

    meta["alignment_model"] = p if action_from_model == "create_post" else h
    meta["alignment_resolved"] = p if resolved == "create_post" else h

    return resolved, meta


def _intent_conflict(intents: EntryIntentScores) -> bool:
    """Publish and help both look plausible — avoid aggressive auto-navigation."""
    p, h = intents.publish, intents.help
    return p >= 0.48 and h >= 0.48 and abs(p - h) < 0.18


def _route_intent_alignment(action: str, route: str, intents: EntryIntentScores) -> float:
    """How well explicit wording supports this route family (0–1)."""
    if route == "/community-nearby":
        return intents.location
    if action == "create_post":
        return max(intents.publish, intents.location * 0.35)
    return max(intents.help, intents.location * 0.35)


def _enhance_route_with_intents(
    route: str,
    route_reason: str,
    route_technical_confidence: float,
    action: str,
    intents: EntryIntentScores,
    normalized_text: str,
    post_input_mode: str | None,
) -> tuple[str, str, float]:
    """
    Pick route variants (location, obstacle head-gesture) and lightly tune reasons.
    Base numeric confidence stays from infer_recommended_route; alignment is applied once in compute_route_confidence.
    """
    loc = intents.location
    max_ph = max(intents.publish, intents.help)

    tech = route_technical_confidence

    if (
        loc >= 0.52
        and loc >= max_ph + _LOCATION_DOMINANCE
        and loc >= intents.publish + _LOCATION_DOMINANCE / 2
        and loc >= intents.help + _LOCATION_DOMINANCE / 2
    ):
        return (
            "/community-nearby",
            "Recherche de lieux accessibles : liste à proximité proposée.",
            _clamp(0.78 + 0.18 * loc, 0.55, 0.96),
        )

    if action == "create_post" and intents.publish >= 0.55 and route == "/create-post":
        route_reason = (route_reason + " Formulation claire pour publier.").strip()
        tech = min(0.96, tech + 0.06 * intents.publish)

    if (
        action == "create_post"
        and ("obstacle" in normalized_text or "signaler un obstacle" in normalized_text)
        and (post_input_mode or "").strip() != "headEyes"
    ):
        route = "/create-post-head-gesture"
        route_reason = (
            "Publication type signalement d'obstacle : parcours guidé tête / yeux proposé."
        )
        tech = max(tech, _clamp(0.88 + 0.06 * intents.publish, 0.72, 0.97))

    if action == "create_help_request" and intents.help >= 0.55 and route == "/create-help-request":
        route_reason = (route_reason + " Formulation claire pour demander de l'aide.").strip()
        tech = min(0.96, tech + 0.07 * intents.help)

    return route, route_reason, tech


def compute_decision_strength(
    *,
    action: str,
    action_ml: str,
    intents: EntryIntentScores,
    route: str,
    context_override: bool,
) -> float:
    """
    How clear the chosen action is from wording + model agreement (0–1).
    Distinct from routeTechnicalConfidence — reflects decision clarity, not path fit alone.
    """
    if route == "/community-nearby":
        return _clamp(0.52 + 0.48 * intents.location)

    chosen = intents.publish if action == "create_post" else intents.help
    rival = intents.help if action == "create_post" else intents.publish
    separation = max(0.0, chosen - rival)

    model_agrees = 1.0 if action == action_ml else 0.62
    ctx_boost = 0.14 if context_override else 0.0

    strength = (
        0.42 * _clamp(chosen + ctx_boost)
        + 0.28 * separation
        + 0.22 * model_agrees
        + 0.08 * max(intents.publish, intents.help, intents.location)
    )

    if _intent_conflict(intents):
        strength *= 0.82

    return _clamp(strength)


def compute_route_confidence(
    route_technical_confidence: float,
    *,
    action: str,
    route: str,
    intents: EntryIntentScores,
) -> float:
    """
    Heuristic confidence that this route is appropriate (modal hints + wording).
    """
    align = _route_intent_alignment(action, route, intents)
    return _clamp(route_technical_confidence * (0.70 + 0.30 * align), 0.36, 0.97)


def compute_navigation_confidence(
    *,
    decision_strength: float,
    route_confidence: float,
    intents: EntryIntentScores,
    requires_confirmation: bool,
    ambiguous_utterance: bool,
    intent_conflict: bool,
) -> float:
    """
    Single scalar for legacy `confidence` field — suitability for proactive UI / auto-navigation.
    Not a calibrated model probability; combine decision clarity + route fit + explicit cues.
    """
    peak = max(intents.publish, intents.help, intents.location)
    nav = (
        0.40 * decision_strength
        + 0.35 * route_confidence
        + 0.25 * peak
    )

    if ambiguous_utterance:
        nav = min(nav, _AMBIGUOUS_NAV_CAP)
    elif intent_conflict:
        nav = min(nav, 0.78)

    if requires_confirmation:
        nav = min(nav, _CONFIRMATION_NAV_CAP)

    # Strong explicit phrases: eligible for auto-navigation band when unambiguous
    if (
        not requires_confirmation
        and not ambiguous_utterance
        and peak >= 0.72
        and decision_strength >= 0.72
        and route_confidence >= 0.70
    ):
        nav = max(nav, min(0.94, _AUTO_NAV_FLOOR + 0.04 * (peak - 0.72)))

    return _clamp(nav, 0.32, 0.96)


def build_decision_summary(
    *,
    action: str,
    route: str,
    intents: EntryIntentScores,
    normalized_text: str,
    post_nature: str | None,
    help_type: str | None,
) -> str:
    """Short, user-facing French line — no sensitive profiling language."""
    if route == "/community-posts":
        return "Consultation des posts détectée."
    if route == "/community-nearby":
        return "Recherche de lieu accessible détectée."

    if action == "create_post":
        if route == "/create-post-voice-vibration":
            if _visual_impairment_voice_post_compound(normalized_text):
                return (
                    "Publication en dictée vocale : formulation avec profil visuel détectée."
                )
            if _is_standalone_visual_profile_only(normalized_text):
                return (
                    "Profil visuel exprimé brièvement : dictée vocale avec vibrations "
                    "recommandée."
                )
            return (
                "Dictée vocale avec vibrations recommandée pour cette publication."
            )
        if route == "/create-post-head-gesture":
            if _visual_impairment_photo_or_place_signalement(normalized_text):
                return (
                    "Publication détectée : parcours tête / yeux pour photo ou "
                    "signalement de lieu."
                )
            return (
                "Publication détectée : parcours guidé par la tête et les yeux."
            )
        if "signaler" in normalized_text and "obstacle" in normalized_text:
            return "Publication détectée. Signalement d'obstacle recommandé."

        pn = (post_nature or "").strip().lower()
        nature_fr = {
            "signalement": "signalement",
            "alerte": "alerte",
            "information": "information",
            "conseil": "conseil",
            "temoignage": "témoignage",
        }.get(pn, "publication")

        if intents.publish >= 0.55:
            return f"Publication détectée (type : {nature_fr})."
        return f"Publication suggérée (type : {nature_fr})."

    ht = (help_type or "").strip().lower()
    help_fr = {
        "orientation": "orientation",
        "mobility": "déplacement",
        "communication": "communication",
        "medical": "santé ou urgence",
        "escort": "accompagnement",
        "unsafe_access": "accès difficile",
        "other": "besoin général",
    }
    detail = help_fr.get(ht)

    if intents.help >= 0.55:
        if detail:
            return f"Demande d'aide détectée. Piste recommandée : {detail}."
        return "Demande d'aide détectée."

    if detail:
        return f"Demande d'aide suggérée. Piste : {detail}."
    return "Demande d'aide suggérée."


def predict_action_plan(
    text: str,
    context_hint: str | None = None,
    input_mode_hint: str | None = None,
    is_for_another_person_hint: bool | None = None,
) -> dict[str, Any]:
    artifact = _load_artifact()
    vec = artifact["vectorizer"]
    clf = artifact["classifier"]
    label_columns = artifact["label_columns"]

    clean_text = text.lower().strip()
    normalized_for_intent = _normalize_for_match(text)
    ambiguous_utterance = _utterance_is_too_ambiguous(normalized_for_intent)

    feature_text = _build_feature_text(clean_text, input_mode_hint, is_for_another_person_hint)
    X = vec.transform([feature_text])
    pred = clf.predict(X)[0]
    out: dict[str, Any] = dict(zip(label_columns, pred))

    for c in BOOL_COLUMNS:
        out[c] = _to_bool(out[c])

    action_ml = str(out["actionType"])

    intents = detect_entry_intent_strength(
        text,
        context_hint=context_hint,
        input_mode_hint=input_mode_hint,
        is_for_another_person_hint=is_for_another_person_hint,
    )

    action_hybrid, _hybrid_meta = enhance_prediction_with_rules(
        out,
        action_from_model=action_ml,
        intents=intents,
    )

    hint_ctx = (context_hint or "").strip().lower()
    post_entry_context = _is_post_entry_context(hint_ctx)
    context_override = hint_ctx in {"post", "help"} or post_entry_context
    mode_hint = (input_mode_hint or "").strip().lower()

    if post_entry_context or hint_ctx == "post":
        action = "create_post"
    elif hint_ctx == "help":
        action = "create_help_request"
    else:
        action = action_hybrid

    # Si le texte est ambigu, utiliser le mode de saisie comme signal secondaire.
    if not context_override and ambiguous_utterance:
        if mode_hint in {"headeyes", "vibration", "deafblind"}:
            action = "create_post"
        elif mode_hint in {"tap", "haptic", "volume_shortcut"}:
            action = "create_help_request"

    # Libellés très courts de profil visuel — publication + dictée vocale, pas une aide SOS générique.
    if _is_standalone_visual_profile_only(normalized_for_intent) and hint_ctx not in {
        "help",
        "aide",
        "sos",
    }:
        action = "create_post"

    # Non-voyant + photo ou signalement de lieu : toujours publication (tête / yeux), pas demande d'aide.
    if _visual_impairment_photo_or_place_signalement(normalized_for_intent) and hint_ctx not in {
        "help",
        "aide",
        "sos",
    }:
        action = "create_post"

    # Profil visuel + texte (FR/TN) : publication en mode voix — prioritaire sur l’hybride aide.
    if _visual_impairment_voice_post_compound(normalized_for_intent):
        action = "create_post"

    out["action"] = action
    out.pop("actionType", None)

    label_snapshot = {
        "targetAudience": out.get("targetAudience"),
        "postNature": out.get("postNature"),
        "helpType": out.get("helpType"),
        "requesterProfile": out.get("requesterProfile"),
        "presetMessageKey": out.get("presetMessageKey"),
    }
    refine_accessibility_booleans(
        out,
        action=action,
        normalized_text=normalized_for_intent,
        label_snapshot=label_snapshot,
        input_mode_hint=input_mode_hint,
        context_hint=context_hint,
    )

    hint = (input_mode_hint or "").strip()

    if action == "create_post":
        for c in HELP_ONLY_COLUMNS:
            out[c] = None
        if hint in POST_INPUT_MODES:
            out["postInputMode"] = hint
        _apply_post_input_mode_accessibility_rules(
            out,
            normalized_text=normalized_for_intent,
            input_mode_hint=input_mode_hint,
        )
        out["generatedContent"] = _generated_post_text(out, clean_text)
        out["generatedDescription"] = None
        out["legacyType"] = map_post_to_legacy(out.get("postNature"), out.get("targetAudience"))
    else:
        for c in POST_ONLY_COLUMNS:
            out[c] = None
        if hint in HELP_INPUT_MODES:
            out["helpInputMode"] = hint
        out["generatedDescription"] = _generated_help_description(out, clean_text)
        out["generatedContent"] = None
        out["legacyType"] = None

    out["predictedPriority"] = infer_priority(clean_text)

    if is_for_another_person_hint is not None:
        out["isForAnotherPerson"] = bool(is_for_another_person_hint)

    route, route_reason, route_technical_confidence = infer_recommended_route(
        action=action,
        post_input_mode=out.get("postInputMode"),
        help_input_mode=out.get("helpInputMode"),
    )

    route, route_reason, route_technical_confidence = _enhance_route_with_intents(
        route,
        route_reason,
        route_technical_confidence,
        action,
        intents,
        normalized_for_intent,
        out.get("postInputMode"),
    )

    ic = _intent_conflict(intents)
    requires_confirmation = ambiguous_utterance or (
        ic and max(intents.publish, intents.help) < 0.78
    )

    decision_strength = compute_decision_strength(
        action=action,
        action_ml=action_ml,
        intents=intents,
        route=route,
        context_override=context_override,
    )

    route_confidence = compute_route_confidence(
        route_technical_confidence,
        action=action,
        route=route,
        intents=intents,
    )

    navigation_confidence = compute_navigation_confidence(
        decision_strength=decision_strength,
        route_confidence=route_confidence,
        intents=intents,
        requires_confirmation=requires_confirmation,
        ambiguous_utterance=ambiguous_utterance,
        intent_conflict=ic,
    )

    summary = build_decision_summary(
        action=action,
        route=route,
        intents=intents,
        normalized_text=normalized_for_intent,
        post_nature=out.get("postNature"),
        help_type=out.get("helpType"),
    )

    if post_entry_context:
        # Entry correction layer: this screen must remain post-only.
        action = "create_post"
        out["action"] = "create_post"
        for c in HELP_ONLY_COLUMNS:
            out[c] = None

        if route in {
            "/create-help-request",
            "/haptic-help",
            "/community-nearby",
            "/community-locations",
        }:
            route = "/create-post"
            route_reason = (
                "Entrée communauté orientée publication : route aide/lieu ignorée."
            )
            route_technical_confidence = max(route_technical_confidence, 0.74)

        forced = _detect_post_entry_route_signal(normalized_for_intent)
        if forced is not None:
            forced_route, forced_summary, forced_reason, forced_conf = forced
            route = forced_route
            summary = forced_summary
            route_reason = forced_reason
            route_confidence = max(route_confidence, forced_conf)
            decision_strength = max(decision_strength, forced_conf)
            navigation_confidence = max(navigation_confidence, forced_conf)
            requires_confirmation = False
        else:
            route = "/create-post"
            summary = "Publication suggérée."
            route_reason = "Entrée communauté orientée publication."
            route_confidence = max(route_confidence, 0.72)
            decision_strength = min(decision_strength, 0.75)
            navigation_confidence = min(max(navigation_confidence, 0.70), 0.75)
            requires_confirmation = True

    out["recommendedRoute"] = route
    out["routeReason"] = route_reason

    # Legacy field: overall navigation suitability (Flutter shouldAutoNavigate)
    out["confidence"] = navigation_confidence
    out["routeConfidence"] = route_confidence
    out["decisionStrength"] = decision_strength
    out["requiresConfirmation"] = requires_confirmation
    out["decisionSummary"] = summary

    out["intentScores"] = {
        "publish": intents.publish,
        "help": intents.help,
        "location": intents.location,
    }
    out["hybridDecision"] = {
        "modelAction": action_ml,
        "resolvedAction": action,
        "ruleAdjusted": action != action_ml and not context_override,
        "contextOverride": context_override,
        "ambiguousUtterance": ambiguous_utterance,
        "intentConflict": ic,
    }

    logger.info(
        "CommunityActionPlan text=%r intent=%s action=%s route=%s "
        "routeConf=%.3f decisionStrength=%.3f navConfidence=%.3f confirm=%s summary=%r",
        clean_text[:280],
        out["intentScores"],
        action,
        route,
        route_confidence,
        decision_strength,
        navigation_confidence,
        requires_confirmation,
        summary[:200],
    )

    return out


def main() -> None:
    logging.basicConfig(level=logging.INFO)
    parser = argparse.ArgumentParser(description="Predict Community Action Plan from text.")
    parser.add_argument("--text", required=True, help="User free text.")
    parser.add_argument("--inputModeHint", default=None, help="Optional input mode hint.")
    parser.add_argument("--contextHint", default=None, help="Optional context hint: post/help/community.")
    parser.add_argument(
        "--isForAnotherPersonHint",
        default=None,
        help="Optional boolean hint: true/false",
    )
    args = parser.parse_args()

    hint_bool = None
    if args.isForAnotherPersonHint is not None:
        hint_bool = _to_bool(args.isForAnotherPersonHint)

    result = predict_action_plan(
        text=args.text,
        context_hint=args.contextHint,
        input_mode_hint=args.inputModeHint,
        is_for_another_person_hint=hint_bool,
    )
    print(pd.Series(result).to_json(force_ascii=False, indent=2))


if __name__ == "__main__":
    main()
