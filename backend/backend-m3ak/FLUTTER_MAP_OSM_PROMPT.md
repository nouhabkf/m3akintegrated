# Prompt Ma3ak — Carte OpenStreetMap et calcul d’itinéraires (Flutter)

> Donne ce prompt à l’IA (ex. Cursor) qui développe l’application mobile Flutter Ma3ak. Il décrit le module **Map** (OpenStreetMap) pour le géocodage, la géocodage inverse et le calcul d’itinéraires. À utiliser pour le **transport** et la **réservation de véhicules** (adresses départ / destination).

---

## Contexte des nouveautés backend

Le backend Ma3ak expose désormais une API **Map** basée sur **OpenStreetMap** (Nominatim pour le géocodage, OSRM pour les itinéraires). Aucune clé API n’est requise côté client : tout passe par le backend.

**Objectifs :**

- **Transport** : afficher une carte, choisir départ/destination, calculer et afficher le trajet.
- **Réservation de véhicules** : saisir ou choisir sur la carte le lieu de départ et le lieu de destination, afficher l’itinéraire estimé.

**Base URL API :** `http://localhost:3000` (ou l’URL de production configurée dans l’app Flutter).

**Documentation API :** `http://localhost:3000/api` (Swagger).

**Prompts associés :**

- `FLUTTER_VEHICLE_RESERVATION_PROMPT.md` — Réservation de véhicules (endpoints, DTOs).
- `FLUTTER_VEHICLE_CRUD_PROMPT.md` — CRUD véhicules.
- `FLUTTER_APP_PROMPT.md` — Vue d’ensemble de l’app.

---

## 1. Endpoints API Map (aucune authentification)

Tous les endpoints ci‑dessous sont **sans JWT**. Préfixe : `GET/POST .../map/...`.

| Méthode | Endpoint | Description |
|--------|----------|-------------|
| **POST** | `/map/geocode` | Adresse → liste de coordonnées (géocodage) |
| **GET** | `/map/geocode` | Idem en GET : `?q=...&countrycodes=TN&limit=5` |
| **POST** | `/map/reverse-geocode` | Coordonnées → adresse (géocodage inverse) |
| **GET** | `/map/reverse-geocode` | Idem en GET : `?lat=36.8&lon=10.18` |
| **POST** | `/map/route` | Calcul d’itinéraire entre origine et destination |

---

## 2. Détails des requêtes / réponses

### 2.1 Géocodage — POST /map/geocode

**Body :**

```json
{
  "query": "Avenue Habib Bourguiba, Tunis",
  "countrycodes": "TN",
  "limit": 5
}
```

- `query` (string, requis) : adresse ou nom de lieu.
- `countrycodes` (string, optionnel) : code pays ISO (ex. `TN` pour Tunisie).
- `limit` (number, optionnel) : nombre max de résultats (défaut 5).

**Réponse (liste) :**

```json
[
  {
    "lat": 36.8065,
    "lon": 10.1815,
    "displayName": "Avenue Habib Bourguiba, Tunis, Tunisia",
    "type": "road",
    "address": { "road": "Avenue Habib Bourguiba", "city": "Tunis", "country": "Tunisia" }
  }
]
```

**Modèles Dart suggérés :**

```dart
class GeocodeResult {
  final double lat;
  final double lon;
  final String displayName;
  final String type;
  final Map<String, String>? address;

  GeocodeResult({required this.lat, required this.lon, required this.displayName, required this.type, this.address});

  factory GeocodeResult.fromJson(Map<String, dynamic> json) => GeocodeResult(
    lat: (json['lat'] as num).toDouble(),
    lon: (json['lon'] as num).toDouble(),
    displayName: json['displayName'] as String? ?? '',
    type: json['type'] as String? ?? '',
    address: json['address'] != null ? Map<String, String>.from(json['address'] as Map) : null,
  );
}
```

---

### 2.2 Géocodage inverse — POST /map/reverse-geocode

**Body :**

```json
{
  "lat": 36.8065,
  "lon": 10.1815
}
```

**Réponse (objet unique ou null) :**

```json
{
  "lat": 36.8065,
  "lon": 10.1815,
  "displayName": "Avenue Habib Bourguiba, Tunis, Tunisia",
  "type": "road",
  "address": { "road": "Avenue Habib Bourguiba", "city": "Tunis" }
}
```

Même structure que un élément de la liste du géocodage ; réutiliser `GeocodeResult`.

---

### 2.3 Calcul d’itinéraire — POST /map/route

**Body :**

```json
{
  "origin": { "lat": 36.8065, "lon": 10.1815 },
  "destination": { "lat": 36.8536, "lon": 10.3239 },
  "waypoints": []
}
```

- `origin` (objet `{ lat, lon }`, requis) : point de départ.
- `destination` (objet `{ lat, lon }`, requis) : point d’arrivée.
- `waypoints` (tableau optionnel) : points intermédiaires `{ lat, lon }`.

**Réponse :**

```json
{
  "distance": 15234,
  "duration": 1245,
  "geometry": {
    "type": "LineString",
    "coordinates": [[10.1815, 36.8065], [10.2, 36.82], [10.3239, 36.8536]]
  },
  "waypoints": [
    { "lat": 36.8065, "lon": 10.1815 },
    { "lat": 36.8536, "lon": 10.3239 }
  ]
}
```

- `distance` : en **mètres**.
- `duration` : en **secondes**.
- `geometry.coordinates` : tableau `[longitude, latitude]` (ordre GeoJSON).

**Modèles Dart suggérés :**

```dart
class RouteResult {
  final double distance;      // mètres
  final double duration;     // secondes
  final RouteGeometry geometry;
  final List<LatLng> waypoints;

  RouteResult({required this.distance, required this.duration, required this.geometry, required this.waypoints});

  factory RouteResult.fromJson(Map<String, dynamic> json) => RouteResult(
    distance: (json['distance'] as num).toDouble(),
    duration: (json['duration'] as num).toDouble(),
    geometry: RouteGeometry.fromJson(json['geometry'] as Map<String, dynamic>),
    waypoints: (json['waypoints'] as List?)
        ?.map((e) => LatLng((e['lat'] as num).toDouble(), (e['lon'] as num).toDouble()))
        .toList() ?? [],
  );
}

class RouteGeometry {
  final String type;
  final List<List<double>> coordinates; // [lon, lat]

  RouteGeometry({required this.type, required this.coordinates});

  factory RouteGeometry.fromJson(Map<String, dynamic> json) => RouteGeometry(
    type: json['type'] as String? ?? 'LineString',
    coordinates: (json['coordinates'] as List?)
        ?.map((e) => (e as List).map((v) => (v as num).toDouble()).toList())
        .toList() ?? [],
  );

  /// Pour flutter_map / polyline : [lat, lon] par point
  List<LatLng> toLatLngList() => coordinates
      .map((c) => LatLng(c[1], c[0]))
      .toList();
}
```

---

## 3. Intégration Flutter — cartes OpenStreetMap

### 3.1 Packages recommandés

- **flutter_map** : affichage de cartes avec tuiles OSM.
- **latlong2** (ou `latlong`) : type `LatLng` et calculs.
- **http** ou **dio** : appels à l’API backend (pas aux serveurs OSM directement pour géocodage/route).

Exemple `pubspec.yaml` :

```yaml
dependencies:
  flutter_map: ^6.0.0
  latlong2: ^0.9.0
  http: ^1.0.0
```

### 3.2 Service API Map côté Flutter

Créer un service (ex. `MapApiService`) qui appelle la **base URL du backend** :

- `POST $baseUrl/map/geocode` avec body `{ "query": "...", "countrycodes": "TN", "limit": 5 }`.
- `POST $baseUrl/map/reverse-geocode` avec body `{ "lat": ..., "lon": ... }`.
- `POST $baseUrl/map/route` avec body `{ "origin": { "lat", "lon" }, "destination": { "lat", "lon" } }`.

Gérer les erreurs (réseau, 400) et parser les réponses avec les modèles ci‑dessus.

### 3.3 Affichage de la carte (flutter_map)

- Utiliser les **tuiles OpenStreetMap** (ex. `TileLayer` avec `urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'`).
- **Marqueurs** : utiliser les `lat`/`lon` des résultats de géocodage ou des points saisis pour transport / réservation véhicule.
- **Itinéraire** : après appel à `POST /map/route`, afficher `geometry.coordinates` sous forme de **polyline** (ordre [lat, lon] selon la lib utilisée ; le backend renvoie [lon, lat] en GeoJSON).

### 3.4 UX recommandée

- **Recherche d’adresse** : champ de recherche → appel `POST /map/geocode` (ou GET avec `q=...`) → affichage des suggestions → au choix, centrer la carte et placer un marqueur.
- **Choix sur la carte** : au tap long (ou bouton “Choisir ce point”), récupérer les coordonnées → optionnel : `POST /map/reverse-geocode` pour afficher l’adresse.
- **Réservation véhicule / transport** : après saisie ou choix de départ et destination, appeler `POST /map/route` et afficher la polyline + distance/durée (ex. “~15 km, ~20 min”).

---

## 4. Où utiliser la Map dans l’app

| Écran / flux | Usage des endpoints Map |
|--------------|---------------------------|
| **Transport** | Géocodage pour départ/destination ; `/map/route` pour afficher le trajet. |
| **Réservation de véhicules** | Géocodage pour lieu de départ/destination ; `/map/route` pour prévisualiser l’itinéraire avant création de la réservation. |

Les endpoints **transport** et **vehicle-reservation** restent ceux décrits dans le README et dans les prompts existants ; le module Map enrichit l’UX avec la carte et les trajets.

---

## 6. Localisation actuelle en continu (live)

L’utilisateur doit pouvoir **récupérer sa position en temps réel** (flux continu) pour : afficher sa position sur la carte, partager sa position pendant un transport, etc.

### 6.1 Backend — Mise à jour de la position (JWT requis)

| Méthode | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| **PATCH** | `/user/me/location` | **JWT** | Enregistrer la position actuelle (lat, lon). À appeler régulièrement depuis l’app pour garder une position “live” côté serveur. |

**Body :**

```json
{
  "lat": 36.8065,
  "lon": 10.1815
}
```

**Réponse :** Profil utilisateur mis à jour (avec `latitude`, `longitude`, `lastLocationAt`).

Le schéma User contient désormais : `latitude`, `longitude`, `lastLocationAt` (optionnels). GET `/user/me` les renvoie.

### 6.2 Flutter — Récupérer la position en continu (stream)

- Utiliser le package **geolocator** (ou **location**) pour le flux de position.
- **Demander les permissions** : localisation en cours d’utilisation (et éventuellement en arrière-plan si besoin).

**Exemple `pubspec.yaml` :**

```yaml
dependencies:
  geolocator: ^10.0.0
```

**Permissions :**

- **Android** : `android/app/src/main/AndroidManifest.xml`  
  `<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />`  
  `<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />`  
  Pour position en arrière-plan : `ACCESS_BACKGROUND_LOCATION` (Android 10+).
- **iOS** : `ios/Runner/Info.plist`  
  `NSLocationWhenInUseUsageDescription` et éventuellement `NSLocationAlwaysAndWhenInUseUsageDescription`.

**Flux de position en continu :**

```dart
import 'package:geolocator/geolocator.dart';

// Vérifier / demander la permission
Future<bool> checkLocationPermission() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) return false;
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  return permission == LocationPermission.whileInUse ||
         permission == LocationPermission.always;
}

// Position ponctuelle
Future<Position?> getCurrentPosition() async {
  if (!await checkLocationPermission()) return null;
  return await Geolocator.getCurrentPosition(
    locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
  );
}

// Flux de position en continu (live) — à écouter avec StreamBuilder ou listen()
Stream<Position> getLocationStream() {
  const locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10, // en mètres : nouveau point tous les 10 m (ajuster selon besoin)
  );
  return Geolocator.getPositionStream(locationSettings: locationSettings);
}
```

**Utilisation typique :**

- Démarrer `getPositionStream().listen((Position position) { ... })` quand l’écran carte / transport est visible.
- Dans le listener : mettre à jour un state (ex. `currentPosition`), déplacer le marqueur sur la carte, et optionnellement appeler `PATCH /user/me/location` avec `position.latitude` et `position.longitude` (par ex. toutes les N secondes ou tous les M mètres pour limiter les appels API).
- Annuler l’écoute du stream dans `dispose()` pour arrêter les mises à jour.

### 6.3 Envoi périodique au backend

Pour garder la position “live” sur le serveur (ex. pour que les contacts urgence ou l’accompagnant voient la position) :

- Depuis le stream, envoyer par exemple toutes les 30 secondes ou tous les 50 m un `PATCH /user/me/location` avec le token JWT et le body `{ "lat": position.latitude, "lon": position.longitude }`.
- Ne pas envoyer à chaque événement du stream si la fréquence est élevée, pour éviter de surcharger l’API.

---

## 7. Résumé pour Cursor / IA

- **Backend** : Module **Map** (OpenStreetMap) : `POST/GET /map/geocode`, `POST/GET /map/reverse-geocode`, `POST /map/route`. Pas d’auth. **User** : `PATCH /user/me/location` (JWT) pour enregistrer la position live ; champs `latitude`, `longitude`, `lastLocationAt` sur le profil.
- **Flutter** : **flutter_map** + tuiles OSM ; appels backend `/map/*` pour géocodage et itinéraires. **geolocator** pour récupérer la **position en continu** via `getPositionStream()` ; permissions Android/iOS ; optionnellement envoyer la position au backend avec `PATCH /user/me/location` de façon périodique.
- **Objectif** : Carte, trajets et **localisation actuelle constante et live** pour transport, réservation de véhicules et partage de position.
