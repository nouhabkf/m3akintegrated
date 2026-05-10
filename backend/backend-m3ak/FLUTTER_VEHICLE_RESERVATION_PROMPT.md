# Prompt Ma3ak — Réservation Véhicules Flutter

> Donne ce prompt à l'IA qui développe l'application mobile Flutter Ma3ak. Il décrit l'intégration du module **Réservation de véhicules** permettant aux personnes handicapées de réserver un véhicule accessible.

---

## Contexte

Le backend Ma3ak expose une API REST pour la **réservation de véhicules**. Les personnes handicapées (rôle `HANDICAPE`) peuvent réserver un véhicule accessible via l'application Flutter. Seuls les véhicules au statut `VALIDE` sont réservables.

**Base URL API :** `http://localhost:3000` (ou l'URL de production)

**Swagger :** `http://localhost:3000/api` — documentation complète.

**Référence :** Le prompt `FLUTTER_VEHICLE_CRUD_PROMPT.md` décrit le CRUD véhicules. Ce prompt complète avec les **réservations**.

---

## 1. Schéma de données

### Modèle VehicleReservation

```dart
class VehicleReservation {
  String id;               // _id MongoDB
  String userId;           // ID du handicapé qui réserve (User)
  String vehicleId;        // ID du véhicule (Vehicle)
  DateTime date;           // Date de réservation
  String heure;            // Heure de départ (ex: "14:30")
  String? lieuDepart;      // Lieu de départ
  String? lieuDestination; // Lieu de destination
  String? besoinsSpecifiques;  // Besoins spécifiques
  String? qrCode;          // QR Code généré par le backend
  VehicleReservationStatut statut;  // EN_ATTENTE | CONFIRMEE | ANNULEE | TERMINEE
  DateTime? createdAt;
  DateTime? updatedAt;
  Vehicle? vehicle;        // Si populate vehicleId
  User? user;              // Si populate userId
}

enum VehicleReservationStatut {
  EN_ATTENTE,
  CONFIRMEE,
  ANNULEE,
  TERMINEE,
}
```

---

## 2. Endpoints API

### Tableau récapitulatif

| Méthode | Endpoint | Auth | Description |
|---------|----------|------|-------------|
| POST | `/vehicle-reservations` | **JWT** | Créer une réservation |
| GET | `/vehicle-reservations/me` | **JWT** | Mes réservations |
| GET | `/vehicle-reservations/vehicle/:vehicleId` | **JWT** | Réservations d'un véhicule |
| GET | `/vehicle-reservations/:id` | **JWT** | Détail d'une réservation |
| POST | `/vehicle-reservations/:id/statut` | **JWT** | Mettre à jour le statut |
| DELETE | `/vehicle-reservations/:id` | **JWT** | Annuler une réservation |

### Header d'authentification

**Toutes** les routes exigent :

```
Authorization: Bearer <access_token>
```

---

## 3. Détails des requêtes / réponses

### POST /vehicle-reservations — Créer une réservation

**Body (CreateVehicleReservationDto) :**

```json
{
  "vehicleId": "64abc123...",
  "date": "2025-03-15",
  "heure": "14:30",
  "lieuDepart": "123 Rue Example, Tunis",
  "lieuDestination": "Centre commercial",
  "besoinsSpecifiques": "Fauteuil roulant, rampe requise"
}
```

- **vehicleId** : obligatoire — ID du véhicule (doit être VALIDE)
- **date** : obligatoire — Format ISO (YYYY-MM-DD)
- **heure** : obligatoire — Format HH:mm
- **lieuDepart**, **lieuDestination**, **besoinsSpecifiques** : optionnels

Le `userId` est extrait automatiquement du JWT (utilisateur connecté = handicapé qui réserve).

**Réponse 201** : objet VehicleReservation créé (vehicleId peuplé avec le véhicule).

**Erreurs :**
- **400** : validation, véhicule non réservable (statut ≠ VALIDE), conflit de réservation (véhicule déjà réservé à cette date/heure)
- **401** : non authentifié
- **404** : véhicule non trouvé

---

### GET /vehicle-reservations/me — Mes réservations

**Réponse 200** : tableau de VehicleReservation (vehicleId peuplé).

---

### GET /vehicle-reservations/vehicle/:vehicleId — Réservations d'un véhicule

**Réponse 200** : tableau de VehicleReservation (userId peuplé).

---

### GET /vehicle-reservations/:id — Détail

**Réponse 200** : objet VehicleReservation (vehicleId et userId peuplés).

**Erreur 404** : réservation non trouvée.

---

### POST /vehicle-reservations/:id/statut — Mettre à jour le statut

**Body :**

```json
{
  "statut": "CONFIRMEE"
}
```

Statuts autorisés : `EN_ATTENTE`, `CONFIRMEE`, `ANNULEE`, `TERMINEE`.

**Réponse 200** : objet VehicleReservation mis à jour.

---

### DELETE /vehicle-reservations/:id — Annuler

**Réponse 200 :**

```json
{
  "message": "Réservation annulée"
}
```

---

## 4. Structure Flutter recommandée

### Arborescence

```
lib/
├── models/
│   ├── vehicle_reservation.dart
│   └── vehicle_reservation_statut.dart (enum)
├── services/
│   └── vehicle_reservation_service.dart
├── screens/
│   └── vehicle_reservation/
│       ├── vehicle_reservation_list_screen.dart   # Mes réservations
│       ├── vehicle_reservation_detail_screen.dart # Détail d'une réservation
│       └── vehicle_reservation_form_screen.dart   # Créer une réservation
└── widgets/
    └── vehicle_reservation/
        ├── vehicle_reservation_card.dart
        └── vehicle_reservation_statut_chip.dart
```

---

## 5. Modèle VehicleReservation (Dart)

```dart
class VehicleReservation {
  final String id;
  final String userId;
  final String vehicleId;
  final DateTime date;
  final String heure;
  final String? lieuDepart;
  final String? lieuDestination;
  final String? besoinsSpecifiques;
  final String? qrCode;
  final VehicleReservationStatut statut;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Vehicle? vehicle;
  final User? user;

  VehicleReservation({
    required this.id,
    required this.userId,
    required this.vehicleId,
    required this.date,
    required this.heure,
    this.lieuDepart,
    this.lieuDestination,
    this.besoinsSpecifiques,
    this.qrCode,
    required this.statut,
    this.createdAt,
    this.updatedAt,
    this.vehicle,
    this.user,
  });

  factory VehicleReservation.fromJson(Map<String, dynamic> json) {
    return VehicleReservation(
      id: json['_id'],
      userId: json['userId'] is Map 
          ? json['userId']['_id'] 
          : json['userId'].toString(),
      vehicleId: json['vehicleId'] is Map 
          ? json['vehicleId']['_id'] 
          : json['vehicleId'].toString(),
      date: DateTime.parse(json['date']),
      heure: json['heure'],
      lieuDepart: json['lieuDepart'],
      lieuDestination: json['lieuDestination'],
      besoinsSpecifiques: json['besoinsSpecifiques'],
      qrCode: json['qrCode'],
      statut: VehicleReservationStatut.values.firstWhere(
        (e) => e.name == json['statut'],
        orElse: () => VehicleReservationStatut.EN_ATTENTE,
      ),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
      vehicle: json['vehicleId'] is Map ? Vehicle.fromJson(json['vehicleId']) : null,
      user: json['userId'] is Map ? User.fromJson(json['userId']) : null,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'vehicleId': vehicleId,
      'date': date.toIso8601String().split('T')[0],
      'heure': heure,
      if (lieuDepart != null) 'lieuDepart': lieuDepart,
      if (lieuDestination != null) 'lieuDestination': lieuDestination,
      if (besoinsSpecifiques != null) 'besoinsSpecifiques': besoinsSpecifiques,
    };
  }
}
```

---

## 6. VehicleReservationService (exemple)

```dart
class VehicleReservationService {
  final String baseUrl;
  final String? token;

  VehicleReservationService({required this.baseUrl, this.token});

  Future<VehicleReservation> create(CreateVehicleReservationDto dto) async {
    final res = await _post('/vehicle-reservations', dto.toJson());
    return VehicleReservation.fromJson(res);
  }

  Future<List<VehicleReservation>> getMine() async {
    final res = await _get('/vehicle-reservations/me');
    return (res as List).map((e) => VehicleReservation.fromJson(e)).toList();
  }

  Future<VehicleReservation> findOne(String id) async {
    final res = await _get('/vehicle-reservations/$id');
    return VehicleReservation.fromJson(res);
  }

  Future<VehicleReservation> updateStatut(String id, String statut) async {
    final res = await _post('/vehicle-reservations/$id/statut', {'statut': statut});
    return VehicleReservation.fromJson(res);
  }

  Future<void> cancel(String id) async {
    await _delete('/vehicle-reservations/$id');
  }

  // _get, _post, _delete avec header Authorization: Bearer <token>
}
```

---

## 7. Écrans UI à implémenter

### 7.1 Liste « Mes réservations » (`VehicleReservationListScreen`)

- **Accès** : depuis le menu / profil utilisateur connecté (handicapé).
- **Contenu** :
  - AppBar « Mes réservations de véhicules », bouton + pour créer.
  - Appel `GET /vehicle-reservations/me`.
  - Liste avec `VehicleReservationCard` : véhicule (marque, modèle), date, heure, statut, lieux.
  - Badge statut : EN_ATTENTE (orange), CONFIRMEE (vert), ANNULEE (rouge), TERMINEE (gris).
  - Clic sur une carte → `VehicleReservationDetailScreen(id)`.

### 7.2 Formulaire création (`VehicleReservationFormScreen`)

- **Entrée** : `vehicleId` (ID du véhicule sélectionné) — depuis la liste des véhicules ou le détail d'un véhicule.
- **Champs** :
  - Date (DatePicker)
  - Heure (TimePicker ou TextField format HH:mm)
  - Lieu de départ (TextField)
  - Lieu de destination (TextField)
  - Besoins spécifiques (TextField multiligne)
- **Validation** : date, heure obligatoires.
- **Action** : POST `/vehicle-reservations` → navigation vers détail ou liste + SnackBar succès.
- **Gestion erreurs** : 400 (véhicule non réservable, conflit) → message clair.

### 7.3 Détail réservation (`VehicleReservationDetailScreen`)

- **Contenu** :
  - Infos véhicule (marque, modèle, immatriculation, accessibilité).
  - Date, heure, lieu départ, lieu destination.
  - Badge statut.
  - QR Code (si fourni par l’API).
  - Bouton Annuler (si EN_ATTENTE ou CONFIRMEE) → confirmation → DELETE.

---

## 8. Parcours utilisateur (handicapé)

1. L’utilisateur handicapé consulte la liste des véhicules disponibles (`GET /vehicles?statut=VALIDE`).
2. Il sélectionne un véhicule et clique sur « Réserver ».
3. Navigation vers `VehicleReservationFormScreen(vehicleId: ...)`.
4. Il remplit date, heure, lieux, besoins et valide.
5. Création de la réservation → navigation vers détail ou liste « Mes réservations ».
6. Depuis « Mes réservations », il peut consulter le détail et annuler si nécessaire.

---

## 9. Règles métier et UX

1. **Véhicule VALIDE uniquement** : Seuls les véhicules au statut `VALIDE` sont réservables. Afficher un message si l’utilisateur tente de réserver un véhicule non valide.
2. **Conflit de réservation** : En cas de 400 (véhicule déjà réservé à cette date/heure), afficher « Ce véhicule n’est pas disponible à cette date et heure ».
3. **Annulation** : Demander une confirmation (AlertDialog) avant DELETE.
4. **QR Code** : Afficher le QR Code dans le détail de la réservation si fourni (pour scan par le propriétaire du véhicule).

---

## 10. Codes HTTP

| Code | Signification |
|------|---------------|
| 200 / 201 | Succès |
| 400 | Données invalides, véhicule non réservable, conflit de réservation |
| 401 | Non authentifié |
| 404 | Véhicule ou réservation non trouvée |

---

## 11. Checklist de développement

- [ ] Créer le modèle `VehicleReservation` et enum `VehicleReservationStatut`
- [ ] Implémenter `VehicleReservationService`
- [ ] Écran liste « Mes réservations » (`VehicleReservationListScreen`)
- [ ] Écran formulaire création (`VehicleReservationFormScreen`)
- [ ] Écran détail (`VehicleReservationDetailScreen`)
- [ ] Bouton « Réserver » sur la fiche véhicule → navigation vers le formulaire
- [ ] Annulation avec confirmation
- [ ] Gestion des erreurs (400, 401, 404)
