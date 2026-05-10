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
| `PATCH /user/me/accompagnants` | Supprimé — remplacer par **Emergency Contacts** |
| `GET /user/me/accompagnants` | `GET /emergency-contacts/me` |
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

### Dossier médical (HANDICAPE uniquement)

- `POST /medical-records` — Créer mon dossier (body : `groupeSanguin`, `allergies`, `maladiesChroniques`, `medicaments`, `medecinTraitant`, `contactUrgence`)
- `GET /medical-records/me`
- `PATCH /medical-records/me`

---

### Alertes SOS

- `POST /sos-alerts` — Body : `{ latitude, longitude }`
- `GET /sos-alerts/me` — Mes alertes
- `GET /sos-alerts/nearby?latitude=...&longitude=...` — Alertes à proximité

---

### Contacts urgence (remplace accompagnants)

- `POST /emergency-contacts` — Body : `{ accompagnantId, ordrePriorite }`
- `GET /emergency-contacts/me` — Liste avec `accompagnantId` peuplé
- `DELETE /emergency-contacts/:id`

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

### Lieux accessibles

- `GET /lieux` — Liste (query : `typeLieu`, `page`, `limit`)
- `GET /lieux/nearby?latitude=...&longitude=...&maxDistance=...` — Lieux à proximité
- `GET /lieux/:id` — Détail d’un lieu

Chaque lieu a : `nom`, `adresse`, `typeLieu`, `latitude`, `longitude`, `description`, `scoreAccessibilite`, `rampe`, `ascenseur`, `toilettesAdaptees`.

---

### Réservations lieux

- `POST /lieu-reservations` — Body : `{ lieuId, date (ISO), heure, besoinsSpecifiques? }`
- `GET /lieu-reservations/me`
- `POST /lieu-reservations/:id/statut` — Body : `{ statut }`

---

### Communauté (posts, commentaires, demandes d’aide)

- `GET /community/posts` — Liste paginée
- `GET /community/posts/:id`
- `POST /community/posts` — Body : `{ contenu, type }`
- `GET /community/posts/:postId/comments`
- `POST /community/posts/:postId/comments` — Body : `{ contenu }`
- `GET /community/help-requests`
- `POST /community/help-requests` — Body : `{ description, latitude, longitude }`
- `POST /community/help-requests/:id/statut` — Body : `{ statut }`

---

### Éducation (Braille, langue des signes)

- `GET /education/modules` — Query optionnel : `type` (BRAILLE | LANGUE_SIGNES)
- `GET /education/modules/:id`
- `GET /education/progress` — Mon progrès (JWT)
- `POST /education/progress` — Body : `{ moduleId, score, niveauActuel }`

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
3. Remplacer l’écran « accompagnants » par « contacts urgence » (emergency-contacts).
4. Ajouter l’écran Dossier médical pour les HANDICAPE.
5. Ajouter l’écran Alertes SOS (bouton + liste).
6. Ajouter le flux Transport (créer demande, liste, accepter/annuler, évaluation).
7. Ajouter la recherche de lieux accessibles (liste + carte).
8. Ajouter les réservations de lieux.
9. Ajouter la section Communauté (posts, commentaires, demandes d’aide).
10. Ajouter les modules éducatifs (Braille, langue des signes).
11. Ajouter le centre de notifications.
12. Changer `/user/me/image` en `/user/me/photo` pour l’upload de photo.

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
