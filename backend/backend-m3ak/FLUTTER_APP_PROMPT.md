# Prompt Ma3ak — Application Flutter (changements API 2025)

> Donne ce prompt à l'IA qui développe l'application mobile Flutter Ma3ak. Il décrit les changements récents du backend.

---

## Contexte

L'API backend Ma3ak a été entièrement restructurée. L'application Flutter doit être mise à jour pour consommer la nouvelle API.

**Base URL API :** `http://localhost:3000` (ou l'URL de production)

**Swagger :** `http://localhost:3000/api` — pour voir tous les endpoints et schémas.

---

## 1. Changements User (rôles et schéma)

### Nouveaux rôles

| Ancien | Nouveau |
|--------|---------|
| `BENEFICIARY` | `HANDICAPE` |
| `COMPANION` | `ACCOMPAGNANT` |
| `ADMIN` | `ADMIN` (inchangé) |

### Nouveau schéma User

```dart
// Modèle User à jour
class User {
  String id;
  String nom;          // Nom de famille (anciennement "nom" = nom complet)
  String prenom;       // Nouveau
  String email;
  // password non retourné par l'API
  String? telephone;   // Anciennement "contact"
  String role;         // HANDICAPE | ACCOMPAGNANT | ADMIN
  String? typeHandicap;
  String? besoinSpecifique;
  bool animalAssistance;
  String? typeAccompagnant;   // Pour ACCOMPAGNANT
  String? specialisation;     // Pour ACCOMPAGNANT
  bool disponible;            // Pour ACCOMPAGNANT
  double noteMoyenne;         // Pour ACCOMPAGNANT
  String langue;              // ar, fr, etc.
  String? photoProfil;        // Anciennement "image"
  String statut;              // ACTIF
  DateTime? createdAt;
  DateTime? updatedAt;
}
```

### Changements d'endpoints User

| Ancien | Nouveau |
|--------|---------|
| `PATCH /user/me/image` | `PATCH /user/me/photo` |
| `PATCH /user/me/accompagnants` | Supprimé — remplacer par **Relations** (`/relations`) |
| `GET /user/me/accompagnants` | `GET /relations/me/accompagnants` |
| `GET /user/me/beneficiaires` | Pas d’équivalent direct — utiliser les demandes de transport |

---

## 2. Nouveaux modules à intégrer

### Auth (inchangé)

- `POST /auth/login` — `{ email, password }`
- `POST /auth/google` — `{ id_token }`
- `GET /auth/config-test`

### Inscription (CreateUserDto)

Le body doit inclure : `nom`, `prenom`, `email`, `password`, `telephone`, `role`, et optionnellement `typeHandicap`, `besoinSpecifique`, `animalAssistance`, `typeAccompagnant`, `specialisation`, `langue`, etc.

---

### Relations handicapé ↔ accompagnant

- `POST /relations` — Handicapé : body `{ accompagnantId }` ; accompagnant : `{ handicapId }`
- `POST /relations/:id/accept`
- `DELETE /relations/:id`
- `GET /relations/me` — query `acceptedOnly`
- `GET /relations/me/accompagnants` — côté handicapé
- `GET /relations/me/handicapes` — côté accompagnant
- `GET /relations/:id`

Voir aussi `docs/FLUTTER_RELATIONS_PROMPT.md`.

---

### Transport

- `POST /transport` — Créer une demande  
  Body : `typeTransport` (URGENCE | QUOTIDIEN), `depart`, `destination`, `latitudeDepart`, `longitudeDepart`, `latitudeArrivee`, `longitudeArrivee`, `dateHeure` (ISO)
- `GET /transport/matching?latitude=...&longitude=...` — Accompagnants disponibles
- `POST /transport/:id/accept` — Accepter (ACCOMPAGNANT) — body optionnel : `{ scoreMatching }`
- `POST /transport/:id/cancel`
- `GET /transport/me` — Retourne `{ asDemandeur, asAccompagnant }`
- `GET /transport/available` — Demandes en attente (pour accompagnants)

---

### Évaluations transport

- `POST /transport-reviews/transport/:transportId` — Body : `{ note: 1-5, commentaire? }`
- `GET /transport-reviews/transport/:transportId`

---

### Carte / géocodage / itinéraires (`/map`)

- Voir `FLUTTER_MAP_OSM_PROMPT.md` — géocodage Nominatim, itinéraires OSRM (sans clé API côté app).

---

### Notifications

- `GET /notifications` — Query : `page`, `limit` — Retourne `{ data, total, unreadCount }`
- `POST /notifications/:id/read`
- `POST /notifications/read-all`

---

## 3. Header d’authentification

Toutes les routes protégées exigent :

```
Authorization: Bearer <access_token>
```

---

## 4. Tâches prioritaires pour l’app Flutter

1. Mettre à jour le modèle `User` (nom, prenom, telephone, photoProfil, role HANDICAPE/ACCOMPAGNANT).
2. Mettre à jour l’inscription avec les nouveaux champs.
3. Remplacer l’écran « accompagnants » par le flux **Relations** (`/relations`, voir `docs/FLUTTER_RELATIONS_PROMPT.md`).
4. Ajouter le flux Transport (créer demande, liste, accepter/annuler, évaluation).
5. Intégrer la carte / géocodage / itinéraires via `/map` (voir `FLUTTER_MAP_OSM_PROMPT.md`).
6. Ajouter le centre de notifications.
7. Changer `/user/me/image` en `/user/me/photo` pour l’upload de photo.

---

## 5. Codes HTTP

| Code | Signification |
|------|---------------|
| 200 / 201 | Succès |
| 400 | Données invalides |
| 401 | Non authentifié |
| 403 | Accès refusé (rôle insuffisant) |
| 404 | Ressource non trouvée |
| 409 | Conflit (ex. email déjà utilisé) |
