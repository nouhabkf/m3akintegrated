# API Flask — Transport adapté (personnes handicapées)

Backend REST **Flask** pour une application de transport adapté. **Bibliothèques gratuites uniquement**, pas d’appel à des APIs payantes.

---

## Installation

```bash
cd flask-transport-api
python3 -m venv venv
source venv/bin/activate   # Windows: venv\Scripts\activate
pip install -r requirements.txt
```

**Swagger** : après l'installation, lancer l'app et ouvrir **http://localhost:5001/api-docs** pour afficher et tester tous les endpoints (comme sur le backend NestJS).

Pour l’analyse de sentiment avec TextBlob (optionnel, téléchargement des données NLTK une fois) :

```bash
python -c "import nltk; nltk.download('brown'); nltk.download('punkt')"
```

---

## Démarrage

```bash
python app.py
```

- API : **http://localhost:5001** (ou `PORT=5000 python app.py` si le port 5001 est pris)
- **Swagger (tester les endpoints)** : **http://localhost:5001/api-docs**
- Health : **http://localhost:5001/health**

---

## Endpoints

### POST /api/match

Matching intelligent des chauffeurs : score basé sur **proximité (Haversine)**, **expérience**, **notes**, **spécialisation**. Bonus si **urgence**.

**Body JSON :**

```json
{
  "latitude_utilisateur": 36.8,
  "longitude_utilisateur": 10.18,
  "urgence": false,
  "type_handicap_utilisateur": "mobilite_reduite",
  "chauffeurs": [
    {
      "id": "c1",
      "latitude": 36.81,
      "longitude": 10.19,
      "noteMoyenne": 4.5,
      "anneesExperience": 5,
      "specialisation": "mobilite_reduite"
    }
  ]
}
```

**Réponse :** `{ "chauffeurs": [ ..., "distance_km", "score_matching" ] }` triés par score décroissant.

---

### POST /api/demande

Détection automatique d’**urgence** par **mots-clés** dans la description (liste simple : urgent, urgence, santé, hôpital, accident, crise, etc.).

**Body JSON :**

```json
{ "description": "Besoin urgent pour rendez-vous hôpital demain 8h." }
```

**Réponse :** `{ "urgence": true, "mots_detectes": ["urgent", "hôpital"] }`

---

### GET /api/eta

**Estimation du temps d’arrivée** : distance Haversine entre chauffeur et utilisateur, puis `durée = distance / vitesse moyenne` (défaut 30 km/h en ville).

**Query :**

- `lat_chauffeur`, `lon_chauffeur`, `lat_utilisateur`, `lon_utilisateur`
- `vitesse_kmh` (optionnel, défaut 30)

**Exemple :**  
`GET /api/eta?lat_chauffeur=36.8&lon_chauffeur=10.18&lat_utilisateur=36.82&lon_utilisateur=10.20&vitesse_kmh=25`

**Réponse :** `{ "distance_km": 2.5, "duree_minutes": 6.0, "vitesse_kmh_utilisee": 25 }`

---

### GET /api/recommandations — POST /api/recommandations

**Recommandations personnalisées** : historique des notes de l’utilisateur + chauffeurs les mieux notés pour le **même handicap**.

**POST Body (recommandé) :**

```json
{
  "type_handicap_utilisateur": "mobilite_reduite",
  "historique_notes_utilisateur": [
    { "chauffeurId": "c1", "note": 5, "typeHandicap": "mobilite_reduite" }
  ],
  "chauffeurs": [ { "id": "c1", "noteMoyenne": 4.8, "specialisation": "mobilite_reduite" }, ... ],
  "top_n": 10
}
```

**Réponse :** `{ "recommandations": [ ... ] }`

---

### POST /api/optimiser-tournee

**Ordre de passages** pour trajets programmés : algorithme du **plus proche voisin (glouton)** avec distances **Haversine**. Départ et retour au dépôt.

**Body JSON :**

```json
{
  "depot": { "latitude": 36.8, "longitude": 10.18 },
  "points": [
    { "id": "A", "latitude": 36.81, "longitude": 10.19 },
    { "id": "B", "latitude": 36.79, "longitude": 10.20 }
  ]
}
```

**Réponse :** `{ "ordre": [ ... ], "distance_totale_km": 12.5 }`

---

### POST /api/analyse-avis

**Analyse de sentiment** avec **TextBlob** (gratuit) et **extraction de mots-clés** (fréquence).

**Body JSON :**

```json
{ "avis": "Service très bien, chauffeur à l'heure et professionnel." }
```

ou plusieurs textes :

```json
{ "avis": [ "Texte 1...", "Texte 2..." ] }
```

**Réponse :** `{ "polarite": 0.35, "subjectivite": 0.6, "mots_cles": [ { "mot": "chauffeur", "frequence": 2 }, ... ] }`

Les avis très négatifs (polarité ≤ -0,3) sont enregistrés comme **alertes** (voir GET /api/alertes).

---

### GET /api/alertes

Liste des **alertes** issues des analyses d’avis (sentiment très négatif). Stockage **en mémoire** (pas de base de données).

**Query :** `limit` (optionnel, défaut 50).

**Réponse :** `{ "alertes": [ ... ], "total": 3 }`

---

## Codes HTTP

- **200** — Succès  
- **400** — Données invalides / paramètres manquants  

---

## Technologies

- **Flask** — serveur HTTP  
- **TextBlob** — analyse de sentiment (gratuit)  
- **Haversine** — formules en Python pur (sans API)  
- Aucune API payante (pas de Google Maps, etc.)
