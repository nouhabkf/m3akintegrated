"""
Analyse de sentiment avec TextBlob (gratuit) et extraction de mots-clés.
"""
import re
from collections import Counter

try:
    from textblob import TextBlob
except ImportError:
    TextBlob = None

# Mots vides français courants (liste réduite)
STOP_WORDS = {
    "le", "la", "les", "un", "une", "des", "du", "de", "et", "est", "en", "au", "aux",
    "ce", "cette", "ces", "son", "sa", "ses", "mon", "ma", "mes", "notre", "nos",
    "votre", "vos", "leur", "leurs", "qui", "que", "quoi", "dont", "où", "ou",
    "par", "pour", "avec", "sans", "sous", "sur", "dans", "chez", "vers", "depuis",
    "très", "plus", "moins", "bien", "mal", "pas", "ne", "je", "tu", "il", "elle",
    "on", "nous", "vous", "ils", "elles", "être", "avoir", "fait", "faites",
}


def _tokenize(text: str) -> list:
    """Tokenisation simple : mots en minuscules, sans ponctuation."""
    if not text:
        return []
    text = (text or "").lower()
    words = re.findall(r"[a-zàâäéèêëïîôùûüçœæ]+", text)
    return [w for w in words if len(w) > 1 and w not in STOP_WORDS]


def analyser_avis(texte: str) -> dict:
    """
    Analyse de sentiment (TextBlob) + mots-clés (fréquence).
    Retourne: polarite (-1 à 1), subjectivite (0 à 1), mots_cles [ { "mot", "frequence" } ].
    """
    if not texte or not isinstance(texte, str):
        return {
            "polarite": 0.0,
            "subjectivite": 0.0,
            "mots_cles": [],
            "erreur": "Texte manquant ou invalide",
        }
    texte = texte.strip()
    result = {"polarite": 0.0, "subjectivite": 0.0, "mots_cles": []}

    if TextBlob is not None:
        try:
            blob = TextBlob(texte)
            result["polarite"] = round(blob.sentiment.polarity, 4)
            result["subjectivite"] = round(blob.sentiment.subjectivity, 4)
        except Exception as e:
            result["erreur_textblob"] = str(e)

    tokens = _tokenize(texte)
    if tokens:
        counts = Counter(tokens)
        total = len(tokens)
        # Mots apparaissant au moins 2 fois ou parmi les 15 plus fréquents
        top = counts.most_common(15)
        result["mots_cles"] = [
            {"mot": m, "frequence": c}
            for m, c in top
            if c >= 2 or c >= max(1, total // 10)
        ][:20]

    return result


def est_alerte_negatif(analyse: dict, seuil_polarite: float = -0.3) -> bool:
    """Détermine si l'analyse doit générer une alerte (sentiment très négatif)."""
    return (analyse.get("polarite") or 0) <= seuil_polarite
