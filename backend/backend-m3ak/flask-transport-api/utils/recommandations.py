"""
Recommandations personnalisées : historique des notes de l'utilisateur
et chauffeurs les mieux notés pour le même handicap.
"""
from collections import defaultdict


def recommandations_personnalisees(
    type_handicap_utilisateur,
    historique_notes_utilisateur,
    chauffeurs,
    top_n=10,
):
    """
    historique_notes_utilisateur: liste de { "chauffeurId", "note", "typeHandicap" } (optionnel)
    chauffeurs: liste de dict avec id, noteMoyenne/note_moyenne, specialisation/typeHandicap, etc.
    Retourne les chauffeurs recommandés (même handicap prioritaire, puis meilleures notes).
    """
    type_handicap = (type_handicap_utilisateur or "").strip().lower()
    # Chauffeurs bien notés par l'utilisateur dans le passé
    chauffeurs_preferes = set()
    if historique_notes_utilisateur:
        for h in historique_notes_utilisateur:
            if isinstance(h, dict) and float(h.get("note") or 0) >= 4.0:
                cid = h.get("chauffeurId") or h.get("chauffeur_id")
                if cid is not None:
                    chauffeurs_preferes.add(str(cid))

    def note(c):
        return float(c.get("noteMoyenne") or c.get("note_moyenne") or 0)

    def correspond_handicap(c):
        spec = c.get("specialisation") or c.get("typeHandicap") or c.get("type_handicap") or ""
        if isinstance(spec, list):
            return type_handicap in [ (s or "").strip().lower() for s in spec ]
        return (spec or "").strip().lower() == type_handicap

    # Priorité 1: même handicap + dans les préférés
    # Priorité 2: même handicap, meilleure note
    # Priorité 3: autres, par note
    avec_handicap = [c for c in chauffeurs if correspond_handicap(c)]
    sans_handicap = [c for c in chauffeurs if not correspond_handicap(c)]

    def cle_tri(c):
        pref = 1 if (str(c.get("id") or c.get("_id") or "") in chauffeurs_preferes) else 0
        return (-pref, -note(c))

    avec_handicap.sort(key=cle_tri)
    sans_handicap.sort(key=lambda c: -note(c))
    resultats = avec_handicap + sans_handicap
    return resultats[:top_n]
