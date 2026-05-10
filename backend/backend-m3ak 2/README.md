# Ma3ak API — Backend

> API REST NestJS pour l'application **Ma3ak** — plateforme destinée aux personnes en situation de handicap en Tunisie et à leurs accompagnants. Facilite la mobilité, l'autonomie et l'inclusion sociale.

---

## 📋 À propos de ce document

Ce README est conçu pour être partagé avec l'équipe. Il contient tout ce dont vous avez besoin pour comprendre, installer et contribuer au backend Ma3ak. Les commentaires explicatifs (💡 **Note**, ⚠️ **Important**, 📌 **À savoir**) facilitent la prise en main.

---

## Table des matières

1. [Démarrage rapide (nouveaux arrivants)](#1-démarrage-rapide-nouveaux-arrivants)
2. [Contexte et objectifs](#2-contexte-et-objectifs)
3. [Stack technique](#3-stack-technique)
4. [Architecture du projet](#4-architecture-du-projet)
5. [Logique métier](#5-logique-métier)
6. [Modèles de données](#6-modèles-de-données)
7. [API — Documentation complète](#7-api--documentation-complète)
8. [Configuration](#8-configuration)
9. [Sécurité](#9-sécurité)
10. [Installation et démarrage](#10-installation-et-démarrage)
11. [Projets associés](#11-projets-associés)
12. [Scénarios d’usage typiques](#12-scénarios-dusage-typiques)

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

### Fonctionnalités prévues

Localisation de zones accessibles, réservation de lieux adaptés, transport, mise en relation avec accompagnants humains ou animaux d'assistance, modules éducatifs (Braille, langue des signes), alertes SOS, recommandations personnalisées par IA.

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
| **Upload fichiers** | Multer (stockage disque, dossier `uploads/`) |
| **IA texte / vision (optionnel)** | Ollama (HTTP) pour résumés et scores — voir `AccessibilityService` |
| **SDK Google** | Cloud Vision, Generative AI (selon services activés dans les modules) |

---

## 4. Architecture du projet

> **📌 Structure des dossiers** — Chaque module NestJS regroupe généralement : `*.module.ts`, `*.controller.ts`, `*.service.ts`, `dto/`, `schemas/`.

```
src/
├── main.ts                       # Point d'entrée : CORS, ValidationPipe, Swagger, fichiers statiques
├── app.module.ts                 # Module racine — importe tous les sous-modules
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
├── medical-record/               # Dossiers médicaux — 1 user HANDICAPE = 1 dossier
├── sos-alert/                    # Alertes SOS avec géolocalisation
├── emergency-contact/            # Contacts urgence (handicapé ↔ accompagnants)
├── transport/                    # Demandes de transport, matching accompagnants
├── transport-review/             # Évaluations transport → met à jour noteMoyenne
├── lieu/                         # Lieux accessibles (index géospatial 2dsphere)
├── lieu-reservation/             # Réservations de lieux
├── community/                    # Communauté — posts, commentaires, demandes d'aide, extraction lieu
├── education/                    # Modules éducatifs (Braille, LANGUE_SIGNES)
├── notification/                 # Notifications utilisateur
├── accessibility/                # Feature flags Ollama + résumés commentaires / score urgence
├── m3ak-learning/                # Compat. ancienne API M3AK : Braille, prédiction, vision signes/visage
├── m3ak-guidance/                # Sessions guidage + analyse de frames (images base64)
│
└── uploads/                      # Fichiers uploadés (servis sous /uploads/)
```

---

## 5. Logique métier

### Rôles

> **⚠️ Important** — Les rôles sont `HANDICAPE`, `ACCOMPAGNANT` et `ADMIN`. Les anciens noms (`BENEFICIARY`, `COMPANION`) ne sont plus utilisés.

| Rôle | Description |
|------|-------------|
| `HANDICAPE` | Personne en situation de handicap — dossier médical, alertes SOS, contacts urgence, demandes de transport |
| `ACCOMPAGNANT` | Accompagnant — disponible pour transport, dans les contacts urgence, noté via transport-reviews |
| `ADMIN` | Administrateur — accès au backoffice et CRUD utilisateurs |

### Règles principales

1. **Inscription** : Rôle par défaut `HANDICAPE` si non précisé. L'email doit être unique.
2. **Login Google** : Si l'utilisateur n'existe pas, il est créé avec rôle `HANDICAPE` et mot de passe factice hashé.
3. **Dossier médical** : 1 utilisateur HANDICAPE → 1 dossier médical (groupe sanguin, allergies, etc.).
4. **Contacts urgence** : Un HANDICAPE peut ajouter des ACCOMPAGNANT avec ordre de priorité.
5. **Transport** : Le demandeur crée une demande ; un accompagnant disponible peut l'accepter. Les évaluations mettent à jour `noteMoyenne`.
6. **Admin** : Les routes `/admin/*` sont protégées par JWT + rôle `ADMIN`.
7. **Communauté / IA** : À la création d'un post, `CommunityVisionService` analyse le texte (lieu, risque, obstacle) via heuristiques et, pour les résumés / urgence, via `AccessibilityService` (Ollama si disponible, sinon repli local). Un danger **critique** avec coordonnées peut déclencher une **alerte SOS** (`SosAlertService`).
8. **Points de confiance** : Les utilisateurs peuvent accumuler des `trustPoints` (commentaires utiles, acceptation de demandes d'aide — voir `CommunityService`).

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
| `typeAccompagnant` | string | non | Type d'accompagnant (pour ACCOMPAGNANT) |
| `specialisation` | string | non | Spécialisation (pour ACCOMPAGNANT) |
| `disponible` | boolean | non | Disponible pour accompagnement (défaut: false) |
| `noteMoyenne` | number | non | Note moyenne des évaluations (défaut: 0) |
| `trustPoints` | number | non | Points de confiance (communauté : commentaires, aide) |
| `langue` | string | non | Langue préférée (ar, fr, etc.) |
| `photoProfil` | string | non | URL photo de profil |
| `statut` | string | non | ACTIF (défaut) |
| `createdAt` | Date | auto | Timestamps |
| `updatedAt` | Date | auto | Timestamps |

### MedicalRecord (collection `medicalRecords`)

1 user HANDICAPE → 1 dossier. Champs : `userId`, `groupeSanguin`, `allergies`, `maladiesChroniques`, `medicaments`, `medecinTraitant`, `contactUrgence`, `updatedAt`.

### SosAlert (collection `sosAlerts`)

Champs : `userId`, `latitude`, `longitude`, `statut` (ENVOYEE), `createdAt`. Index sur latitude/longitude pour les requêtes géospatiales.

### EmergencyContact (collection `emergencyContacts`)

Champs : `userId` (handicapé), `accompagnantId`, `ordrePriorite` — ordre d'appel en cas d'urgence.

### TransportRequest (collection `transportRequests`)

Champs : `demandeurId`, `accompagnantId`, `typeTransport` (URGENCE, QUOTIDIEN), `depart`, `destination`, `latitudeDepart`, `longitudeDepart`, `latitudeArrivee`, `longitudeArrivee`, `dateHeure`, `statut`, `scoreMatching`, `createdAt`.

### TransportReview (collection `transportReviews`)

Champs : `transportId`, `note` (1–5), `commentaire`, `createdAt`. Met à jour `noteMoyenne` de l'accompagnant.

### Lieu (collection `lieux`)

Champs : `nom`, `adresse`, `typeLieu`, `latitude`, `longitude`, `description`, `scoreAccessibilite`, `rampe`, `ascenseur`, `toilettesAdaptees`, `createdAt`. Index géospatial 2dsphere sur `location`.

### LieuReservation (collection `lieuReservations`)

Champs : `userId`, `lieuId`, `date`, `heure`, `besoinsSpecifiques`, `qrCode`, `statut`, `createdAt`.

### Post (collection `posts`)

Champs principaux : `userId`, `contenu`, `type`, `images[]`, géolocalisation optionnelle (`latitude`, `longitude`), `dangerLevel` (ex. `none`, `critical` — si critique + coords, le serveur peut créer une alerte SOS).

Champs **IA / lieu** : `hasPlace`, `placeText`, `placeCategory`, `placeConfidence`, `riskLevel`, `obstaclePresent`, `aiSummary`, `reasonCodes[]`, `placeVerificationStatus`, `linkedLieuId`, `validationYes`, `validationNo`.

### Comment (collection `comments`)

Champs : `postId`, `userId`, `contenu`, `createdAt`.

### HelpRequest (collection `helpRequests`)

Champs : `userId`, `description`, `latitude`, `longitude`, `statut`, `createdAt`.

### EducationModule (collection `educationmodules`)

Champs : `titre`, `type` (BRAILLE, LANGUE_SIGNES), `niveau`, `description`.

### EducationProgress (collection `educationprogresses`)

Champs : `userId`, `moduleId`, `score`, `niveauActuel`, `derniereActivite`.

### Notification (collection `notifications`)

Champs : `userId`, `titre`, `message`, `type`, `lu` (défaut: false), `createdAt`.

---

## 7. API — Documentation complète

**Base URL :** `http://localhost:3000` (ou variable d'environnement `PORT`)

**Swagger :** http://localhost:3000/api — documentation interactive et schémas

**Header auth :** `Authorization: Bearer <access_token>` (obligatoire pour toutes les routes protégées, sauf login et register)

---

### Auth (`/auth`)

| Méthode | Endpoint | Auth | Body | Réponse |
|---------|----------|------|------|---------|
| POST | `/auth/login` | Non | `{ email, password }` | `{ access_token, user }` |
| POST | `/auth/google` | Non | `{ id_token }` | `{ access_token, user }` |
| GET | `/auth/config-test` | Non | — | `{ jwtSecretConfigured, googleClientIdConfigured }` |

---

### User (`/user`)

| Méthode | Endpoint | Auth | Description |
|---------|----------|------|-------------|
| POST | `/user/register` | Non | Inscription — CreateUserDto |
| GET | `/user/me` | JWT | Profil de l'utilisateur connecté |
| PATCH | `/user/me` | JWT | Mise à jour du profil (UpdateUserDto) |
| DELETE | `/user/me` | JWT | Suppression du compte |
| PATCH | `/user/me/photo` | JWT | Upload photo de profil (multipart, champ `image`) |

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

### Medical Record (`/medical-records`)

| Méthode | Endpoint | Auth | Description |
|---------|----------|------|-------------|
| POST | `/medical-records` | JWT | Créer mon dossier médical (HANDICAPE) |
| GET | `/medical-records/me` | JWT | Récupérer mon dossier |
| PATCH | `/medical-records/me` | JWT | Mettre à jour mon dossier |

---

### SOS Alerts (`/sos-alerts`)

| Méthode | Endpoint | Auth | Description |
|---------|----------|------|-------------|
| POST | `/sos-alerts` | JWT | Envoyer une alerte SOS |
| GET | `/sos-alerts/me` | JWT | Mes alertes |
| GET | `/sos-alerts/nearby` | JWT | Alertes à proximité (query: latitude, longitude) |
| POST | `/sos-alerts/:id/statut` | JWT | Mettre à jour le statut |
| POST | `/sos-alerts/:id/respond` | JWT | Répondre / prendre en charge une alerte (voir contrôleur) |

---

### Emergency Contacts (`/emergency-contacts`)

| Méthode | Endpoint | Auth | Description |
|---------|----------|------|-------------|
| POST | `/emergency-contacts` | JWT | Ajouter un contact urgence |
| GET | `/emergency-contacts/me` | JWT | Mes contacts |
| DELETE | `/emergency-contacts/:id` | JWT | Retirer un contact |

---

### Transport (`/transport`)

| Méthode | Endpoint | Auth | Description |
|---------|----------|------|-------------|
| POST | `/transport` | JWT | Créer une demande de transport |
| GET | `/transport/matching` | JWT | Accompagnants disponibles (query: latitude, longitude) |
| POST | `/transport/:id/accept` | JWT | Accepter une demande (accompagnant) |
| POST | `/transport/:id/cancel` | JWT | Annuler une demande |
| GET | `/transport/me` | JWT | Mes demandes (en tant que demandeur ou accompagnant) |
| GET | `/transport/available` | JWT | Demandes en attente (accompagnants) |

---

### Transport Reviews (`/transport-reviews`)

| Méthode | Endpoint | Auth | Description |
|---------|----------|------|-------------|
| POST | `/transport-reviews/transport/:transportId` | JWT | Évaluer un transport |
| GET | `/transport-reviews/transport/:transportId` | JWT | Évaluations d'un transport |

---

### Lieux (`/lieux`)

| Méthode | Endpoint | Auth | Description |
|---------|----------|------|-------------|
| POST | `/lieux` | JWT | Créer un lieu |
| GET | `/lieux` | Non | Liste (query: typeLieu, page, limit) |
| GET | `/lieux/nearby` | Non | À proximité (query: latitude, longitude, maxDistance) |
| GET | `/lieux/:id` | Non | Détail |
| PATCH | `/lieux/:id` | JWT | Modifier |
| DELETE | `/lieux/:id` | JWT | Supprimer |

---

### Lieu Reservations (`/lieu-reservations`)

| Méthode | Endpoint | Auth | Description |
|---------|----------|------|-------------|
| POST | `/lieu-reservations` | JWT | Créer une réservation |
| GET | `/lieu-reservations/me` | JWT | Mes réservations |
| GET | `/lieu-reservations/lieu/:lieuId` | JWT | Réservations d'un lieu |
| POST | `/lieu-reservations/:id/statut` | JWT | Mettre à jour le statut |

---

### Community (`/community`)

| Méthode | Endpoint | Auth | Description |
|---------|----------|------|-------------|
| POST | `/community/posts` | JWT | Créer un post (multipart possible — images) |
| GET | `/community/posts` | Non | Liste des posts (pagination) |
| GET | `/community/posts/for-me` | JWT | Posts filtrés selon le profil handicap |
| GET | `/community/posts/:id` | Non | Détail d'un post |
| POST | `/community/posts/:postId/validate-obstacle` | JWT | Valider « obstacle toujours présent » (oui/non) |
| POST | `/community/posts/:postId/comments` | JWT | Commenter un post |
| GET | `/community/posts/:postId/comments` | Non | Commentaires d'un post |
| GET | `/community/posts/:postId/comments/flash-summary` | Non | Résumé flash des commentaires (Ollama ou heuristique) |
| POST | `/community/help-requests` | JWT | Créer une demande d'aide |
| GET | `/community/help-requests` | Non | Liste des demandes |
| POST | `/community/help-requests/:id/statut` | JWT | Mettre à jour le statut |
| PATCH | `/community/help-requests/:id/accept` | JWT | Accepter une demande d'aide (accompagnant) |

---

### Accessibility (`/accessibility`)

| Méthode | Endpoint | Auth | Description |
|---------|----------|------|-------------|
| GET | `/accessibility/features` | Non | Flags Ollama (`ollamaEnabled`, URLs, modèles) + ping `/api/tags` |

---

### M3AK Learning & Vision (`/m3ak`)

Compatibilité avec l’ancienne API FastAPI M3AK (Braille, prédiction, signes, visage).

| Méthode | Endpoint | Auth | Description |
|---------|----------|------|-------------|
| GET | `/m3ak` | Non | Health check sous-namespace M3AK |
| GET | `/m3ak/next_exercise/:userId` | Non | Prochain exercice Braille |
| POST | `/m3ak/predict` | Non | Prédiction / feedback pédagogique |
| POST | `/m3ak/update_profile/:userId` | Non | Mise à jour profil progression |
| POST | `/m3ak/sign/explain` | Non | Analyse / explication LSF (fichier upload) |
| POST | `/m3ak/face/detect` | Non | Détection visage |
| POST | `/m3ak/face/encode` | Non | Encodage / embedding |
| POST | `/m3ak/face/emotion` | Non | Émotion |

---

### M3AK Guidance (`/m3ak/guidance`)

| Méthode | Endpoint | Auth | Description |
|---------|----------|------|-------------|
| POST | `/m3ak/guidance/session` | Non | Créer une session (hint client) |
| POST | `/m3ak/guidance/frame` | Non | Analyser une image (base64) dans une session |

---

### Education (`/education`)

| Méthode | Endpoint | Auth | Description |
|---------|----------|------|-------------|
| GET | `/education/modules` | Non | Liste des modules (query: type) |
| GET | `/education/modules/:id` | Non | Détail d'un module |
| POST | `/education/modules` | JWT | Créer un module (admin) |
| GET | `/education/progress` | JWT | Mon progrès |
| POST | `/education/progress` | JWT | Mettre à jour mon progrès |

---

### Notifications (`/notifications`)

| Méthode | Endpoint | Auth | Description |
|---------|----------|------|-------------|
| GET | `/notifications` | JWT | Mes notifications |
| POST | `/notifications/:id/read` | JWT | Marquer comme lue |
| POST | `/notifications/read-all` | JWT | Tout marquer comme lu |

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
| `CORS_ORIGINS` | Non | Origines autorisées, séparées par des virgules (production) |
| `NODE_ENV` | Non | `production` : CORS restreint, écoute sur `PORT` uniquement ; sinon CORS large et `0.0.0.0` pour émulateurs |
| `OLLAMA_ENABLED` | Non | Si absent : **Ollama activé** par défaut ; `false` pour forcer le repli heuristique |
| `OLLAMA_BASE_URL` | Non | Défaut `http://127.0.0.1:11434` |
| `OLLAMA_MODEL` | Non | Modèle texte (défaut `llama3.2`) |
| `OLLAMA_VISION_MODEL` | Non | Modèle vision (défaut `llava`) |

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
```

### Accès

- **API :** http://localhost:3000
- **Swagger :** http://localhost:3000/api
- **Health check :** http://localhost:3000

### Créer un compte admin

1. Inscription : `POST /user/register` avec `"role": "ADMIN"`
2. Ou modifier un utilisateur existant en base : `role: "ADMIN"`

---

## 11. Projets associés

> **💡 Pour l'équipe** — Ces projets consomment cette API. Des prompts dédiés facilitent leur développement.

| Projet | Fichier | Description |
|--------|---------|-------------|
| **App mobile Flutter** | `FLUTTER_APP_PROMPT.md` | Application Ma3ak pour handicapés et accompagnants |
| **Backoffice web (CRUD)** | `BACKOFFICE_CRUD_PROMPT.md` | Site web pour CRUD utilisateurs (admin) |
| **Backoffice web (complet)** | `BACKOFFICE_ADMIN_PROMPT.md` | Description détaillée du backoffice |
| **Backoffice web (mise à jour)** | `BACKOFFICE_WEB_PROMPT.md` | Changements API 2025 pour le backoffice |

---

## 12. Scénarios d’usage typiques

1. **Onboarding** : `POST /user/register` → `POST /auth/login` (ou `POST /auth/google`) → toutes les routes JWT avec `Authorization: Bearer …`.
2. **Signalement d’obstacle avec position** : `POST /community/posts` avec texte, coords, `dangerLevel` ; le serveur enrichit le post (extraction lieu, statut de vérification) et, si `dangerLevel === critical` et coords valides, crée une **SOS** pour les utilisateurs à proximité.
3. **Validation par la communauté** : autres utilisateurs appellent `POST …/validate-obstacle` pour confirmer ou infirmer la présence de l’obstacle (votes).
4. **Résumé des commentaires** : `GET …/comments/flash-summary` — utile pour afficher une synthèse courte (Ollama si joignable).
5. **Demande d’aide terrain** : création `POST /community/help-requests` → un accompagnant `PATCH …/accept` → points de confiance mis à jour selon la logique métier.
6. **Transport** : `POST /transport` → accompagnant `POST /transport/:id/accept` → fin de course → `POST /transport-reviews/transport/:id` pour noter.
7. **Inclusion M3AK (Flutter + ancienne stack)** : l’app mobile appelle `GET/POST /m3ak/*` (Braille, prédiction, LSF, visage) et éventuellement `POST /m3ak/guidance/frame` pour l’analyse d’images guidée.
8. **Administration** : compte `ADMIN` → `GET/PATCH/DELETE /admin/users` pour support et modération.

---

## Licence

MIT
