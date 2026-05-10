# Prompt pour l’app Flutter Ma3ak — Module Transport Adapté Intelligent

> **À donner à l’IA Cursor (ou au dev) en charge du frontend Flutter.**  
> Ce document décrit les changements backend du module **Transport Adapté Intelligent** pour que l’app mobile soit alignée avec l’API.

---

## Contexte

Le backend Ma3ak (NestJS) a été mis à jour pour le **module Transport Adapté Intelligent**. De nouveaux endpoints et champs sont disponibles. L’application Flutter doit les consommer et afficher les nouvelles fonctionnalités (matching avec score, ETA, suivi en direct, fin de trajet avec durée, besoins d’assistance, véhicule à l’acceptation).

**Base URL API :** `http://localhost:3000` (ou l’URL de production).  
**Auth :** Toutes les routes transport exigent `Authorization: Bearer <access_token>`.

---

## 1. Modèle Transport (à jour côté backend)

Chaque demande de transport retournée par l’API peut contenir les champs suivants. **Mettre à jour le modèle Dart** pour les inclure :

```dart
// Exemple de modèle TransportRequest à jour
class TransportRequest {
  String id;
  String demandeurId;
  User? demandeur;           // peuplé si populate
  String? accompagnantId;
  User? accompagnant;        // peuplé si populate
  String? vehicleId;         // NOUVEAU — ID du véhicule assigné
  Vehicle? vehicle;         // NOUVEAU — peuplé si populate
  String typeTransport;     // "URGENCE" | "QUOTIDIEN"
  String depart;
  String destination;
  double latitudeDepart;
  double longitudeDepart;
  double latitudeArrivee;
  double longitudeArrivee;
  DateTime dateHeure;
  List<String> besoinsAssistance;  // NOUVEAU — ex: ["fauteuil_roulant", "aide_embarquement"]
  String statut;             // "EN_ATTENTE" | "ACCEPTEE" | "ANNULEE" | "TERMINEE"
  double? scoreMatching;
  DateTime? dateHeureArrivee;  // NOUVEAU — rempli quand trajet terminé
  int? dureeMinutes;          // NOUVEAU — durée du trajet (trajet terminé)
  DateTime? createdAt;
}
```

---

## 2. Création d’une demande — POST /transport

**Body à envoyer :** en plus des champs existants, envoyer **`besoinsAssistance`** (optionnel).

```dart
// Body pour créer une demande
{
  "typeTransport": "URGENCE" | "QUOTIDIEN",
  "depart": "Adresse départ",
  "destination": "Adresse arrivée",
  "latitudeDepart": 36.8,
  "longitudeDepart": 10.18,
  "latitudeArrivee": 36.82,
  "longitudeArrivee": 10.20,
  "dateHeure": "2025-03-01T08:00:00.000Z",
  "besoinsAssistance": ["fauteuil_roulant", "aide_embarquement"]  // optionnel
}
```

**À faire côté Flutter :**  
- Dans l’écran de création de demande, ajouter un champ (liste ou chips) pour **sélectionner les types d’assistance** (ex. fauteuil roulant, aide à l’embarquement, etc.) et les envoyer dans `besoinsAssistance`.

---

## 3. Matching des accompagnants — GET /transport/matching

**Query params :**

| Paramètre      | Type   | Obligatoire | Description                                      |
|----------------|--------|-------------|--------------------------------------------------|
| `latitude`     | number | oui         | Latitude du demandeur (point de prise en charge) |
| `longitude`    | number | oui         | Longitude du demandeur                          |
| `typeHandicap` | string | non         | Type de handicap du demandeur (pour le score)  |
| `urgence`      | string | non         | `"true"` pour prioriser les urgences dans le score |

**Exemple :**  
`GET /transport/matching?latitude=36.8&longitude=10.18&typeHandicap=mobilite_reduite&urgence=true`

**Réponse :** liste d’accompagnants (users) avec en plus **`distance_km`** et **`score_matching`** (si le backend appelle le module Flask de matching).

**À faire côté Flutter :**  
- Afficher pour chaque accompagnant proposé : **distance_km** et **score_matching** (ex. “À 2,5 km • Score 0,85”).  
- Lors de l’appel au matching depuis l’écran de demande, passer si possible **typeHandicap** (profil du demandeur) et **urgence=true** si le type de transport est URGENCE.

---

## 4. Accepter une demande — POST /transport/:id/accept

**Body (optionnel) :**

```dart
{
  "scoreMatching": 0.92,   // optionnel — score affiché au moment du clic
  "vehicleId": "xxx"       // NOUVEAU — optionnel — ID du véhicule utilisé
}
```

**À faire côté Flutter :**  
- Si l’accompagnant a des véhicules (module Vehicle), proposer de **choisir le véhicule** à l’acceptation et envoyer **vehicleId** dans le body.

---

## 5. Marquer le trajet comme terminé — POST /transport/:id/termine

**Nouvel endpoint.** Réservé aux transports en statut **ACCEPTEE**. Le demandeur ou l’accompagnant peut terminer le trajet.

**Body (optionnel) :**

```dart
{
  "dureeMinutes": 25,     // optionnel
  "dateHeureArrivee": "2025-03-01T08:25:00.000Z"  // optionnel (ISO 8601)
}
```

- Si **dateHeureArrivee** est envoyée et pas **dureeMinutes**, le backend calcule la durée à partir de `dateHeure` et `dateHeureArrivee`.  
- Après l’appel, le statut passe à **TERMINEE** et **dureeMinutes** / **dateHeureArrivee** sont enregistrés pour l’historique.

**À faire côté Flutter :**  
- Sur l’écran de trajet en cours (statut ACCEPTEE), afficher un bouton **“Terminer le trajet”** (pour l’accompagnant ou le demandeur).  
- Optionnel : proposer de saisir l’heure d’arrivée ou la durée, puis appeler **POST /transport/:id/termine** avec le body ci-dessus.  
- Après succès, mettre à jour l’état local et afficher le trajet comme terminé (avec durée dans l’historique).

---

## 6. Détail d’une demande — GET /transport/:id

**Nouvel endpoint.** Retourne une seule demande avec `demandeur`, `accompagnant`, `vehicle` peuplés.

**À faire côté Flutter :**  
- Utiliser cet endpoint pour l’écran de détail d’un transport (et afficher véhicule si présent).

---

## 7. ETA (temps d’arrivée estimé) — GET /transport/:id/eta

**Nouvel endpoint.** Réservé aux transports en statut **ACCEPTEE**.

**Réponse :**

```dart
{
  "distance_km": 2.5,
  "duree_minutes": 6.0,
  "vitesse_kmh_utilisee": 30
}
```

**À faire côté Flutter :**  
- Sur l’écran de trajet en cours (côté demandeur), appeler **GET /transport/:id/eta** (par ex. toutes les 30 s ou au focus) et afficher : “Arrivée estimée dans **X min**” et éventuellement la distance.

---

## 8. Suivi du trajet — GET /transport/:id/suivi

**Nouvel endpoint.** Réservé aux transports en statut **ACCEPTEE**.

**Réponse :**

```dart
{
  "transport": { ... },           // la demande (avec accompagnant, etc.)
  "positionChauffeur": { "lat": 36.81, "lon": 10.19 },
  "eta": {
    "distance_km": 2.5,
    "duree_minutes": 6.0,
    "vitesse_kmh_utilisee": 30
  },
  "itineraire": {                 // peut être null si OSRM échoue
    "distance": 2500,             // mètres
    "duration": 360,              // secondes
    "geometry": { "type": "LineString", "coordinates": [...] }
  }
}
```

**À faire côté Flutter :**  
- Écran “Suivi en direct” : appeler **GET /transport/:id/suivi** périodiquement, afficher la **position du chauffeur** sur une carte, l’**ETA** (durée en minutes) et, si présent, tracer l’**itinéraire** (geometry) sur la carte.

---

## 9. Demandes disponibles (accompagnants) — GET /transport/available

**Comportement backend :** la liste est triée avec **les demandes URGENCE en premier**, puis par date/heure.

**À faire côté Flutter :**  
- Dans la liste des demandes disponibles pour les accompagnants, afficher clairement les **urgences en premier** (badge “Urgence” ou tri déjà respecté).

---

## 10. Historique et durée

**GET /transport/me** retourne `asDemandeur` et `asAccompagnant`. Chaque trajet **TERMINEE** contient maintenant **`dureeMinutes`** et **`dateHeureArrivee`**.

**À faire côté Flutter :**  
- Dans l’historique des trajets, afficher pour chaque trajet terminé : **durée du trajet** (ex. “25 min”) et éventuellement l’heure d’arrivée.

---

## 11. Récapitulatif des tâches Flutter (checklist)

1. **Modèle** : Ajouter à `TransportRequest` : `vehicleId`, `vehicle`, `besoinsAssistance`, `dateHeureArrivee`, `dureeMinutes`.
2. **Création demande** : Champ “Types d’assistance” → envoyer `besoinsAssistance`.
3. **Matching** : Afficher `distance_km` et `score_matching` ; passer en query `typeHandicap` et `urgence` si pertinent.
4. **Acceptation** : Option “Choisir le véhicule” → envoyer `vehicleId` dans le body.
5. **Trajet en cours** : Bouton “Terminer le trajet” → **POST /transport/:id/termine** (avec option durée/heure d’arrivée).
6. **Trajet en cours** : Afficher ETA via **GET /transport/:id/eta** (rafraîchissement périodique).
7. **Suivi** : Écran ou section “Suivi en direct” avec **GET /transport/:id/suivi** (carte + position chauffeur + itinéraire + ETA).
8. **Détail** : Utiliser **GET /transport/:id** pour l’écran détail (avec véhicule si présent).
9. **Liste available** : Mettre en avant les demandes URGENCE (tri backend déjà fait).
10. **Historique** : Afficher `dureeMinutes` et `dateHeureArrivee` pour les trajets terminés.

---

## 12. Codes HTTP (inchangés)

| Code | Signification        |
|------|----------------------|
| 200  | Succès               |
| 201  | Créé                 |
| 400  | Données invalides    |
| 401  | Non authentifié      |
| 403  | Accès refusé         |
| 404  | Ressource non trouvée |

---

*Document généré pour la synchronisation backend (module Transport Adapté) / frontend Flutter Ma3ak. Backend NestJS + optionnel Flask (matching/ETA).*
