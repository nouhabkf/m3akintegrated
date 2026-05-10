"""
Matching intelligent chauffeurs : score basé sur proximité (Haversine),
expérience, notes, spécialisation. Bonus urgence.
"""
from typing import Optional
from .haversine import haversine_km

# Poids pour le score (ajustables)
POIDS_DISTANCE = 0.35   # plus proche = mieux
POIDS_NOTES = 0.30
POIDS_EXPERIENCE = 0.20
POIDS_SPECIALISATION = 0.15
BONUS_URGENCE = 1.15   # multiplicateur si urgence


def score_proximite(distance_km: float) -> float:
    """Score 0-1 : plus la distance est faible, plus le score est élevé. 0 km = 1, 50 km = ~0."""
    if distance_km <= 0:
        return 1.0
    # Décroissance douce : 5 km -> ~0.9, 20 km -> ~0.6, 50 km -> ~0.2
    return max(0.0, 1.0 - (distance_km / 50.0))


def score_notes(note: float, note_max: float = 5.0) -> float:
    """Score 0-1 basé sur la note (ex: 4.5/5 -> 0.9)."""
    if note_max <= 0:
        return 0.0
    return max(0.0, min(1.0, float(note) / float(note_max)))


def score_experience(annees_experience: float, max_annees: float = 20.0) -> float:
    """Score 0-1 : plus d'expérience = mieux, plafonné."""
    if max_annees <= 0:
        return 0.0
    return min(1.0, max(0.0, float(annees_experience) / max_annees))


def calculer_score_chauffeur(
    distance_km: float,
    note_moyenne: float,
    annees_experience: float,
    specialisation_correspond: bool,
    urgence: bool = False,
) -> float:
    """
    Score global 0-1 (puis éventuellement multiplié par BONUS_URGENCE).
    """
    s_prox = score_proximite(distance_km)
    s_notes = score_notes(note_moyenne)
    s_exp = score_experience(annees_experience)
    s_spec = 1.0 if specialisation_correspond else 0.5
    score = (
        POIDS_DISTANCE * s_prox
        + POIDS_NOTES * s_notes
        + POIDS_EXPERIENCE * s_exp
        + POIDS_SPECIALISATION * s_spec
    )
    if urgence:
        score *= BONUS_URGENCE
    return min(1.0, score)


def matching_chauffeurs(
    lat_utilisateur: float,
    lon_utilisateur: float,
    chauffeurs: list,
    type_handicap_utilisateur: Optional[str] = None,
    urgence: bool = False,
) -> list:
    """
    chauffeurs: liste de dict avec au minimum:
      - latitude, longitude
      - noteMoyenne (ou note_moyenne)
      - anneesExperience (ou annees_experience), optionnel, défaut 0
      - specialisation ou typeHandicap (str ou liste), optionnel
    Retourne les chauffeurs avec score et distance_km, triés par score décroissant.
    """
    type_handicap = (type_handicap_utilisateur or "").strip().lower()
    resultats = []
    for ch in chauffeurs:
        lat = ch.get("latitude") or ch.get("lat")
        lon = ch.get("longitude") or ch.get("lon")
        if lat is None or lon is None:
            continue
        distance_km = haversine_km(lat_utilisateur, lon_utilisateur, float(lat), float(lon))
        note = float(ch.get("noteMoyenne") or ch.get("note_moyenne") or 0)
        exp = float(ch.get("anneesExperience") or ch.get("annees_experience") or 0)
        spec_raw = ch.get("specialisation") or ch.get("typeHandicap") or ch.get("type_handicap") or ""
        if isinstance(spec_raw, list):
            spec_match = any(
                (s or "").strip().lower() == type_handicap for s in spec_raw
            ) or not type_handicap
        else:
            spec_match = (spec_raw or "").strip().lower() == type_handicap or not type_handicap
        score = calculer_score_chauffeur(
            distance_km, note, exp, spec_match, urgence=urgence
        )
        resultats.append({
            **{k: v for k, v in ch.items() if k not in ("latitude", "longitude", "lat", "lon")},
            "latitude": lat,
            "longitude": lon,
            "distance_km": round(distance_km, 2),
            "score_matching": round(score, 4),
        })
    resultats.sort(key=lambda x: x["score_matching"], reverse=True)
    return resultats
