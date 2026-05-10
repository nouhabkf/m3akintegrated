# Prompt Ma3ak — CRUD Véhicules Flutter (détaillé)

> Donne ce prompt à l'IA qui développe l'application mobile Flutter Ma3ak. Il décrit l'intégration complète du module CRUD Véhicules avec l'API backend.

---

## Contexte

Le backend Ma3ak expose une API REST pour la gestion des véhicules (module Vehicle). L'application Flutter doit implémenter un CRUD complet : création, lecture, mise à jour et suppression de véhicules. Les véhicules sont liés aux utilisateurs (propriétaires) et possèdent des caractéristiques d'accessibilité.

**Base URL API :** `http://localhost:3000` (ou l'URL de production)

**Swagger :** `http://localhost:3000/api` — documentation complète.

---

## 1. Schéma de données

### Modèle Vehicle

```dart
class Vehicle {
  String id;                    // _id MongoDB
  String ownerId;               // ObjectId du propriétaire (User)
  String marque;                // Ex: Toyota
  String modele;                // Ex: Yaris
  String immatriculation;       // Ex: 123-456-78
  Accessibilite accessibilite;  // Caractéristiques d'accessibilité
  List<String> photos;          // URLs des photos
  VehicleStatut statut;         // EN_ATTENTE | VALIDE | REFUSE
  DateTime? createdAt;
  DateTime? updatedAt;
  // Si populate ownerId : User? owner (optionnel)
}

enum VehicleStatut {
  EN_ATTENTE,
  VALIDE,
  REFUSE,
}

class Accessibilite {
  bool coffreVaste;      // Coffre vaste
  bool rampeAcces;       // Rampe d'accès
  bool siegePivotant;    // Siège pivotant
  bool climatisation;    // Climatisation
  bool animalAccepte;    // Animal accepté (animal d'assistance)
}
```

### Modèle User (référence pour owner)

Le champ `ownerId` référence un User. Lors de `GET /vehicles/:id` ou `GET /vehicles`, l'API peut retourner `ownerId` peuplé avec : `nom`, `prenom`, `email`, `role`, `telephone` (optionnel).

---

## 2. Endpoints API

### Tableau récapitulatif

| Méthode | Endpoint | Auth | Description |
|---------|----------|------|-------------|
| POST | `/vehicles` | **JWT** | Créer un véhicule |
| GET | `/vehicles` | Non | Liste paginée (filtres : ownerId, statut, page, limit) |
| GET | `/vehicles/owner/:ownerId` | Non | Véhicules d'un propriétaire |
| GET | `/vehicles/:id` | Non | Détail d'un véhicule |
| PATCH | `/vehicles/:id` | **JWT** | Modifier un véhicule |
| DELETE | `/vehicles/:id` | **JWT** | Supprimer un véhicule |

### Header d'authentification

Les routes POST, PATCH et DELETE exigent :

```
Authorization: Bearer <access_token>
```

### Détails des requêtes / réponses

#### POST /vehicles — Créer un véhicule

**Body (CreateVehicleDto) :**

```json
{
  "ownerId": "64abc123...",
  "marque": "Toyota",
  "modele": "Yaris",
  "immatriculation": "123-456-78",
  "accessibilite": {
    "coffreVaste": true,
    "rampeAcces": true,
    "siegePivotant": false,
    "climatisation": true,
    "animalAccepte": true
  },
  "photos": ["https://..."],
  "statut": "EN_ATTENTE"
}
```

- **ownerId** : obligatoire — ID de l'utilisateur connecté ou d'un autre user (selon règles métier)
- **marque**, **modele**, **immatriculation** : obligatoires
- **accessibilite** : optionnel — tous les booléens à false par défaut
- **photos** : optionnel — tableau d'URLs (vide par défaut)
- **statut** : optionnel — défaut `EN_ATTENTE`

**Réponse 201** : objet Vehicle créé.

**Erreurs :**
- **400** : validation (marque, modele, immatriculation requis)
- **401** : non authentifié
- **409** : immatriculation déjà utilisée

---

#### GET /vehicles — Liste paginée

**Query params :**

| Param | Type | Description |
|-------|------|-------------|
| ownerId | string | Filtrer par propriétaire |
| statut | string | EN_ATTENTE, VALIDE, REFUSE |
| page | number | Page (défaut: 1) |
| limit | number | Par page (défaut: 20, max: 100) |

**Réponse 200 :**

```json
{
  "data": [ /* Vehicle[] */ ],
  "total": 42,
  "page": 1,
  "limit": 20,
  "totalPages": 3
}
```

---

#### GET /vehicles/owner/:ownerId — Véhicules d'un propriétaire

**Réponse 200** : tableau de Vehicle.

---

#### GET /vehicles/:id — Détail

**Réponse 200** : objet Vehicle (ownerId peut être peuplé avec les infos User).

**Erreur 404** : véhicule non trouvé.

---

#### PATCH /vehicles/:id — Modifier

**Body (UpdateVehicleDto)** : tous les champs optionnels.

```json
{
  "marque": "Renault",
  "modele": "Clio",
  "immatriculation": "987-654-32",
  "accessibilite": {
    "rampeAcces": true,
    "climatisation": true
  },
  "photos": ["https://...", "https://..."],
  "statut": "VALIDE"
}
```

Seuls les champs envoyés sont mis à jour. Pour `accessibilite`, seules les clés fournies sont fusionnées.

**Réponse 200** : objet Vehicle mis à jour.

**Erreurs :** 400, 401, 404, 409 (immatriculation déjà utilisée).

---

#### DELETE /vehicles/:id — Supprimer

**Réponse 200 :**

```json
{
  "message": "Véhicule supprimé"
}
```

**Erreurs :** 401, 404.

---

## 3. Structure Flutter recommandée

### Arborescence

```
lib/
├── models/
│   ├── vehicle.dart
│   ├── accessibilite.dart
│   └── vehicle_statut.dart (enum)
├── services/
│   └── vehicle_service.dart      # Appels HTTP
├── providers/ ou bloc/           # État (Provider, Riverpod, Bloc...)
│   └── vehicle_provider.dart
├── screens/
│   ├── vehicle/
│   │   ├── vehicle_list_screen.dart      # Liste des véhicules
│   │   ├── vehicle_detail_screen.dart    # Détail
│   │   ├── vehicle_form_screen.dart      # Création / édition
│   │   └── my_vehicles_screen.dart       # Mes véhicules (filtrés par userId)
└── widgets/
    └── vehicle/
        ├── vehicle_card.dart
        ├── accessibilite_form.dart       # Formulaire checkboxes accessibilité
        └── vehicle_statut_chip.dart      # Badge statut (EN_ATTENTE, VALIDE, REFUSE)
```

### Modèle Vehicle (avec fromJson / toJson)

```dart
class Vehicle {
  final String id;
  final String ownerId;
  final String marque;
  final String modele;
  final String immatriculation;
  final Accessibilite accessibilite;
  final List<String> photos;
  final VehicleStatut statut;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final User? owner;  // Si populate

  Vehicle({
    required this.id,
    required this.ownerId,
    required this.marque,
    required this.modele,
    required this.immatriculation,
    required this.accessibilite,
    required this.photos,
    required this.statut,
    this.createdAt,
    this.updatedAt,
    this.owner,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['_id'],
      ownerId: json['ownerId'] is Map 
          ? json['ownerId']['_id'] 
          : json['ownerId'].toString(),
      marque: json['marque'],
      modele: json['modele'],
      immatriculation: json['immatriculation'],
      accessibilite: Accessibilite.fromJson(
        json['accessibilite'] ?? {},
      ),
      photos: List<String>.from(json['photos'] ?? []),
      statut: VehicleStatut.values.firstWhere(
        (e) => e.name == json['statut'],
        orElse: () => VehicleStatut.EN_ATTENTE,
      ),
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt']) 
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.tryParse(json['updatedAt']) 
          : null,
      owner: json['ownerId'] is Map 
          ? User.fromJson(json['ownerId']) 
          : null,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'ownerId': ownerId,
      'marque': marque,
      'modele': modele,
      'immatriculation': immatriculation,
      'accessibilite': accessibilite.toJson(),
      'photos': photos,
      if (statut != VehicleStatut.EN_ATTENTE) 'statut': statut.name,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    final map = <String, dynamic>{};
    // N'envoyer que les champs modifiés (selon ta logique)
    return map;
  }
}

class Accessibilite {
  final bool coffreVaste;
  final bool rampeAcces;
  final bool siegePivotant;
  final bool climatisation;
  final bool animalAccepte;

  Accessibilite({
    this.coffreVaste = false,
    this.rampeAcces = false,
    this.siegePivotant = false,
    this.climatisation = false,
    this.animalAccepte = false,
  });

  factory Accessibilite.fromJson(Map<String, dynamic> json) {
    return Accessibilite(
      coffreVaste: json['coffreVaste'] ?? false,
      rampeAcces: json['rampeAcces'] ?? false,
      siegePivotant: json['siegePivotant'] ?? false,
      climatisation: json['climatisation'] ?? false,
      animalAccepte: json['animalAccepte'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'coffreVaste': coffreVaste,
    'rampeAcces': rampeAcces,
    'siegePivotant': siegePivotant,
    'climatisation': climatisation,
    'animalAccepte': animalAccepte,
  };
}
```

---

## 4. VehicleService (exemple avec Dio / http)

```dart
class VehicleService {
  final String baseUrl;
  final String? token;

  VehicleService({required this.baseUrl, this.token});

  Future<Vehicle> create(Vehicle vehicle) async {
    final res = await _post('/vehicles', vehicle.toCreateJson());
    return Vehicle.fromJson(res);
  }

  Future<Map<String, dynamic>> findAll({
    String? ownerId,
    String? statut,
    int page = 1,
    int limit = 20,
  }) async {
    final q = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (ownerId != null) q['ownerId'] = ownerId;
    if (statut != null) q['statut'] = statut;
    final uri = Uri.parse('$baseUrl/vehicles').replace(queryParameters: q);
    final res = await _get(uri);
    return {
      'data': (res['data'] as List).map((e) => Vehicle.fromJson(e)).toList(),
      'total': res['total'],
      'page': res['page'],
      'limit': res['limit'],
      'totalPages': res['totalPages'],
    };
  }

  Future<List<Vehicle>> findByOwner(String ownerId) async {
    final res = await _get(Uri.parse('$baseUrl/vehicles/owner/$ownerId'));
    return (res as List).map((e) => Vehicle.fromJson(e)).toList();
  }

  Future<Vehicle> findOne(String id) async {
    final res = await _get(Uri.parse('$baseUrl/vehicles/$id'));
    return Vehicle.fromJson(res);
  }

  Future<Vehicle> update(String id, Map<String, dynamic> body) async {
    final res = await _patch('/vehicles/$id', body);
    return Vehicle.fromJson(res);
  }

  Future<void> delete(String id) async {
    await _delete('/vehicles/$id');
  }

  // _get, _post, _patch, _delete : ajouter header Authorization si token
}
```

---

## 5. Écrans UI à implémenter

### 5.1 Liste des véhicules (`VehicleListScreen`)

- **Accès** : depuis le menu / navigation (ex. « Véhicules »).
- **Contenu** :
  - AppBar avec titre « Véhicules », bouton + pour créer.
  - Filtres optionnels : statut (dropdown EN_ATTENTE / VALIDE / REFUSE), propriétaire (si admin).
  - Liste paginée (ListView ou ListView.builder) avec `VehicleCard`.
  - Pull-to-refresh, chargement suivant en scroll (infinite scroll).
  - Clic sur une carte → navigation vers `VehicleDetailScreen(id)`.

### 5.2 Mes véhicules (`MyVehiclesScreen`)

- **Accès** : depuis le profil utilisateur connecté (userId).
- **Contenu** :
  - Appel `GET /vehicles/owner/:userId` avec l’ID de l’utilisateur connecté.
  - Liste des véhicules du propriétaire.
  - Bouton « Ajouter un véhicule » → `VehicleFormScreen(mode: create)`.
  - Clic sur un véhicule → `VehicleDetailScreen(id)`.

### 5.3 Détail d’un véhicule (`VehicleDetailScreen`)

- **Contenu** :
  - Marque, modèle, immatriculation.
  - Badge statut (couleur : EN_ATTENTE = orange, VALIDE = vert, REFUSE = rouge).
  - Section accessibilité : coffre vaste, rampe d’accès, siège pivotant, climatisation, animal accepté (icônes + texte).
  - Galerie photos (si non vide).
  - Boutons : Modifier, Supprimer (avec confirmation).
  - Pour Modifier → `VehicleFormScreen(vehicle: vehicle, mode: edit)`.
  - Pour Supprimer → appel `DELETE /vehicles/:id` → retour liste + message succès.

### 5.4 Formulaire création / édition (`VehicleFormScreen`)

- **Mode create** : `ownerId` = userId connecté (ou champ si admin).
- **Mode edit** : pré-remplir les champs avec les données du véhicule.

**Champs :**

| Champ | Type | Validation |
|-------|------|------------|
| Marque | TextField | Requis, 1–100 caractères |
| Modèle | TextField | Requis, 1–100 caractères |
| Immatriculation | TextField | Requis, 1–50 caractères |
| Accessibilité | Groupe de Switch/Checkbox | Optionnel |
| → Coffre vaste | Switch | |
| → Rampe d’accès | Switch | |
| → Siège pivotant | Switch | |
| → Climatisation | Switch | |
| → Animal accepté | Switch | |
| Photos | (optionnel) | Liste d’URLs ou upload si l’app le supporte |
| Statut | Dropdown (edit uniquement, si admin) | EN_ATTENTE, VALIDE, REFUSE |

**Actions :**

- Bouton Enregistrer → `POST /vehicles` (create) ou `PATCH /vehicles/:id` (edit).
- Gestion erreurs : 400 (afficher les messages de validation), 409 (immatriculation déjà utilisée).
- Succès → navigation vers détail ou liste + SnackBar.

---

## 6. Règles métier et UX

1. **ownerId** : En création, utiliser par défaut l’ID de l’utilisateur connecté. Un admin peut potentiellement choisir un autre propriétaire.
2. **Statut** : En création, le backend met `EN_ATTENTE` par défaut. Seul un admin (ou backoffice) devrait pouvoir passer en VALIDE / REFUSE via le formulaire.
3. **Immatriculation unique** : En cas d’erreur 409, afficher un message clair : « Cette immatriculation est déjà enregistrée ».
4. **Suppression** : Demander une confirmation (AlertDialog) avant `DELETE`.
5. **Photos** : L’API attend des URLs. Si l’app gère l’upload (ex. vers `/user/me/photo` ou un service dédié), stocker l’URL retournée dans `photos`.

---

## 7. Codes HTTP

| Code | Signification |
|------|---------------|
| 200 / 201 | Succès |
| 400 | Données invalides (messages dans `message` array) |
| 401 | Non authentifié (token manquant ou invalide) |
| 403 | Accès refusé |
| 404 | Véhicule non trouvé |
| 409 | Conflit (immatriculation déjà utilisée) |

---

## 8. Tâches prioritaires (checklist)

- [ ] Créer les modèles `Vehicle`, `Accessibilite`, enum `VehicleStatut`.
- [ ] Implémenter `VehicleService` avec tous les appels API.
- [ ] Écran liste (`VehicleListScreen`) avec pagination et filtres.
- [ ] Écran « Mes véhicules » (`MyVehiclesScreen`) pour l’utilisateur connecté.
- [ ] Écran détail (`VehicleDetailScreen`) avec badges et section accessibilité.
- [ ] Formulaire création (`VehicleFormScreen`).
- [ ] Formulaire édition (`VehicleFormScreen` en mode edit).
- [ ] Suppression avec confirmation.
- [ ] Gestion erreurs (400, 401, 404, 409) et messages utilisateur.
- [ ] Intégration dans la navigation (menu, profil).
