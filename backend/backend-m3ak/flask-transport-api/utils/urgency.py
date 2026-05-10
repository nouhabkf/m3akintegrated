"""
Détection d'urgence par mots-clés dans la description (liste simple).
"""
import re

MOTS_URGENCE = [
    "urgent", "urgence", "santé", "sante", "hôpital", "hopital", "hospital",
    "accident", "crise", "urgence médicale", "urgence medicale", "médecin", "medecin",
    "ambulance", "grave", "vite", "immédiat", "immediat", "asap", "critical",
    "danger", "aide rapide", "emergency", "critical",
]


def detecter_urgence(description: str) -> dict:
    """
    Détecte si la demande est urgente via des mots-clés.
    Retourne: { "urgence": bool, "mots_detectes": [...] }
    """
    if not description or not isinstance(description, str):
        return {"urgence": False, "mots_detectes": []}
    text = description.lower().strip()
    # Normaliser accents pour comparaison simple
    text_norm = text
    mots_trouves = []
    for mot in MOTS_URGENCE:
        if mot in text_norm or mot.replace(" ", "") in text_norm.replace(" ", ""):
            mots_trouves.append(mot)
    # Éviter doublons (ex. "urgence" et "urgence médicale")
    mots_trouves = list(dict.fromkeys(mots_trouves))
    return {
        "urgence": len(mots_trouves) > 0,
        "mots_detectes": mots_trouves,
    }
