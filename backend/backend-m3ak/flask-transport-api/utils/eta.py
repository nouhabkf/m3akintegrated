"""
Estimation du temps d'arrivée : distance Haversine puis durée = distance / vitesse moyenne.
"""
from .haversine import haversine_km

VITESSE_MOYENNE_KMH_DEFAUT = 30.0  # ville


def estimer_eta(
    lat_chauffeur,
    lon_chauffeur,
    lat_utilisateur,
    lon_utilisateur,
    vitesse_kmh=None,
):
    """
    Retourne distance_km et duree_minutes.
    """
    v = vitesse_kmh if vitesse_kmh is not None and vitesse_kmh > 0 else VITESSE_MOYENNE_KMH_DEFAUT
    distance_km = haversine_km(lat_chauffeur, lon_chauffeur, lat_utilisateur, lon_utilisateur)
    duree_heures = distance_km / v
    duree_minutes = max(0.0, duree_heures * 60.0)
    return {
        "distance_km": round(distance_km, 2),
        "duree_minutes": round(duree_minutes, 1),
        "vitesse_kmh_utilisee": v,
    }
