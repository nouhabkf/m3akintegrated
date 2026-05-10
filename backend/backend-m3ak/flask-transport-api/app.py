"""
Backend Flask - Transport adapté aux personnes handicapées.
Endpoints REST : matching, demande/urgence, ETA, recommandations,
optimisation tournée, analyse d'avis et alertes.
Bibliothèques gratuites uniquement, pas d'API payante.
"""
import os
from flask import Flask, request, jsonify

try:
    from flasgger import Swagger
    FLASGGER_AVAILABLE = True
except ImportError:
    FLASGGER_AVAILABLE = False

from utils.urgency import detecter_urgence
from utils.haversine import haversine_km
from utils.matching import matching_chauffeurs
from utils.eta import estimer_eta
from utils.recommandations import recommandations_personnalisees
from utils.tournee import optimiser_tournee
from utils.sentiment import analyser_avis, est_alerte_negatif

app = Flask(__name__)

# Configuration Swagger (documentation et test des endpoints)
# Interface Swagger UI : http://127.0.0.1:5001/api-docs (évite conflit avec /api/match, etc.)
swagger_config = {
    "headers": [],
    "specs": [
        {
            "endpoint": "apispec",
            "route": "/apispec.json",
            "rule_filter": lambda rule: True,
            "model_filter": lambda tag: True,
        }
    ],
    "static_url_path": "/flasgger_static",
    "swagger_ui": True,
    "specs_route": "/api-docs",
    "uiversion": 3,
}
swagger_template = {
    "swagger": "2.0",
    "info": {
        "title": "Ma3ak API",
        "description": "API REST pour l'application Ma3ak - Application mobile intelligente destinée aux personnes en situation de handicap en Tunisie et à leurs accompagnants. Ce module (Flask) fournit le transport adapté : matching chauffeurs, urgence, ETA, recommandations, optimisation tournée, analyse d'avis. Facilite la mobilité, l'autonomie et l'inclusion sociale. Bibliothèques gratuites uniquement.",
        "version": "1.0",
    },
    "host": "127.0.0.1:5001",
    "basePath": "/",
    "tags": [
        {"name": "Health", "description": "Vérification du statut de l'API"},
        {"name": "Matching", "description": "Matching intelligent chauffeurs"},
        {"name": "Demande", "description": "Détection urgence par mots-clés"},
        {"name": "ETA", "description": "Estimation temps d'arrivée"},
        {"name": "Recommandations", "description": "Recommandations personnalisées"},
        {"name": "Tournée", "description": "Optimisation ordre de passages"},
        {"name": "Avis", "description": "Analyse sentiment et mots-clés"},
        {"name": "Alertes", "description": "Alertes avis négatifs"},
    ],
    "paths": {},
}
if FLASGGER_AVAILABLE:
    Swagger(app, config=swagger_config, template=swagger_template)

# Stockage en mémoire des analyses d'avis pour GET /api/alertes (pas de BDD)
_analyses_avis = []
_alertes = []
_SEUIL_ALERTE_POLARITE = -0.3


# ---------- POST /api/match ----------
@app.route("/api/match", methods=["POST"])
def api_match():
    """
    Matching intelligent des chauffeurs
    ---
    tags:
      - Matching
    parameters:
      - in: body
        name: body
        required: true
        schema:
          type: object
          properties:
            latitude_utilisateur:
              type: number
              example: 36.8
            longitude_utilisateur:
              type: number
              example: 10.18
            urgence:
              type: boolean
              default: false
            type_handicap_utilisateur:
              type: string
            chauffeurs:
              type: array
              items:
                type: object
                properties:
                  id: { type: string }
                  latitude: { type: number }
                  longitude: { type: number }
                  noteMoyenne: { type: number }
                  anneesExperience: { type: number }
                  specialisation: { type: string }
    responses:
      200:
        description: Liste des chauffeurs triés par score
      400:
        description: Données invalides
    """
    try:
        data = request.get_json(force=True, silent=True) or {}
        lat = float(data.get("latitude_utilisateur") or data.get("lat_utilisateur") or 0)
        lon = float(data.get("longitude_utilisateur") or data.get("lon_utilisateur") or 0)
        chauffeurs = data.get("chauffeurs") or []
        type_handicap = data.get("type_handicap_utilisateur") or data.get("type_handicap")
        urgence = bool(data.get("urgence"))
        resultats = matching_chauffeurs(lat, lon, chauffeurs, type_handicap_utilisateur=type_handicap, urgence=urgence)
        return jsonify({"chauffeurs": resultats}), 200
    except Exception as e:
        return jsonify({"erreur": str(e)}), 400


# ---------- POST /api/demande ----------
@app.route("/api/demande", methods=["POST"])
def api_demande():
    """
    Détection urgence par mots-clés dans la description
    ---
    tags:
      - Demande
    parameters:
      - in: body
        name: body
        required: true
        schema:
          type: object
          properties:
            description:
              type: string
              example: "Besoin urgent pour rendez-vous hôpital"
    responses:
      200:
        description: urgence (bool) et mots_detectes (liste)
      400:
        description: Erreur
    """
    try:
        data = request.get_json(force=True, silent=True) or {}
        description = data.get("description") or data.get("texte") or ""
        resultat = detecter_urgence(description)
        return jsonify(resultat), 200
    except Exception as e:
        return jsonify({"erreur": str(e)}), 400


# ---------- GET /api/eta ----------
@app.route("/api/eta", methods=["GET"])
def api_eta():
    """
    Estimation du temps d'arrivée (distance Haversine / vitesse)
    ---
    tags:
      - ETA
    parameters:
      - name: lat_chauffeur
        in: query
        type: number
        required: true
      - name: lon_chauffeur
        in: query
        type: number
        required: true
      - name: lat_utilisateur
        in: query
        type: number
        required: true
      - name: lon_utilisateur
        in: query
        type: number
        required: true
      - name: vitesse_kmh
        in: query
        type: number
        default: 30
    responses:
      200:
        description: distance_km, duree_minutes, vitesse_kmh_utilisee
      400:
        description: Paramètres invalides
    """
    try:
        lat_c = float(request.args.get("lat_chauffeur", 0) or 0)
        lon_c = float(request.args.get("lon_chauffeur", 0) or 0)
        lat_u = float(request.args.get("lat_utilisateur") or request.args.get("lat_user") or 0)
        lon_u = float(request.args.get("lon_utilisateur") or request.args.get("lon_user") or 0)
        vitesse = request.args.get("vitesse_kmh", type=float)
        resultat = estimer_eta(lat_c, lon_c, lat_u, lon_u, vitesse_kmh=vitesse)
        return jsonify(resultat), 200
    except (TypeError, ValueError) as e:
        return jsonify({"erreur": "Paramètres invalides (lat/lon nombres)", "detail": str(e)}), 400


# ---------- GET /api/recommandations ----------
@app.route("/api/recommandations", methods=["GET", "POST"])
def api_recommandations():
    """
    Recommandations personnalisées (historique notes + même handicap)
    ---
    tags:
      - Recommandations
    parameters:
      - name: type_handicap
        in: query
        type: string
      - name: top_n
        in: query
        type: integer
        default: 10
      - in: body
        name: body
        schema:
          type: object
          properties:
            type_handicap_utilisateur: { type: string }
            historique_notes_utilisateur: { type: array }
            chauffeurs: { type: array }
            top_n: { type: integer }
    responses:
      200:
        description: recommandations (liste)
    """
    try:
        if request.method == "POST":
            data = request.get_json(force=True, silent=True) or {}
            type_handicap = data.get("type_handicap_utilisateur") or data.get("type_handicap")
            historique = data.get("historique_notes_utilisateur") or data.get("historique_notes")
            chauffeurs = data.get("chauffeurs") or []
            top_n = int(data.get("top_n") or 10)
        else:
            type_handicap = request.args.get("type_handicap_utilisateur") or request.args.get("type_handicap")
            top_n = request.args.get("top_n", type=int) or 10
            # GET sans body : on attend que les données soient passées en query ou on retourne structure vide
            historique = []
            chauffeurs = []
        resultats = recommandations_personnalisees(
            type_handicap_utilisateur=type_handicap,
            historique_notes_utilisateur=historique,
            chauffeurs=chauffeurs,
            top_n=top_n,
        )
        return jsonify({"recommandations": resultats}), 200
    except Exception as e:
        return jsonify({"erreur": str(e)}), 400


# ---------- POST /api/optimiser-tournee ----------
@app.route("/api/optimiser-tournee", methods=["POST"])
def api_optimiser_tournee():
    """
    Optimisation tournée : plus proche voisin (Haversine)
    ---
    tags:
      - Tournée
    parameters:
      - in: body
        name: body
        required: true
        schema:
          type: object
          properties:
            depot:
              type: object
              properties:
                latitude: { type: number }
                longitude: { type: number }
            points:
              type: array
              items:
                type: object
                properties:
                  id: { type: string }
                  latitude: { type: number }
                  longitude: { type: number }
    responses:
      200:
        description: ordre (liste), distance_totale_km
      400:
        description: Erreur
    """
    try:
        data = request.get_json(force=True, silent=True) or {}
        depot = data.get("depot") or {}
        points = data.get("points") or data.get("trajets") or []
        resultat = optimiser_tournee(depot, points)
        return jsonify(resultat), 200
    except Exception as e:
        return jsonify({"erreur": str(e)}), 400


# ---------- POST /api/analyse-avis ----------
@app.route("/api/analyse-avis", methods=["POST"])
def api_analyse_avis():
    """
    Analyse de sentiment (TextBlob) et mots-clés
    ---
    tags:
      - Avis
    parameters:
      - in: body
        name: body
        required: true
        schema:
          type: object
          properties:
            avis:
              type: string
              example: "Service excellent, chauffeur à l'heure."
    responses:
      200:
        description: polarite, subjectivite, mots_cles
      400:
        description: Erreur
    """
    try:
        data = request.get_json(force=True, silent=True) or {}
        raw = data.get("avis") or data.get("texte") or data.get("textes")
        if isinstance(raw, list):
            analyses = [analyser_avis(t) for t in raw]
            for a in analyses:
                _analyses_avis.append(a)
                if est_alerte_negatif(a, _SEUIL_ALERTE_POLARITE):
                    _alertes.append({"type": "sentiment_negatif", "analyse": a})
            return jsonify({"analyses": analyses}), 200
        analyse = analyser_avis(raw)
        _analyses_avis.append(analyse)
        if est_alerte_negatif(analyse, _SEUIL_ALERTE_POLARITE):
            _alertes.append({"type": "sentiment_negatif", "analyse": analyse})
        return jsonify(analyse), 200
    except Exception as e:
        return jsonify({"erreur": str(e)}), 400


# ---------- GET /api/alertes ----------
@app.route("/api/alertes", methods=["GET"])
def api_alertes():
    """
    Liste des alertes (avis très négatifs)
    ---
    tags:
      - Alertes
    parameters:
      - name: limit
        in: query
        type: integer
        default: 50
    responses:
      200:
        description: alertes (liste), total
    """
    try:
        limit = request.args.get("limit", type=int) or 50
        return jsonify({"alertes": _alertes[-limit:], "total": len(_alertes)}), 200
    except Exception as e:
        return jsonify({"erreur": str(e)}), 400


# ---------- Health ----------
@app.route("/health", methods=["GET"])
def health():
    """
    Vérification du statut de l'API (health check)
    ---
    tags:
      - Health
    responses:
      200:
        description: API opérationnelle
    """
    return jsonify({"status": "ok", "service": "transport-adapte"}), 200


@app.route("/", methods=["GET"])
def index():
    """
    Vérification du statut de l'API et liste des endpoints
    ---
    tags:
      - Health
    responses:
      200:
        description: Service et liste des endpoints disponibles
    """
    doc = {
        "service": "Transport adapté - API Flask",
        "swagger": "http://127.0.0.1:5001/api-docs" if FLASGGER_AVAILABLE else "Installer flasgger (pip install flasgger) puis redémarrer pour Swagger",
        "endpoints": {
            "POST /api/match": "Matching chauffeurs (proximité, notes, spécialisation, urgence)",
            "POST /api/demande": "Détection urgence par mots-clés",
            "GET /api/eta": "Estimation temps d'arrivée (Haversine + vitesse)",
            "GET/POST /api/recommandations": "Recommandations personnalisées",
            "POST /api/optimiser-tournee": "Ordre de passages (plus proche voisin)",
            "POST /api/analyse-avis": "Sentiment TextBlob + mots-clés",
            "GET /api/alertes": "Alertes (avis très négatifs)",
        },
    }
    return jsonify(doc), 200


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5001))
    app.run(host="0.0.0.0", port=port, debug=os.environ.get("FLASK_DEBUG", "false").lower() == "true")
