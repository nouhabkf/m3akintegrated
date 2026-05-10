# Ma3ak API — Backend

> API **NestJS** pour l'application **Ma3ak** — personnes en situation de handicap en Tunisie et accompagnants. Le backend couvre la **santé et le social** (dossier médical, SOS, contacts d’urgence, communauté), la **mobilité** (transport, véhicules, carte), les **comptes** (auth, profil, admin), les **relations** handicapé ↔ accompagnant, et les **notifications**. Les routes sont documentées dans **Swagger** (`/api`).

---

## 📋 À propos de ce document

Ce README est conçu pour être partagé avec l'équipe. Il contient tout ce dont vous avez besoin pour comprendre, installer et contribuer au backend Ma3ak, y compris une **section 12** (inventaire fichier par fichier du dossier `src/`). Les commentaires explicatifs (💡 **Note**, ⚠️ **Important**, 📌 **À savoir**) facilitent la prise en main.

---
 
## Table des matières

1. [Démarrage rapide (nouveaux arrivants)](#1-démarrage-rapide-nouveaux-arrivants)
2. [Contexte et objectifs](#2-contexte-et-objectifs)
3. [Stack technique](#3-stack-technique)
4. [Architecture du projet](#4-architecture-du-projet)  
   - [4.1 Domaine santé & social (SanteModule)](#41-domaine-santé--social-santemodule)
   - [4.2 Domaine mobilité (MobiliteModule)](#42-domaine-mobilité-mobilitemodule)
   - [4.3 AppModule et modules transverses](#43-appmodule-et-modules-transverses)
   - [4.4 Accessibilité, Ollama et priorisation des demandes d’aide](#44-accessibilité-ollama-et-priorisation-des-demandes-daide)
5. [Logique métier](#5-logique-métier)
6. [Modèles de données](#6-modèles-de-données)
7. [API — Documentation complète](#7-api--documentation-complète)
8. [Configuration](#8-configuration)
9. [Sécurité](#9-sécurité)
10. [Installation et démarrage](#10-installation-et-démarrage)
11. [Projets associés et documentation](#11-projets-associés-et-documentation)
12. [Inventaire des fichiers source](#12-inventaire-des-fichiers-source)

---

## 1. Démarrage rapide (nouveaux arrivants)

> **💡 Pour les nouveaux membres de l'équipe** — Si vous découvrez le projet, suivez ces étapes pour être opérationnel rapidement.

1. **Cloner le dépôt** et ouvrir le dossier du projet
2. **Installer les dépendances** : `npm install`
3. **Configurer l'environnement** : copier `.env.example` vers `.env` et renseigner au minimum `MONGODB_URI` et `JWT_SECRET`
4. **Lancer MongoDB** (localement ou via Atlas)
5. **Démarrer l'API** : `npm run start:dev`
6. **Vérifier** : ouvrir http://localhost:3000 et http://localhost:3000/api (Swagger)

> **📌 Astuce** — La documentation Swagger (`/api`) permet de tester tous les endpoints directement depuis le navigateur.

---

## 2. Contexte et objectifs

**Ma3ak** est une application mobile intelligente qui vise à faciliter la **mobilité**, l'**autonomie** et l'**inclusion sociale** des personnes en situation de handicap en Tunisie.

### Utilisateurs cibles

- **Handicapés** — Personnes en situation de handicap (bénéficiaires des services)
- **Accompagnants** — Personnes qui accompagnent (transport, assistance)
- **Administrateurs** — Gestion de la plateforme via un backoffice web

### Fonctionnalités couvertes par ce backend

- **Comptes** : inscription, connexion (email / Google), profil, photo, position live, administration des utilisateurs.
- **Relations** : demandes et acceptation entre handicapés et accompagnants (`/relations`).
- **Santé & social** (`SanteModule`) : dossier médical (`/medical-records`), alertes SOS (`/sos-alerts`) — à l’envoi, **notification in-app + push FCM** vers les accompagnants enregistrés comme **contacts d’urgence** (`/emergency-contacts`) — communauté (`/community`).
- **Mobilité** : demandes de transport (matching, statuts type VTC, tarification TND), avis chauffeur, véhicules adaptés, réservations véhicule liées au transport ; **Socket.io** pour le suivi temps réel des courses (gateway transport).
- **Carte** : géocodage et itinéraires via OpenStreetMap (Nominatim / OSRM) en proxy (`/map`), et recherche de **POI** (Overpass) via `GET /map/places`.
- **Notifications** : notifications in-app et push FCM optionnel.
- **Accessibilité / IA locale** : indicateurs Ollama (`GET /accessibility/features`), score d’urgence et résumés de commentaires pour la communauté (repli heuristique si Ollama est coupé).

---

## 3. Stack technique

> **💡 Note** — Cette stack a été choisie pour sa robustesse, sa scalabilité et la richesse de l'écosystème NestJS/TypeScript.

| Technologie | Version / Rôle |
|-------------|----------------|
| **Framework** | NestJS 10.x |
| **Langage** | TypeScript (strict) |
| **Base de données** | MongoDB |
| **ODM** | Mongoose (`@nestjs/mongoose`) |
| **Authentification** | JWT (`@nestjs/jwt`, `passport-jwt`) + Google OAuth2 (`google-auth-library`) |
| **Validation** | class-validator + class-transformer |
| **Documentation API** | Swagger (`@nestjs/swagger`) |
| **Hash mot de passe** | bcryptjs |
| **Config** | @nestjs/config (global) |
| **HTTP sortant** | `@nestjs/axios` (Nominatim, OSRM, service Flask transport optionnel) |
| **Temps réel** | Socket.io (`@nestjs/websockets`) — suivi des statuts de transport |
| **Upload fichiers** | Multer (stockage disque, dossier `uploads/` à la racine du projet) |
| **IA locale (optionnel)** | Ollama en HTTP (`fetch`) — urgence des demandes d’aide, résumés commentaires ; désactivable via `OLLAMA_ENABLED` |

---

## 4. Architecture du projet

> **📌 Structure des dossiers** — Chaque module NestJS regroupe généralement : `*.module.ts`, `*.controller.ts`, `*.service.ts`, `dto/`, `schemas/`.

```
src/
├── main.ts                       # Point d'entrée : CORS, log HTTP, ValidationPipe, Swagger, uploads/
├── app.module.ts                 # Module racine — SanteModule + MobiliteModule + map, relations, notifications, etc.
├── app.controller.ts             # Route santé / (health check)
├── app.service.ts
│
├── database/
│   └── database.module.ts        # Connexion MongoDB (uri locale ou variables Atlas)
│
├── auth/                         # Authentification — login, Google OAuth, vérif config
├── user/                         # Utilisateurs — inscription, profil, photo
├── admin/                        # Administration — CRUD users (rôle ADMIN requis)
│
├── relation/                     # Liaisons handicapé ↔ accompagnant (demande / acceptation)
│
├── sante/                        # Agrégateur santé & social (une entrée dans AppModule)
│   └── sante.module.ts           # medical-record, sos-alert, emergency-contact, community
├── medical-record/               # Dossier médical (HANDICAPE)
├── sos-alert/                    # Alertes SOS (+ notifications vers contacts urgence)
├── emergency-contact/            # Contacts d’urgence (réf. accompagnants)
├── community/                    # Posts, commentaires, demandes d’aide
│
├── mobilite/                     # Agrégateur domaine transport + véhicules (importé une fois dans AppModule)
│   ├── mobilite.module.ts        # Transport, TransportReview, Vehicle, VehicleReservation
│   ├── mobilite-core.module.ts   # ChauffeurSolidaireGuard
│   ├── mobilite.constants.ts     # ex. CHAUFFEURS_SOLIDAIRES_TYPE
│   ├── guards/                   # Garde « Chauffeurs solidaires »
│   └── transport/
│       └── transport.gateway.ts  # WebSocket Socket.io — suivi statut course
├── transport/                    # Demandes de transport, matching, suivi, tarification
├── transport-review/             # Évaluations transport → met à jour noteMoyenne
├── vehicle/                      # Véhicules adaptés (accessibilité, statut validation)
├── vehicle-reservation/         # Réservations de véhicules + avis trajet
├── map/                          # Géocodage Nominatim + itinéraires OSRM + POI Overpass
├── notification/                 # Notifications utilisateur (+ push FCM optionnel)
├── accessibility/                # Feature flags Ollama + score urgence + résumés commentaires
├── help-priority/                # Priorité métier des demandes d’aide (service interne, pas de contrôleur)
└── common/                       # Utilitaires partagés (chemins uploads)
```

**Hors `src/`** — à la **racine du dépôt** : dossier `uploads/` (créé au démarrage par `main.ts`), servi en statique sous `/uploads/` (photos de profil).

### 4.1 Domaine santé & social (SanteModule)

> **💡 Principe** — Les modules issus du backend « santé » du collègue sont regroupés dans **`SanteModule`** pour une seule importation dans `AppModule`, sans mélanger avec la mobilité.

| Sous-module | Préfixe API | Rôle (résumé) |
|-------------|-------------|----------------|
| `MedicalRecordModule` | `/medical-records` | Création / lecture / mise à jour du dossier médical (utilisateur `HANDICAPE`). |
| `SosAlertModule` | `/sos-alerts` | Création d’alerte géolocalisée ; **notifie** chaque accompagnant listé dans **contacts d’urgence** (`NotificationService`, type `SOS_ALERT`). |
| `EmergencyContactModule` | `/emergency-contacts` | Liaison handicapé → accompagnants prioritaires pour l’urgence. |
| `CommunityModule` | `/community` | Communauté (publications, commentaires, demandes d’aide). |

### 4.2 Domaine mobilité (MobiliteModule)

> **💡 Principe** — Transport, avis transport, véhicules adaptés et réservations véhicules partagent le même objectif produit (mobilité). Le backend les regroupe pour une **entrée unique** dans `AppModule` et des **règles communes** (notamment « Chauffeurs solidaires »).

**Fichiers (`src/mobilite/`)**

| Fichier | Rôle |
|---------|------|
| `mobilite.module.ts` | Importe et ré-exporte `TransportModule`, `TransportReviewModule`, `VehicleModule`, `VehicleReservationModule`, plus `MobiliteCoreModule`. |
| `mobilite-core.module.ts` | Fournit le `ChauffeurSolidaireGuard` (et extensions futures partagées mobilité). |
| `mobilite.constants.ts` | Constante `CHAUFFEURS_SOLIDAIRES_TYPE` (`"Chauffeurs solidaires"`) — **même valeur** que `User.typeAccompagnant` côté base. |
| `guards/chauffeur-solidaire.guard.ts` | Vérifie JWT + rôle `ACCOMPAGNANT` + `typeAccompagnant === CHAUFFEURS_SOLIDAIRES_TYPE` ; sinon **403**. |

**`MobiliteModule`** regroupe ces quatre modules pour le domaine produit « mobilité » ; la liste exacte des imports dans `AppModule` peut en outre réexporter certains de ces modules directement — voir [§4.3](#43-appmodule-et-modules-transverses).

**Liaison technique véhicules ↔ réservations** — `VehicleModule` exporte `MongooseModule` (schéma `Vehicle`) en plus de `VehicleService`. `VehicleReservationModule` importe `VehicleModule` au lieu de redéclarer le schéma `Vehicle`, ce qui évite un double enregistrement Mongoose.

**Routes transport protégées par `ChauffeurSolidaireGuard`** (en plus de `JwtAuthGuard`) : `GET /transport/available`, `POST /transport/:id/accept`, `POST /transport/:id/statut`. Le **matching** `GET /transport/matching` reste ouvert à tout utilisateur authentifié (ex. bénéficiaire cherchant des accompagnants à proximité).

### 4.3 AppModule et modules transverses

Dans `app.module.ts`, outre les agrégateurs **`SanteModule`** et **`MobiliteModule`**, plusieurs modules sont aussi importés **directement** à la racine : par exemple `MedicalRecordModule`, `SosAlertModule`, `EmergencyContactModule`, `TransportModule`, `TransportReviewModule`, `CommunityModule`, `NotificationModule`, `MapModule`, `RelationModule`, `AccessibilityModule`, `HelpPriorityModule`. Les sous-modules santé et mobilité peuvent donc apparaître **à la fois** dans un agrégateur et dans la liste d’imports du module racine (configuration actuelle du dépôt). **Swagger** (`/api`) reste la référence pour l’inventaire exact des routes exposées.

### 4.4 Accessibilité, Ollama et priorisation des demandes d’aide

- **`AccessibilityModule`** expose `GET /accessibility/features` : indique si Ollama est censé être actif (`OLLAMA_ENABLED`, défaut **activé** si la variable est absente), URL de base, modèles texte / vision, et effectue un **ping HTTP** vers `GET {OLLAMA_BASE_URL}/api/tags` (5 s max) pour `ollamaReachable`.
- **`AccessibilityService`** alimente la communauté : **score d’urgence** 1–5 pour les demandes d’aide (LLM local via Ollama ou heuristique mots-clés) et **résumé flash** des commentaires (`GET /community/posts/:postId/comments/flash-summary`).
- **`HelpPriorityModule`** exporte uniquement `HelpPriorityService` (règles de score, texte de justification en français). Il est consommé par `CommunityService` lors de `POST /community/help-requests` ; **aucune route HTTP** dédiée.
- **`CommunityVisionService`** : extraction / enrichissement liés aux lieux et à la vision sur les posts (utilisé côté service communauté).

---

## 5. Logique métier

### Rôles

> **⚠️ Important** — Les rôles sont `HANDICAPE`, `ACCOMPAGNANT` et `ADMIN`. Les anciens noms (`BENEFICIARY`, `COMPANION`) ne sont plus utilisés.

| Rôle | Description |
|------|-------------|
| `HANDICAPE` | Personne en situation de handicap — demandes de transport et services associés |
| `ACCOMPAGNANT` | Accompagnant — disponible pour transport, noté via transport-reviews |
| `ADMIN` | Administrateur — accès au backoffice et CRUD utilisateurs |

### Règles principales

1. **Inscription** : Rôle par défaut `HANDICAPE` si non précisé. L'email doit être unique.
2. **Login Google** : Si l'utilisateur n'existe pas, il est créé avec rôle `HANDICAPE` et mot de passe factice hashé.
3. **Transport** : Le demandeur crée une demande ; l’acceptation, la liste des demandes ouvertes et la mise à jour des statuts de course sont réservées aux accompagnants enregistrés comme **« Chauffeurs solidaires »** (`typeAccompagnant` = valeur définie dans `src/mobilite/mobilite.constants.ts`, actuellement `Chauffeurs solidaires`). Le **matching** (`GET /transport/matching`) reste accessible à tout utilisateur authentifié JWT. Les évaluations mettent à jour `noteMoyenne`.
4. **Admin** : Les routes `/admin/*` sont protégées par JWT + rôle `ADMIN`.
5. **Relations** : Liaisons explicites handicapé ↔ accompagnant (demande `EN_ATTENTE`, acceptation).
6. **SOS** : À chaque `POST /sos-alerts`, l’API enregistre l’alerte puis envoie une notification (in-app + push si FCM configuré) à **chaque accompagnant** référencé dans les contacts d’urgence du demandeur.

### Flux d'authentification

1. Login classique : `POST /auth/login` → vérification email/password → JWT + user
2. Login Google : `POST /auth/google` avec `id_token` → vérification token → création ou récupération user → JWT + user
3. Routes protégées : header `Authorization: Bearer <token>` obligatoire

---

## 6. Modèles de données

> **💡 Note** — Les collections MongoDB suivent les conventions de nommage (camelCase pour les champs, noms de collections au pluriel ou conventions Mongoose).

### User (collection `users`)

| Champ | Type | Requis | Description |
|-------|------|--------|-------------|
| `nom` | string | oui | Nom de famille |
| `prenom` | string | oui | Prénom |
| `email` | string | oui | Email unique, lowercase |
| `password` | string | oui | Hash bcrypt, `select: false` (jamais retourné par l'API) |
| `telephone` | string | non | Téléphone |
| `role` | enum | oui | HANDICAPE, ACCOMPAGNANT, ADMIN |
| `typeHandicap` | string | non | Type de handicap (pour HANDICAPE) |
| `besoinSpecifique` | string | non | Besoins spécifiques |
| `animalAssistance` | boolean | non | Animal d'assistance (défaut: false) |
| `animalType` | string | non | Type d'animal (si `animalAssistance` : obligatoire via `PUT /users/animal`) |
| `animalName` | string | non | Nom de l'animal |
| `animalNotes` | string | non | Notes sur l'animal |
| `typeAccompagnant` | string | non | Type d'accompagnant (pour ACCOMPAGNANT) — ex. `Chauffeurs solidaires` pour les courses transport sensibles |
| `specialisation` | string | non | Spécialisation (pour ACCOMPAGNANT) |
| `disponible` | boolean | non | Disponible pour accompagnement (défaut: false) |
| `noteMoyenne` | number | non | Note moyenne des évaluations (défaut: 0) |
| `langue` | string | non | Langue préférée (ar, fr, etc.) |
| `photoProfil` | string | non | URL photo de profil |
| `statut` | string | non | ACTIF (défaut) |
| `latitude` | number | non | Dernière latitude (position live) |
| `longitude` | number | non | Dernière longitude (position live) |
| `lastLocationAt` | Date | non | Date/heure dernière mise à jour position |
| `createdAt` | Date | auto | Timestamps |
| `updatedAt` | Date | auto | Timestamps |

### TransportRequest (collection `transportRequests`)

| Champ | Description |
|-------|-------------|
| `demandeurId`, `accompagnantId`, `vehicleId` | Références User / Vehicle (optionnel jusqu’à acceptation) |
| `typeTransport` | `URGENCE` \| `QUOTIDIEN` |
| `motifTrajet` | Optionnel : `MEDICAL` \| `ADMINISTRATIF` \| `QUOTIDIEN` \| `LOISIR` |
| `prioriteMedicale` | Bool (défaut `false`) — tri `GET /transport/available` |
| `depart`, `destination` | Adresses texte |
| `latitudeDepart`, `longitudeDepart`, `latitudeArrivee`, `longitudeArrivee` | Coordonnées |
| `dateHeure` | Date/heure souhaitée |
| `besoinsAssistance` | Tableau de chaînes (ex. fauteuil, aide embarquement) |
| `statut` | Voir `TransportStatut` ci-dessous |
| `scoreMatching` | Score (optionnel, renseigné à l’acceptation) |
| `matchingSubscores` | Objet optionnel (proximité, note, handicap, besoins, urgence) persisté si fourni à l’acceptation |
| `shareTokenHash`, `shareTokenExpiresAt` | Partage trajet (hash SHA256 + TTL) — réinitialisés à fin / annulation |
| `dateHeureArrivee`, `dureeMinutes` | Fin de course (optionnel) |
| `distanceEstimeeKm`, `dureeEstimeeMinutes`, `prixEstimeTnd` | Estimation à la création (OSRM + tarif env, repli Haversine) |
| `prixFinalTnd` | Prix final à la clôture (`POST .../termine` ou via statut `TERMINEE`) |
| `raisonAnnulation`, `annuleParUserId` | Annulation |
| `vehicleReservationId` | Optionnel, unique (sparse) — liaison avec une réservation véhicule si la demande a été générée par `POST /vehicle-reservations` |

**TransportStatut :** `EN_ATTENTE` → `ACCEPTEE` → `EN_ROUTE` → `ARRIVEE` → `EN_COURS` → `TERMINEE` ; `ANNULEE` à tout moment autorisé (hors terminé/annulé) via cancel ou statut côté chauffeur.

### TransportReview (collection `transportReviews`)

Champs : `transportId`, `note` (1–5), `commentaire`, `createdAt`. Met à jour `noteMoyenne` de l'accompagnant.

### Vehicle (collection `vehicles`)

Champs : `ownerId` (ref User), `marque`, `modele`, `immatriculation`, `accessibilite` (sous-objet : `coffreVaste`, `rampeAcces`, `siegePivotant`, `climatisation`, `animalAccepte`), `photos` (array d'URLs), `statut` (EN_ATTENTE, VALIDE, REFUSE), `createdAt`, `updatedAt`.

### VehicleReservation (collection `vehicleReservations`)

Champs : `userId` (handicapé qui réserve, ref User), `vehicleId` (ref Vehicle), `date`, `heure`, `lieuDepart`, `lieuDestination`, `besoinsSpecifiques`, `qrCode`, `statut` (EN_ATTENTE, CONFIRMEE, ANNULEE, TERMINEE), `transportId` (ref transport généré automatiquement pour le chauffeur), `createdAt`, `updatedAt`.

### Notification (collection `notifications`)

Champs : `userId`, `titre`, `message`, `type`, `lu` (défaut: false), `createdAt`.

### Relation (collection des liaisons handicapé-accompagnant)

Champs typiques : références des deux parties, statut (`EN_ATTENTE`, acceptée, etc.) — voir schéma `relation.schema.ts`.

### Santé & social (collections associées)

Voir les schémas dans `src/medical-record/`, `src/sos-alert/`, `src/emergency-contact/`, `src/community/` — champs détaillés dans Swagger (`/api`).

---

## 7. API — Documentation complète

**Base URL :** `http://localhost:3000` (ou variable d'environnement `PORT`)

**Swagger :** http://localhost:3000/api — documentation interactive et schémas (source de vérité à jour)

**Header auth :** `Authorization: Bearer <access_token>` (obligatoire pour toutes les routes protégées, sauf login et register)

### Préfixes REST actuels

| Préfixe | Rôle |
|---------|------|
| `/auth` | Login, Google, test config JWT/Google |
| `/user` | Inscription, profil, localisation, photo |
| `/admin` | CRUD utilisateurs (rôle ADMIN) |
| `/relations` | Liaisons handicapé ↔ accompagnant |
| `/medical-records` | Dossier médical |
| `/sos-alerts` | Alertes SOS |
| `/emergency-contacts` | Contacts d’urgence |
| `/community` | Communauté |
| `/transport` | Demandes de transport et flux chauffeur |
| `/transport-reviews` | Avis après course |
| `/vehicles` | Véhicules adaptés |
| `/vehicle-reservations` | Réservations véhicule + avis |
| `/notifications` | Notifications utilisateur |
| `/map` | Géocodage, itinéraires et lieux POI (sans auth) |
| `/accessibility` | Indicateurs d’accessibilité côté IA locale (Ollama) |

**WebSocket (Socket.io)** — namespace **`/transport`** (`TransportGateway`). Handshake : header `Authorization: Bearer <JWT>` **ou** `auth: { token: "<JWT>" }` (équivalent REST). **Invité** : `join_ride` avec `{ rideId, shareToken }` (jeton opaque `POST /transport/:id/share`) sans JWT.

| Message client (emit) | Corps | Effet |
|------------------------|--------|--------|
| `join_ride` | `{ rideId }` + JWT **ou** `{ rideId, shareToken }` | Rejoindre la room `ride_<id>` (demandeur, chauffeur assigné, ou invité partage valide) pour `location_update` / `ride_status_update` |
| `driver_location` | `{ rideId, lat, lng }` | **Chauffeur** de la course uniquement (JWT) ; si le statut est actif (`ACCEPTEE` … `EN_COURS`), enregistre la position et **broadcast** `location_update` à la room |

| Événement serveur (écouter) | Charge utile (résumé) |
|-----------------------------|------------------------|
| `location_update` | `{ lat, lng, timestamp }` |
| `ride_status_update` | `{ rideId, statut, timestamp }` (émis aussi depuis le flux métier transport) |
| `error` | `{ message }` (token manquant/invalide, non autorisé, statut incompatible) |

Fichier : `src/mobilite/transport/transport.gateway.ts`.

---

### Auth (`/auth`)

| Méthode | Endpoint | Auth | Body | Réponse |
|---------|----------|------|------|---------|
| POST | `/auth/login` | Non | `{ email, password }` | `{ access_token, user }` |
| POST | `/auth/google` | Non | `{ id_token }` | `{ access_token, user }` |
| GET | `/auth/config-test` | Non | — | `{ jwtSecretConfigured, googleClientIdConfigured }` |

---

### User (`/users`)

| Méthode | Endpoint | Auth | Description |
|---------|----------|------|-------------|
| POST | `/users/register` | Non | Inscription — CreateUserDto |
| GET | `/users/me` | JWT | Profil de l'utilisateur connecté |
| PATCH | `/users/me` | JWT | Mise à jour du profil (UpdateUserDto) |
| PUT | `/users/animal` | JWT | Animal d'assistance (UpdateAnimalDto) |
| PATCH | `/users/me/location` | JWT | Mise à jour position live (lat, lon) |
| DELETE | `/users/me` | JWT | Suppression du compte |
| PATCH | `/users/me/photo` | JWT | Upload photo de profil (multipart, champ `image`, max 5 Mo) |

---

### Admin (`/admin`) — Rôle ADMIN requis

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/admin/users` | Liste paginée — query: `page`, `limit`, `role`, `search` |
| GET | `/admin/users/:id` | Détail d'un utilisateur |
| POST | `/admin/users` | Créer un utilisateur (CreateUserDto) |
| PATCH | `/admin/users/:id` | Modifier un utilisateur (UpdateUserDto) |
| DELETE | `/admin/users/:id` | Supprimer un utilisateur |

---

### Relations handicapé-accompagnant (`/relations`)

> Toutes les routes exigent un JWT. Handicapé et accompagnant peuvent initier une demande ; l’autre partie accepte.

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| POST | `/relations` | Créer une demande — handicapé : body avec `accompagnantId` ; accompagnant : body avec `handicapId` ; statut `EN_ATTENTE` jusqu’à acceptation |
| POST | `/relations/:id/accept` | Accepter la demande (l’autre partie) |
| DELETE | `/relations/:id` | Supprimer la liaison (handicapé ou accompagnant concerné) |
| GET | `/relations/me` | Mes relations — query optionnel `acceptedOnly=true` |
| GET | `/relations/me/accompagnants` | Handicapé : mes accompagnants liés — query `acceptedOnly` (défaut : acceptés seulement) |
| GET | `/relations/me/handicapes` | Accompagnant : mes handicapés liés — query `acceptedOnly` |
| GET | `/relations/:id` | Détail d’une relation (accès si partie prenante) |

Documentation mobile : `docs/FLUTTER_RELATIONS_PROMPT.md`.

---

### Transport (`/transport`)

Flux type course VTC : création → matching chauffeurs → acceptation atomique → statuts chauffeur (`EN_ROUTE` …) → fin / annulation / prix.

> **Réservation véhicule et transport** — Une réservation réussie via `POST /vehicle-reservations` (statut initial `EN_ATTENTE`) crée automatiquement une demande `transport` liée (`vehicleReservationId` / `transportId`), `typeTransport` = `QUOTIDIEN`, `vehicleId` = véhicule réservé. Le propriétaire du véhicule la voit dans `GET /transport/available` avec les demandes ouvertes (`vehicleId` null). Les statuts réservation / transport se synchronisent sur acceptation, annulation et fin de course.

| Méthode | Endpoint | Auth | Description |
|---------|----------|------|-------------|
| POST | `/transport` | JWT | Crée `EN_ATTENTE`, estimation trajet. Champs **optionnels** : `motifTrajet` (`MEDICAL` \| `ADMINISTRATIF` \| `QUOTIDIEN` \| `LOISIR`), `prioriteMedicale` (bool, tri file chauffeur) |
| GET | `/transport/matching` | JWT | Query : `latitude`, `longitude`, `typeHandicap`, `urgence`, `rayonKm`, `besoinsAssistance` (répété ou CSV). Réponse **NestJS** enrichie : `source: 'nestjs'`, `subscores`, `vehicles`, `recommendedVehicle`, `score` (= `scoreMatching`). Si **Flask** répond (`FLASK_TRANSPORT_URL`), le corps reste **celui du service Flask** (inchangé) ; le POST `/api/match` envoie en plus `besoinsAssistance`, `typeTransport`, `motifTrajet`, `prioriteMedicale` (ignorables côté Flask) |
| POST | `/transport/matching` | JWT | Même logique que GET ; corps `TransportMatchingBodyDto` (évite URL longue pour `besoinsAssistance`) |
| GET | `/transport/history` | JWT | Historique **fusionné** transport + réservations véhicule (fenêtre récente, voir `note` dans la réponse) |
| GET | `/transport/:id/matching-candidates` | JWT | Matching basé sur la demande `id` (coords + `besoinsAssistance` du document). Demandeur ; chauffeur solidaire si course `EN_ATTENTE` |
| GET | `/transport/:id/suivi/public` | **Token** | Query `token` ou header `X-Transport-Share-Token` (pas de JWT). Réponse sans PII passager ; rate limit mémoire |
| GET | `/transport/:id/eta/public` | **Token** | Idem |
| POST | `/transport/:id/share` | JWT | Demandeur ou chauffeur assigné ; course `ACCEPTEE`…`EN_COURS`. Retour `{ token, expiresAt }` (TTL fin estimée + marge) |
| DELETE | `/transport/:id/share` | JWT | Révoque le jeton |
| POST | `/transport/:id/accept` | JWT **+ Chauffeurs solidaires** | Body optionnel `scoreMatching`, `vehicleId`, `matchingSubscores` (sous-scores persistés) |
| POST | `/transport/:id/statut` | JWT **+ Chauffeurs solidaires** | **Uniquement l’accompagnant assigné** à la course (contrôle métier). Body `{ "statut": "<TransportStatut>" }`. Transitions validées ; `ANNULEE` → annulation ; `TERMINEE` → clôture comme `termine`. Notification demandeur |
| POST | `/transport/:id/cancel` | JWT | Demandeur ou accompagnant assigné. Body optionnel `{ "raison" }`. Interdit si `TERMINEE` / `ANNULEE` |
| POST | `/transport/:id/termine` | JWT | Demandeur ou accompagnant ; statuts `ACCEPTEE` \| `EN_ROUTE` \| `ARRIVEE` \| `EN_COURS`. Calcule `prixFinalTnd` (env `TRANSPORT_FARE_*_TND`) |
| GET | `/transport/me` | JWT | `{ asDemandeur, asAccompagnant }` |
| GET | `/transport/available` | JWT **+ Chauffeurs solidaires** | Demandes `EN_ATTENTE` ouvertes ou liées à un de vos véhicules. **Tri** : `prioriteMedicale` **>** `typeTransport=URGENCE` **>** autres, puis `dateHeure` |
| GET | `/transport/:id` | JWT | Détail peuplé |
| GET | `/transport/:id/eta` | JWT | Si course active : ETA chauffeur → point départ passager (Flask `/api/eta` si configuré, sinon Haversine + 30 km/h) |
| GET | `/transport/:id/suivi` | JWT | Si course active : transport, `positionChauffeur`, `eta`, `itineraire` OSRM, `cible` `POINT_DEPART` ou `DESTINATION` (si `EN_COURS`) |
| GET | `/transport/:id/price-estimate` | JWT | Retourne ou recalcule distance / durée / prix estimé TND |

**Notifications (types)** : `TRANSPORT_ACCEPTED`, `TRANSPORT_ASSIGNED`, `TRANSPORT_STATUS`, `TRANSPORT_CANCELLED`, `TRANSPORT_COMPLETED`. Une erreur sur la création de notification **n’interrompt pas** le flux métier.

**Compatibilité clients :** `POST .../cancel` accepte un corps vide ou `{ "raison" }`. Les statuts transport incluent toute la chaîne type VTC ci-dessus. **Review en double** sur le même transport : **409 Conflict** (`ConflictException`).

---

### Transport Reviews (`/transport-reviews`)

| Méthode | Endpoint | Auth | Description |
|---------|----------|------|-------------|
| POST | `/transport-reviews/transport/:transportId` | JWT | **Seul le demandeur** ; transport **TERMINEE** ; **une seule** review par transport → met à jour `noteMoyenne` de l’accompagnant |
| GET | `/transport-reviews/transport/:transportId` | JWT | Liste des avis pour ce transport |

---

### Véhicules (`/vehicles`)

| Méthode | Endpoint | Auth | Description |
|---------|----------|------|-------------|
| POST | `/vehicles` | JWT | Créer un véhicule — `ownerId` dans le body **ignoré** si non-ADMIN (propriétaire = JWT) ; **ADMIN** doit fournir `ownerId` |
| GET | `/vehicles` | Non | Liste paginée (query: `ownerId`, `statut`, `page`, `limit`) — optionnel **géofiltre** : `latitude` + `longitude` + `maxDistanceKm` (défaut 10 km si coords fournies) pour limiter aux véhicules dont le propriétaire est dans le rayon |
| GET | `/vehicles/owner/:ownerId` | Non | Véhicules d'un propriétaire |
| GET | `/vehicles/:id` | Non | Détail d'un véhicule |
| PATCH | `/vehicles/:id` | JWT | Modifier un véhicule : **propriétaire** ou **admin** ; accompagnant **Chauffeurs solidaires** (non propriétaire) : **uniquement** le champ `statut` |
| DELETE | `/vehicles/:id` | JWT | **Propriétaire** ou **admin** uniquement |

---

### Réservations Véhicules (`/vehicle-reservations`)

| Méthode | Endpoint | Auth | Description |
|---------|----------|------|-------------|
| POST | `/vehicle-reservations` | JWT | `userId` = connecté ; véhicule `VALIDE` ; conflit date/heure + `EN_ATTENTE`\|`CONFIRMEE` → **400** ; génère `qrCode` ; **crée un transport lié** (`transportId` sur la réservation) pour le flux chauffeur |
| GET | `/vehicle-reservations/me` | JWT | Mes réservations (véhicule + owner chauffeur peuplés) |
| GET | `/vehicle-reservations/me/history` | JWT | Query optionnel `statut=` |
| GET | `/vehicle-reservations/vehicle/:vehicleId` | JWT | Réservations du véhicule |
| GET | `/vehicle-reservations/:id` | JWT | Détail |
| GET \| POST | `/vehicle-reservations/:id/review` | JWT | **Seul le demandeur** ; réservation **TERMINEE** ; POST = upsert review |
| POST | `/vehicle-reservations/:id/statut` | JWT | Body JSON `{ "statut": "EN_ATTENTE" \| "CONFIRMEE" \| "ANNULEE" \| "TERMINEE" }` — **CONFIRMEE** / **TERMINEE** : propriétaire du véhicule ou **admin** ; **ANNULEE** : demandeur (réservation), propriétaire du véhicule ou **admin** |
| DELETE | `/vehicle-reservations/:id` | JWT | Même habilitation qu’une **ANNULEE** ; **ne supprime pas** le document : met `statut = ANNULEE` |

---

### Notifications (`/notifications`)

| Méthode | Endpoint | Auth | Description |
|---------|----------|------|-------------|
| GET | `/notifications` | JWT | Mes notifications — pagination query `page`, `limit` (défauts côté service) |
| POST | `/notifications/:id/read` | JWT | Marquer comme lue |
| POST | `/notifications/read-all` | JWT | Tout marquer comme lu |

---

### Dossier médical (`/medical-records`)

| Méthode | Endpoint | Auth | Description |
|---------|----------|------|-------------|
| POST | `/medical-records` | JWT | Création — réservé au profil **HANDICAPE** (règle métier dans le service) |
| GET | `/medical-records/me` | JWT | Lecture de son dossier |
| PATCH | `/medical-records/me` | JWT | Mise à jour |

---

### Contacts d’urgence (`/emergency-contacts`)

| Méthode | Endpoint | Auth | Description |
|---------|----------|------|-------------|
| POST | `/emergency-contacts` | JWT | Ajouter un accompagnant comme contact prioritaire SOS |
| GET | `/emergency-contacts/me` | JWT | Liste de mes contacts |
| DELETE | `/emergency-contacts/:id` | JWT | Retirer un contact |

---

### Alertes SOS (`/sos-alerts`)

| Méthode | Endpoint | Auth | Description |
|---------|----------|------|-------------|
| POST | `/sos-alerts` | JWT | Créer une alerte ; **notifications** in-app (+ push FCM si clé configurée) vers les **contacts d’urgence** |
| GET | `/sos-alerts/me` | JWT | Historique / liste de mes alertes |
| GET | `/sos-alerts/nearby` | JWT | Alertes à proximité — query **`latitude`**, **`longitude`** (obligatoires, nombres) |
| POST | `/sos-alerts/:id/statut` | JWT | Mise à jour du statut — body `{ "statut": "..." }` |

---

### Communauté (`/community`)

**Posts** — images stockées sous `uploads/` avec préfixe public `/uploads/…` (jusqu’à **10** fichiers, 5 Mo chacun, types image courants).

| Méthode | Endpoint | Auth | Description |
|---------|----------|------|-------------|
| POST | `/community/posts` | JWT | Création `multipart/form-data` : champs `contenu`, `type` + optionnel `latitude`, `longitude`, `dangerLevel` (`none` \| `low` \| `medium` \| `critical`), `images[]` ; autres champs inclusifs (voir `CreatePostDto` / Swagger) |
| GET | `/community/posts` | Non | Liste paginée — query `page`, `limit`, `type` |
| GET | `/community/posts/for-me` | JWT | Filtrage « smart » selon le profil (ex. `typeHandicap`) |
| GET | `/community/posts/:id` | Non | Détail d’un post |
| DELETE | `/community/posts/:postId` | JWT **ADMIN** | Modération (suppression) |
| POST | `/community/posts/:postId/validate-obstacle` | JWT | Vote validation obstacle — body `{ "confirm": boolean }` |
| POST | `/community/posts/:postId/merci` | JWT | Toggle remerciement (alternative positive au « like ») |
| GET | `/community/posts/:postId/merci-state` | JWT | État « merci » pour l’utilisateur connecté |
| POST | `/community/posts/:postId/comments` | JWT | Commentaire — body `{ "contenu": string }` |
| GET | `/community/posts/:postId/comments` | Non | Liste des commentaires |
| GET | `/community/posts/:postId/comments/flash-summary` | Non | Résumé accessible (Ollama ou heuristique) |

**Demandes d’aide** — à la création : `HelpRequestMessageBuilderService` (texte final) → `AccessibilityService.getUrgencyScore` → `HelpPriorityService` (priorité `low` \| `medium` \| `high` \| `critical`, score, raison FR, signaux). Liste triée par priorité puis score puis date.

| Méthode | Endpoint | Auth | Description |
|---------|----------|------|-------------|
| POST | `/community/help-requests` | JWT | Création — voir `CreateHelpRequestDto` (champs inclusifs optionnels ; minimum historique : `description`, `latitude`, `longitude`) |
| GET | `/community/help-requests` | Non | Liste paginée — `page`, `limit` |
| POST | `/community/help-requests/:id/statut` | JWT | Mise à jour du statut |
| PATCH | `/community/help-requests/:id/accept` | JWT | Accepter en tant qu’aidant ; enregistre le nom affiché du helper |

Documentation interne du builder de message : `src/community/HELP_REQUEST_MESSAGE_BUILDER.md`.

---

### Accessibilité / IA locale (`/accessibility`)

| Méthode | Endpoint | Auth | Description |
|---------|----------|------|-------------|
| GET | `/accessibility/features` | Non | Flags Ollama + ping du serveur Ollama (`/api/tags`) |

---

### Map — OpenStreetMap (`/map`)

| Méthode | Endpoint | Auth | Description |
|---------|----------|------|-------------|
| POST | `/map/geocode` | Non | Géocodage : adresse → coordonnées (Nominatim) |
| GET | `/map/geocode` | Non | Géocodage (GET, query: `q`, `countrycodes`, `limit`) |
| POST | `/map/reverse-geocode` | Non | Géocodage inverse : coordonnées → adresse |
| GET | `/map/reverse-geocode` | Non | Géocodage inverse (GET, query: `lat`, `lon`) |
| POST | `/map/route` | Non | Calcul d'itinéraire (OSRM) : origine, destination, waypoints optionnels |
| GET | `/map/places` | Non | **POI** (Overpass) : Grand Tunis par défaut ou bbox — query typées via `PlacesQueryDto` (catégories, limites, respect des plages max. définies dans `map-places.constants.ts`) |

Variable **`OVERPASS_URL`** (optionnelle) : surcharge de l’instance Overpass (défaut `https://overpass-api.de/api/interpreter` dans `MapService`).

---

### Fichiers statiques

- **Photos de profil :** `GET /uploads/{filename}`

---

### Codes HTTP

| Code | Signification |
|------|---------------|
| 200 / 201 | Succès |
| 400 | Données invalides (validation) |
| 401 | Non authentifié (token manquant ou invalide) |
| 403 | Accès refusé (rôle insuffisant) |
| 404 | Ressource non trouvée |
| 409 | Conflit (ex. email déjà utilisé) |

---

## 8. Configuration

### Variables d'environnement

> **📌 À savoir** — Copier `.env.example` vers `.env` avant de démarrer. Ne jamais commiter le fichier `.env`.

| Variable | Obligatoire | Description |
|----------|-------------|-------------|
| `PORT` | Non | Port serveur (défaut: 3000) |
| `MONGODB_URI` | Oui* | URI MongoDB (ex. `mongodb://localhost:27017/ma3ak`) |
| `DB_USERNAME` | Oui* | Pour Atlas — avec DB_PASSWORD, DB_CLUSTER, DB_NAME |
| `DB_PASSWORD` | Oui* | |
| `DB_CLUSTER` | Oui* | |
| `DB_NAME` | Non | Défaut: ma3ak |
| `JWT_SECRET` | Oui | Secret pour signer les JWT — utiliser une valeur longue et aléatoire |
| `JWT_EXPIRES_IN` | Non | Durée du token (défaut: 7d) |
| `GOOGLE_CLIENT_ID` | Non | Pour login Google OAuth2 |
| `CORS_ORIGINS` | Non | Origines autorisées, séparées par des virgules |
| `NOMINATIM_URL` | Non | URL Nominatim (défaut: OpenStreetMap public) |
| `OSRM_URL` | Non | URL OSRM pour calcul d'itinéraires (défaut: public) |
| `FLASK_TRANSPORT_URL` | Non | Service Flask optionnel : matching (`POST …/api/match`) et ETA (`GET …/api/eta`) |
| `TRANSPORT_MATCHING_RADIUS_KM` | Non | Rayon matching (défaut: **15**) |
| `TRANSPORT_FARE_BASE_TND` | Non | Tarif de base TND (défaut: **2.5**) |
| `TRANSPORT_FARE_PER_KM_TND` | Non | TND par km (défaut: **0.8**) |
| `TRANSPORT_FARE_PER_MINUTE_TND` | Non | TND par minute (défaut: **0.15**) |
| `FCM_SERVER_KEY` | Non | Clé serveur **Firebase Cloud Messaging** — si absente, les pushes mobiles sont ignorés (les notifications en base restent créées) |
| `OVERPASS_URL` | Non | URL de l’API Overpass pour `GET /map/places` (défaut instance publique) |
| `OLLAMA_ENABLED` | Non | `false` / `0` / `off` pour désactiver explicitement ; **si absent**, Ollama est considéré **activé** puis repli heuristique si injoignable |
| `OLLAMA_BASE_URL` | Non | URL du serveur Ollama (défaut `http://127.0.0.1:11434`) |
| `OLLAMA_MODEL` | Non | Modèle texte pour urgence + résumés (défaut `llama3.2`) |
| `OLLAMA_VISION_MODEL` | Non | Modèle vision annoncé aux clients (défaut `llava`) — usage côté extraction post selon évolutions |
| `OLLAMA_TIMEOUT_MS` | Non | Timeout des appels `generate` (défaut **120000** ms) |

\* Soit `MONGODB_URI` (MongoDB local), soit les variables Atlas.

### Fichiers statiques

- Dossier `uploads/` créé automatiquement au démarrage
- Servi sous le préfixe `/uploads/`

---

## 9. Sécurité

> **⚠️ Important** — Ces mesures sont essentielles en production. Ne jamais exposer les secrets ni désactiver la validation.

- **Mots de passe** : Hash bcrypt (10 rounds) — jamais stockés en clair
- **JWT** : Payload `{ sub: userId, email }`, extraction Bearer token
- **Validation** : ValidationPipe global — `whitelist: true` (ignore les champs non déclarés), `forbidNonWhitelisted: true` (rejette les champs inconnus)
- **Rôles** : Routes admin protégées par `JwtAuthGuard` + `RolesGuard` + `@Roles(Role.ADMIN)`
- **Chauffeurs solidaires** : Certaines routes transport et la mise à jour de statut véhicule sont limitées aux accompagnants dont `typeAccompagnant` correspond à la constante `CHAUFFEURS_SOLIDAIRES_TYPE` (`src/mobilite/mobilite.constants.ts`)
- **Upload** : Limite 5 Mo, types autorisés : jpeg, jpg, png, gif, webp

---

## 10. Installation et démarrage

### Prérequis

- Node.js 18+
- MongoDB (local ou Atlas)

### Commandes

```bash
# Installation des dépendances
npm install

# Développement (watch mode — rechargement automatique)
npm run start:dev

# Build pour production
npm run build

# Démarrer en production
npm run start:prod

# Formatage du code (Prettier)
npm run format

# Tests unitaires (ex. tarification transport)
npm run test

# Tests e2e — nécessitent MongoDB joignable (même config que .env)
npm run test:e2e

# Données de démo (script Node à la racine du projet)
npm run seed
```

### Accès

- **API :** http://localhost:3000
- **Swagger :** http://localhost:3000/api
- **Health check :** http://localhost:3000

### Créer un compte admin

1. Inscription : `POST /users/register` avec `"role": "ADMIN"`
2. Ou modifier un utilisateur existant en base : `role: "ADMIN"`

---

## 11. Projets associés et documentation

> **💡 Pour l'équipe** — Prompts et notes à la racine du dépôt ou dans `docs/` pour les clients (Flutter, modules métier).

### Prompts à la racine

| Projet | Fichier | Description |
|--------|---------|-------------|
| **App mobile Flutter** | `FLUTTER_APP_PROMPT.md` | Application Ma3ak pour handicapés et accompagnants |
| **App Flutter — CRUD Véhicules** | `FLUTTER_VEHICLE_CRUD_PROMPT.md` | Module CRUD véhicules |
| **App Flutter — Réservation véhicules** | `FLUTTER_VEHICLE_RESERVATION_PROMPT.md` | Réservation de véhicules par les handicapés |
| **App Flutter — Mise à jour statut véhicules** | `FLUTTER_VEHICLE_STATUS_UPDATE_PROMPT.md` | Chauffeurs solidaires et admin (statut véhicules) |
| **App Flutter — Carte OSM** | `FLUTTER_MAP_OSM_PROMPT.md` | Intégration carte / géocodage / itinéraires |
| **Backoffice web** | `BACKOFFICE_WEB_PROMPT.md` | Évolutions API et backoffice |

### Dossier `docs/`

| Sujet | Fichier |
|--------|---------|
| **Domaine mobilité (principe + technique, prompt équipe)** | Section [4.2 Domaine mobilité (MobiliteModule)](#42-domaine-mobilité-mobilitemodule) de ce README |
| **Relations handicapé-accompagnant (Flutter)** | `docs/FLUTTER_RELATIONS_PROMPT.md` |
| **Transport (état d’avancement + prompt Flutter)** | `docs/MODULE_TRANSPORT_ETAT_AVANCEMENT.md`, `docs/PROMPT_FLUTTER_MODULE_TRANSPORT.md` |
| **Builder de message (demandes d’aide inclusives)** | `src/community/HELP_REQUEST_MESSAGE_BUILDER.md` |
| **Script de seed MongoDB** | `scripts/README.md`, `scripts/seed.js` |

---

## 12. Inventaire des fichiers source

> Liste exhaustive des fichiers **TypeScript applicatifs** sous `src/` au moment de la révision (137 fichiers). Les dossiers `dist/`, `node_modules/` et les fichiers de config racine (`nest-cli.json`, `tsconfig*.json`, `jest`…) complètent le dépôt mais ne sont pas redétailés ligne par ligne ici.

### Racine et transversal

| Fichier | Rôle |
|---------|------|
| `src/main.ts` | Bootstrap Nest : dossier `uploads/`, CORS, log HTTP, `ValidationPipe`, assets statiques, Swagger `/api`, port |
| `src/app.module.ts` | Module racine — agrégation de tous les domaines |
| `src/app.controller.ts` | Health check `GET /` |
| `src/app.service.ts` | Service minimal associé au contrôleur racine |
| `src/app.controller.spec.ts` | Test unitaire du contrôleur racine |
| `src/common/upload-paths.ts` | Chemins disque et préfixe URL public pour uploads (profil, posts) |

### Base de données

| Fichier | Rôle |
|---------|------|
| `src/database/database.module.ts` | `MongooseModule.forRootAsync` — `MONGODB_URI` ou construction `mongodb+srv` depuis `DB_*` |

### Accessibilité et priorisation

| Fichier | Rôle |
|---------|------|
| `src/accessibility/accessibility.module.ts` | Module |
| `src/accessibility/accessibility.controller.ts` | `GET /accessibility/features` |
| `src/accessibility/accessibility.service.ts` | Flags Ollama, ping, score urgence, résumé flash commentaires |
| `src/help-priority/help-priority.module.ts` | Export du service de priorité |
| `src/help-priority/help-priority.service.ts` | Calcul priorité / score / raison FR |
| `src/help-priority/help-priority.service.spec.ts` | Tests unitaires |
| `src/help-priority/help-priority.constants.ts` | Constantes de scoring |
| `src/help-priority/help-priority.scoring-rules.ts` | Règles numériques |
| `src/help-priority/help-priority.french-reason.ts` | Formulation des raisons |
| `src/help-priority/help-priority.text.ts` | Chaînes / gabarits texte |
| `src/help-priority/help-priority.types.ts` | Types TypeScript |

### Authentification et administration

| Fichier | Rôle |
|---------|------|
| `src/auth/auth.module.ts` | JWT, Passport, exposition `JwtModule` |
| `src/auth/auth.controller.ts` | Login, Google, `config-test` |
| `src/auth/auth.service.ts` | Logique login / Google |
| `src/auth/jwt.strategy.ts` | Stratégie `passport-jwt` |
| `src/auth/guards/jwt-auth.guard.ts` | Garde JWT |
| `src/auth/guards/roles.guard.ts` | Garde par rôle |
| `src/auth/decorators/current-user.decorator.ts` | Utilisateur courant |
| `src/auth/decorators/roles.decorator.ts` | Métadonnées `@Roles` |
| `src/auth/dto/login.dto.ts` | DTO login |
| `src/auth/dto/google-login.dto.ts` | DTO Google |
| `src/admin/admin.module.ts` | Module admin |
| `src/admin/admin.controller.ts` | CRUD utilisateurs `/admin/users` |
| `src/admin/admin.service.ts` | Logique admin |

### Utilisateur

| Fichier | Rôle |
|---------|------|
| `src/user/user.module.ts` | Module utilisateur |
| `src/user/user.controller.ts` | Register, profil, animal d'assistance, localisation, photo |
| `src/user/user.service.ts` | CRUD / règles utilisateur |
| `src/user/schemas/user.schema.ts` | Schéma Mongoose `User` |
| `src/user/enums/role.enum.ts` | `HANDICAPE`, `ACCOMPAGNANT`, `ADMIN` |
| `src/user/dto/create-user.dto.ts` | Inscription |
| `src/user/dto/update-user.dto.ts` | Mise à jour profil |
| `src/user/dto/update-animal.dto.ts` | Animal d'assistance |
| `src/user/dto/update-location.dto.ts` | Position live |

### Relations

| Fichier | Rôle |
|---------|------|
| `src/relation/relation.module.ts` | Module |
| `src/relation/relation.controller.ts` | Routes `/relations` |
| `src/relation/relation.service.ts` | Demandes, acceptation, listes |
| `src/relation/schemas/relation.schema.ts` | Schéma |
| `src/relation/dto/create-relation.dto.ts` | Création demande |
| `src/relation/enums/relation-statut.enum.ts` | Statuts relation |

### Santé et social (fichiers unitaires + agrégateur)

| Fichier | Rôle |
|---------|------|
| `src/sante/sante.module.ts` | Agrégateur : medical, sos, emergency, community |
| `src/medical-record/medical-record.module.ts` | Module dossier médical |
| `src/medical-record/medical-record.controller.ts` | `/medical-records` |
| `src/medical-record/medical-record.service.ts` | Règles HANDICAPE |
| `src/medical-record/schemas/medical-record.schema.ts` | Schéma |
| `src/medical-record/dto/create-medical-record.dto.ts` | Création |
| `src/medical-record/dto/update-medical-record.dto.ts` | Mise à jour |
| `src/sos-alert/sos-alert.module.ts` | Module SOS |
| `src/sos-alert/sos-alert.controller.ts` | `/sos-alerts` |
| `src/sos-alert/sos-alert.service.ts` | Création, proximité, notifications |
| `src/sos-alert/schemas/sos-alert.schema.ts` | Schéma |
| `src/sos-alert/dto/create-sos-alert.dto.ts` | Création alerte |
| `src/emergency-contact/emergency-contact.module.ts` | Module contacts |
| `src/emergency-contact/emergency-contact.controller.ts` | `/emergency-contacts` |
| `src/emergency-contact/emergency-contact.service.ts` | Liaisons handicapé → accompagnants |
| `src/emergency-contact/schemas/emergency-contact.schema.ts` | Schéma |
| `src/emergency-contact/dto/create-emergency-contact.dto.ts` | DTO |

### Communauté

| Fichier | Rôle |
|---------|------|
| `src/community/community.module.ts` | Imports Mongoose, `HttpModule`, `HelpPriorityModule`, `AccessibilityModule` |
| `src/community/community.controller.ts` | Posts, commentaires, merci, validation obstacle, help-requests |
| `src/community/community.service.ts` | Orchestration métier communauté |
| `src/community/community-vision.service.ts` | Vision / lieux sur posts |
| `src/community/help-request-message-builder.service.ts` | Construction texte inclusif demande d’aide |
| `src/community/help-request-message-builder.service.spec.ts` | Tests |
| `src/community/help-request-message-builder.constants.ts` | Constantes builder |
| `src/community/help-request-message-builder.types.ts` | Types builder |
| `src/community/schemas/post.schema.ts` | Post (géo, danger, validation, IA lieu, merci…) |
| `src/community/schemas/comment.schema.ts` | Commentaire |
| `src/community/schemas/help-request.schema.ts` | Demande d’aide + priorité |
| `src/community/dto/create-post.dto.ts` | Création post |
| `src/community/dto/create-help-request.dto.ts` | Création demande d’aide |
| `src/community/dto/help-requests-paginated.dto.ts` | Réponse paginée |
| `src/community/dto/validate-post-obstacle.dto.ts` | Validation obstacle |
| `src/community/dto/post-place-extraction-result.dto.ts` | Résultat extraction lieu |
| `src/community/enums/post-type.enum.ts` | Types de post |
| `src/community/enums/type-handicap.enum.ts` | Types handicap (filtrage) |
| `src/community/enums/post-inclusion.enum.ts` | Inclusion posts |
| `src/community/enums/help-request-inclusion.enum.ts` | Inclusion demandes |
| `src/community/enums/place-extraction-category.enum.ts` | Catégories lieu |
| `src/community/enums/place-risk-level.enum.ts` | Niveaux de risque |

### Mobilité (agrégateur, gateway, garde)

| Fichier | Rôle |
|---------|------|
| `src/mobilite/mobilite.module.ts` | Agrégateur transport, reviews, vehicle, reservation |
| `src/mobilite/mobilite-core.module.ts` | Garde chauffeur solidaire |
| `src/mobilite/mobilite.constants.ts` | `CHAUFFEURS_SOLIDAIRES_TYPE` |
| `src/mobilite/guards/chauffeur-solidaire.guard.ts` | Vérif type accompagnant + JWT |
| `src/mobilite/transport/transport.gateway.ts` | WebSocket namespace `/transport` |

### Transport

| Fichier | Rôle |
|---------|------|
| `src/transport/transport.module.ts` | Mongoose, `MapModule`, `NotificationModule`, gateway |
| `src/transport/transport.controller.ts` | Routes REST transport |
| `src/transport/transport.service.ts` | Matching, acceptation, statuts, prix, SOS lien réservation |
| `src/transport/transport-pricing.util.ts` | Formule tarif TND |
| `src/transport/transport-pricing.util.spec.ts` | Tests tarification |
| `src/transport/schemas/transport-request.schema.ts` | Schéma course |
| `src/transport/enums/transport-statut.enum.ts` | Statuts VTC |
| `src/transport/enums/transport-type.enum.ts` | `URGENCE` / `QUOTIDIEN` |
| `src/transport/dto/*.ts` | DTO création, matching, accept, cancel, termine, statut |

### Avis transport, véhicules, réservations

| Fichier | Rôle |
|---------|------|
| `src/transport-review/transport-review.module.ts` | Module |
| `src/transport-review/transport-review.controller.ts` | `/transport-reviews` |
| `src/transport-review/transport-review.service.ts` | Avis + mise à jour `noteMoyenne` |
| `src/transport-review/schemas/transport-review.schema.ts` | Schéma |
| `src/transport-review/dto/create-transport-review.dto.ts` | DTO |
| `src/vehicle/vehicle.module.ts` | Module + export schéma |
| `src/vehicle/vehicle.controller.ts` | `/vehicles` |
| `src/vehicle/vehicle.service.ts` | CRUD, géofiltre |
| `src/vehicle/vehicle-geo.util.ts` | Utilitaires géodistance |
| `src/vehicle/schemas/vehicle.schema.ts` | Véhicule adapté |
| `src/vehicle/enums/vehicle-statut.enum.ts` | Validation admin |
| `src/vehicle/dto/create-vehicle.dto.ts`, `update-vehicle.dto.ts`, `accessibilite.dto.ts` | DTO |
| `src/vehicle-reservation/vehicle-reservation.module.ts` | Import `VehicleModule` |
| `src/vehicle-reservation/vehicle-reservation.controller.ts` | `/vehicle-reservations` |
| `src/vehicle-reservation/vehicle-reservation.service.ts` | Réservation + transport lié |
| `src/vehicle-reservation/schemas/vehicle-reservation.schema.ts` | Schéma réservation |
| `src/vehicle-reservation/schemas/vehicle-reservation-review.schema.ts` | Avis trajet |
| `src/vehicle-reservation/dto/*.ts` | DTO création, statut, review |

### Carte et notifications

| Fichier | Rôle |
|---------|------|
| `src/map/map.module.ts` | `HttpModule` |
| `src/map/map.controller.ts` | Géocode, route, places |
| `src/map/map.service.ts` | Nominatim, OSRM, Overpass |
| `src/map/map-places.constants.ts` | Bbox Grand Tunis, filtres POI, limites |
| `src/map/dto/geocode.dto.ts`, `route.dto.ts`, `places-query.dto.ts` | DTO |
| `src/notification/notification.module.ts` | Module |
| `src/notification/notification.controller.ts` | `/notifications` |
| `src/notification/notification.service.ts` | Création, FCM optionnel |
| `src/notification/schemas/notification.schema.ts` | Schéma |

### Tests (`test/` à la racine)

Les scénarios **e2e** et la config Jest sont dans `test/` (`jest-e2e.json`, `app.e2e-spec.ts`, etc.) — voir `npm run test:e2e`.

---

## Licence

MIT
