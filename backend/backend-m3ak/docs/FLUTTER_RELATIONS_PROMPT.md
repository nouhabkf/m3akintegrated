# Prompt — Frontoffice Flutter : module Relations handicapé–accompagnant

> **À donner au Cursor (ou au dev) responsable de l’app Flutter Ma3ak** pour intégrer la nouvelle API de liaison entre handicapés et accompagnants.

---

## Contexte backend (modification récente)

Le backend Ma3ak expose une **nouvelle ressource « Relations »** pour lier les utilisateurs **handicapés** et **accompagnants** en **many-to-many** :

- Un **handicapé** peut avoir **plusieurs accompagnants**.
- Un **accompagnant** peut avoir **plusieurs handicapés**.

Une liaison est créée en statut **EN_ATTENTE** ; l’autre partie doit **accepter** pour passer en **ACCEPTEE**. Chaque partie peut **supprimer** la liaison.

**Base URL API :** `http://localhost:3000` (ou l’URL de ton environnement).  
**Authentification :** toutes les routes nécessitent `Authorization: Bearer <access_token>` (JWT après login).

---

## Endpoints à intégrer

### 1. Créer une demande de liaison

- **Méthode :** `POST`
- **URL :** `/relations`
- **Headers :** `Authorization: Bearer <token>`, `Content-Type: application/json`
- **Body (JSON) :**
  - Si l’utilisateur connecté est **HANDICAPE** : envoyer `{ "accompagnantId": "<id_mongo_accompagnant>" }`.
  - Si l’utilisateur connecté est **ACCOMPAGNANT** : envoyer `{ "handicapId": "<id_mongo_handicape>" }`.
- **Réponse :** objet relation créé (voir structure ci-dessous). Code 201 en succès ; 400 si liaison déjà existante ou données invalides.

### 2. Accepter une demande de liaison

- **Méthode :** `POST`
- **URL :** `/relations/:id/accept`
- **Headers :** `Authorization: Bearer <token>`
- **Paramètre :** `id` = ID de la relation (MongoDB ObjectId).
- **Réponse :** objet relation mis à jour avec `statut: "ACCEPTEE"`.

### 3. Supprimer une liaison

- **Méthode :** `DELETE`
- **URL :** `/relations/:id`
- **Headers :** `Authorization: Bearer <token>`
- **Réponse :** `{ "message": "Relation supprimée" }`.

### 4. Mes relations (selon le rôle)

- **Méthode :** `GET`
- **URL :** `/relations/me`
- **Query (optionnel) :** `acceptedOnly=true` pour ne retourner que les liaisons acceptées.
- **Réponse :** liste d’objets relation (handicapé → ses accompagnants ; accompagnant → ses handicapés).

### 5. Mes accompagnants (handicapé uniquement)

- **Méthode :** `GET`
- **URL :** `/relations/me/accompagnants`
- **Query (optionnel) :** `acceptedOnly=false` pour inclure aussi les demandes en attente. Par défaut le backend renvoie uniquement les acceptées.
- **Réponse :** liste de relations avec `accompagnantId` populé (objet User sans `password`).

### 6. Mes handicapés (accompagnant uniquement)

- **Méthode :** `GET`
- **URL :** `/relations/me/handicapes`
- **Query (optionnel) :** `acceptedOnly=false` pour inclure les demandes en attente.
- **Réponse :** liste de relations avec `handicapId` populé (objet User sans `password`).

### 7. Détail d’une relation

- **Méthode :** `GET`
- **URL :** `/relations/:id`
- **Réponse :** un objet relation avec `handicapId` et `accompagnantId` populés (User sans `password`).

---

## Structure des données (réponse API)

**Objet Relation :**

```json
{
  "_id": "string (ObjectId)",
  "handicapId": { "objet User ou ObjectId" },
  "accompagnantId": { "objet User ou ObjectId" },
  "statut": "EN_ATTENTE" | "ACCEPTEE",
  "createdAt": "ISO 8601 date",
  "updatedAt": "ISO 8601 date"
}
```

Quand les refs sont populées, `handicapId` et `accompagnantId` sont des objets User (sans champ `password`) avec au moins : `_id`, `nom`, `prenom`, `email`, `telephone`, `role`, `photoProfil`, etc.

---

## Rôle attendu côté Flutter

1. **Modèles** : créer un modèle `Relation` (et éventuellement réutiliser `User`) pour parser les réponses JSON.
2. **Service / repository** : un service qui appelle la base URL + `/relations` avec le token JWT (déjà utilisé pour les autres appels) pour :
   - créer une liaison (POST avec `accompagnantId` ou `handicapId` selon le rôle),
   - accepter (POST `:id/accept`),
   - supprimer (DELETE `:id`),
   - récupérer mes relations, mes accompagnants ou mes handicapés (GET).
3. **Écrans / flux suggérés :**
   - **Handicapé :** écran « Mes accompagnants » (liste depuis `GET /relations/me/accompagnants`), bouton « Ajouter un accompagnant » (recherche utilisateur ou liste puis POST avec `accompagnantId`), et pour chaque relation en attente possibilité d’accepter ou supprimer si c’est l’handicapé qui a reçu une demande.
   - **Accompagnant :** écran « Mes handicapés » (liste depuis `GET /relations/me/handicapes`), bouton « Ajouter un handicapé » (POST avec `handicapId`), et gestion des demandes en attente (accepter / refuser = supprimer).
   - Afficher clairement le **statut** (EN_ATTENTE / ACCEPTEE) et les infos du User (nom, prénom, photo) depuis les objets populés.

4. **Gestion d’erreurs :** 400 (données invalides, liaison déjà existante), 401 (token expiré), 403 (rôle non autorisé), 404 (relation non trouvée). Adapter les messages utilisateur en conséquence.

---

## Rappel

- Les rôles côté backend sont : `HANDICAPE`, `ACCOMPAGNANT`, `ADMIN`.
- Les **relations** modélisent la liaison many-to-many « qui accompagne qui » dans l’app (demandes, acceptation).

Si tu as la doc Swagger du backend (`/api`), tu peux aussi t’y référer pour les schémas exacts et tester les appels depuis le navigateur.
