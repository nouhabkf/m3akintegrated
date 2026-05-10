"""
Optimisation de tournée : ordre de passages par algorithme du plus proche voisin (glouton)
avec distances Haversine. Départ et retour au dépôt.
"""
from .haversine import haversine_km


def optimiser_tournee(depot: dict, points: list) -> dict:
    """
    depot: { "latitude", "longitude" } (ou "lat", "lon")
    points: liste de { "id", "latitude", "longitude", ... } (id optionnel)
    Retourne: { "ordre": [points dans l'ordre], "distance_totale_km": float }
    """
    lat_d = depot.get("latitude") or depot.get("lat")
    lon_d = depot.get("longitude") or depot.get("lon")
    if lat_d is None or lon_d is None:
        return {"ordre": [], "distance_totale_km": 0.0}
    lat_d, lon_d = float(lat_d), float(lon_d)
    n = len(points)
    if n == 0:
        return {"ordre": [], "distance_totale_km": 0.0}

    def lat_lon(p):
        lat = p.get("latitude") or p.get("lat")
        lon = p.get("longitude") or p.get("lon")
        return float(lat), float(lon)

    ordre = []
    restants = list(points)
    # Point courant : départ du dépôt
    cur_lat, cur_lon = lat_d, lon_d
    distance_totale = 0.0

    while restants:
        best_i = -1
        best_dist = float("inf")
        for i, p in enumerate(restants):
            la, lo = lat_lon(p)
            d = haversine_km(cur_lat, cur_lon, la, lo)
            if d < best_dist:
                best_dist = d
                best_i = i
        prochain = restants.pop(best_i)
        ordre.append(prochain)
        cur_lat, cur_lon = lat_lon(prochain)
        distance_totale += best_dist

    # Retour au dépôt
    distance_totale += haversine_km(cur_lat, cur_lon, lat_d, lon_d)

    return {
        "ordre": ordre,
        "distance_totale_km": round(distance_totale, 2),
    }
