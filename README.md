# Ma3ak (M3ak) — Monorepo

Plateforme mobile et API pour la **mobilité**, l’**inclusion** et l’**entraide** des personnes en situation de handicap (Tunisie et au-delà). Ce dépôt regroupe le **backend NestJS**, le **service Python d’IA**, la **application Flutter**, des **scripts** d’installation et de déploiement léger, ainsi que la documentation métier.

---

## Sommaire

1. [Vue d’ensemble](#vue-densemble)
2. [Structure du dépôt](#structure-du-dépôt)
3. [Prérequis](#prérequis)
4. [Installation](#installation)
5. [Configuration](#configuration)
6. [Démarrage des services](#démarrage-des-services)
7. [Ports et URLs utiles](#ports-et-urls-utiles)
8. [Service IA Python (FastAPI)](#service-ia-python-fastapi)
9. [Proxy NestJS vers l’IA](#proxy-nestjs-vers-lia)
10. [MongoDB et seeds](#mongodb-et-seeds)
11. [Application Flutter](#application-flutter)
12. [Scripts utilitaires](#scripts-utilitaires)
13. [Documentation détaillée](#documentation-détaillée)
14. [Dépannage](#dépannage)

---

## Vue d’ensemble

| Couche | Technologie | Rôle |
|--------|-------------|------|
| Application cliente | Flutter (Dart 3.x) | UI mobile (web possible), communauté, accessibilité, cartes, SOS, etc. |
| API principale | NestJS 10, MongoDB / Mongoose | Auth JWT, Google OAuth, lieux, communauté, notifications, résumés IA via Ollama/Gemini selon config |
| IA dédiée | FastAPI (Python) | Plan d’action communauté (ML), analyse d’accessibilité des lieux (Groq + OpenStreetMap) |

Flutter parle à **Nest**. Nest fait office de **proxy HTTP** vers le service Python pour les fonctionnalités IA « plan d’action » et « analyse lieu ». Les autres IA (FALC, vision, etc.) sont orchestrées côté Nest (Ollama, Gemini, Vision Google selon les variables d’environnement).

---

## Structure du dépôt

```
apppm3ak/
├── frontend/appm3ak/appm3ak/   # Application Flutter
├── backend/backend-m3ak 2/     # API NestJS principale (attention : nom du dossier avec espace)
├── ai/                         # FastAPI : communauté ML + accessibilité Groq/OSM
├── scripts/                    # PowerShell : démarrage, installation, export ZIP
├── module-communaute/          # Schémas / docs module communauté (référence)
├── seed.js, exportSeed.js      # Utilitaires Node à la racine (seed données)
└── *.md                        # Guides métier et IA (voir index ci-dessous)
```

---

## Prérequis

- **Node.js** 20 ou 22 et **npm**
- **MongoDB** (local ou Atlas)
- **Flutter SDK** et **Dart 3.x** (pour l’app mobile)
- **Python** 3.10+ et **pip** (pour le service `ai/`)
- **Android Studio** / émulateur ou appareil physique ; pour iOS, Xcode sur macOS
- Optionnel : **Ollama** (résumés, vision locale), **clé Groq** (analyse accessibilité lieux), **Google Cloud / Gemini** selon modules activés

---

## Installation

### Automatisée (Windows)

À la racine du dépôt :

```powershell
powershell -ExecutionPolicy Bypass -File scripts/installer-tout.ps1
```

Installe les dépendances **npm** du backend et exécute **`flutter pub get`** dans le dossier Flutter prévu.

### Manuelle

**Backend**

```powershell
cd "backend\backend-m3ak 2"
npm install
```

**Flutter**

```powershell
cd frontend\appm3ak\appm3ak
flutter pub get
```

**IA Python**

```powershell
cd ai
python -m venv .venv
.\.venv\Scripts\activate
pip install -r requirements.txt
```

Crée un fichier **`ai/.env`** (voir [Configuration](#configuration)).

---

## Configuration

### Backend — `backend/backend-m3ak 2/.env`

Configurer au minimum :

| Variable | Description |
|----------|-------------|
| `MONGODB_URI` | URI MongoDB (ex. `mongodb://localhost:27017/ma3ak`) |
| `JWT_SECRET` | Secret de signature des JWT |
| `PORT` | Port HTTP de l’API (défaut souvent `3000`) |
| `GOOGLE_CLIENT_ID` | OAuth Google (si login Google utilisé) |

**IA via Nest (proxy vers Python)** — même URL de base pour les deux usages :

| Variable | Description |
|----------|-------------|
| `AI_COMMUNITY_BASE_URL` | URL du service FastAPI (ex. `http://127.0.0.1:8001`) — **sans slash final** |
| `AI_COMMUNITY_TIMEOUT_MS` | Timeout appels « plan d’action communauté » (ex. `10000`) |
| `AI_ACCESSIBILITY_TIMEOUT_MS` | Timeout analyse lieu Groq + OSM (ex. `90000`) |

Les options **Ollama**, **Gemini**, **Google Vision** sont documentées dans les commentaires du `.env` du backend et dans `backend/backend-m3ak 2/docs/`.

### Service Python — `ai/.env`

| Variable | Description |
|----------|-------------|
| `GROQ_API_KEY` | Obligatoire pour **`POST /ai/accessibility/analyze`** |
| `GROQ_TEXT_MODEL` | Optionnel (défaut `llama-3.1-8b-instant`) |
| `CORS_ORIGINS` | Optionnel : liste séparée par virgules ; sinon CORS ouvert en dev |

Le fichier est chargé automatiquement depuis le dossier **`ai/`** au démarrage de l’app FastAPI.

---

## Démarrage des services

Ordre recommandé en développement :

1. **MongoDB**
2. **Service IA Python** (si vous utilisez l’entrée IA communauté ou l’analyse accessibilité lieux)
3. **Backend NestJS**
4. **Flutter**

### Scripts PowerShell (racine `scripts/`)

| Script | Action |
|--------|--------|
| `installer-tout.ps1` | `npm install` backend + `flutter pub get` |
| `1-demarrer-backend.ps1` | `npm run start:dev` dans le backend |
| `2-demarrer-flutter.ps1` | `flutter pub get` puis `flutter run` (paramètre `-Web` pour Chrome) |

### IA Python

Depuis le dossier **`ai/`** (adapter le **port** à celui indiqué dans `AI_COMMUNITY_BASE_URL`, ex. **8001**) :

```powershell
cd ai
.\.venv\Scripts\activate
uvicorn src.app:app --reload --host 127.0.0.1 --port 8001
```

### Backend

```powershell
cd "backend\backend-m3ak 2"
npm run start:dev
```

---

## Ports et URLs utiles

| Service | URL typique |
|---------|-------------|
| API NestJS | `http://localhost:3000` |
| Swagger Nest | `http://localhost:3000/api` |
| FastAPI IA | `http://127.0.0.1:8001` (si vous choisissez le port 8001) |
| Santé IA | `GET http://127.0.0.1:8001/health` |

---

## Service IA Python (FastAPI)

Répertoire : **`ai/`**.

| Méthode | Chemin | Rôle |
|---------|--------|------|
| `GET` | `/health` | Statut global + indicateur présence clé Groq |
| `POST` | `/ai/community/action-plan` | Classification / plan d’action (post ou demande d’aide) à partir du texte libre |
| `POST` | `/ai/accessibility/analyze` | Scores d’accessibilité par axe (Groq + contexte OSM + données formulaire) |

Entraînement du modèle communauté (si vous modifiez le dataset) : voir **`ai/README_AI.md`** et `python src/train_model.py`.

**Seed des posts démo** (collection MongoDB `posts`, base `ma3ak`) :

```powershell
cd ai
python scripts/seed_posts.py
```

Variables optionnelles : `MONGODB_URI`, `DB_NAME` (voir en-tête du script).

---

## Proxy NestJS vers l’IA

Le backend expose des routes qui **relèvent** le même service Python :

| Route Nest | Service Python cible |
|------------|----------------------|
| `POST /community/ai/action-plan` | `POST .../ai/community/action-plan` |
| `POST /lieux/ai/analyze-accessibility` | `POST .../ai/accessibility/analyze` |

Si le service Python est arrêté ou injoignable, Nest renvoie une erreur **503** au client.

---

## MongoDB et seeds

- **URI** : alignée sur `MONGODB_URI` dans le `.env` du backend.
- **Racine du repo** : `npm install` puis `npm run seed` ou `npm run export-seed` selon `package.json` (scripts Node utilisant MongoDB).
- **Backend** : scripts `seed:dev` / `seed:dev:win` pour utilisateur de test (voir `backend/backend-m3ak 2/package.json`).

---

## Application Flutter

Chemin attendu : **`frontend/appm3ak/appm3ak`**.

```powershell
cd frontend\appm3ak\appm3ak
flutter pub get
flutter run
```

### URL de l’API selon l’environnement

| Contexte | Base URL API suggérée |
|----------|------------------------|
| Émulateur Android | `http://10.0.2.2:3000` |
| Simulateur iOS / navigateur desktop | `http://localhost:3000` |
| Téléphone réel (même réseau Wi‑Fi) | `http://<IP_LAN_DU_PC>:3000` |

Exemple :

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

---

## Scripts utilitaires

| Script | Description |
|--------|-------------|
| `scripts/export_slim_zips.ps1` | Génère des archives ZIP allégées (`frontend.zip`, `backend.zip`) pour partage (&lt; 25 Mo), avec exclusions documentées dans le script |
| Racine : `npm run seed` / `export-seed` | Seeds Node (voir `package.json` racine) |

---

## Documentation détaillée

| Document | Contenu |
|----------|---------|
| `README_COMMUNAUTE_AIDE.md` | Module Communauté / Aide |
| `README_COMMUNAUTE_IA.md` | Vue IA communauté |
| `README_IA_GLOBAL.md` | Architecture Flutter ↔ Nest ↔ Python, contrats et invariants |
| `README_MODELE_IA_ACTUELLE.md` | Modèle ML communauté |
| `ai/README_AI.md` | Service Python : dataset, entraînement, endpoints |
| `backend/backend-m3ak 2/README.md` | Backend Nest : API, sécurité, installation |
| `INTEGRATION_MODULE_COMMUNAUTE.md` | Intégration module communauté |
| `FONCTIONNALITES_ACCES_COMMUNAUTE.md` | Fonctionnalités accès communauté |

---

## Dépannage

- **502 / 503 sur les fonctionnalités IA** : vérifier que **uvicorn** tourne sur l’URL et le port définis dans `AI_COMMUNITY_BASE_URL`, et que **`GET /health`** sur le service Python répond.
- **`missing_groq_key` dans `/health`** : ajouter **`GROQ_API_KEY`** dans **`ai/.env`** pour l’analyse accessibilité lieux.
- **Timeout login / Flutter vers l’API** : firewall Windows (port **3000**), Nest bien démarré, **bonne URL** selon émulateur ou téléphone (voir tableau ci-dessus).
- **Erreur Nest du type module introuvable** : relancer **`npm install`** dans **`backend/backend-m3ak 2`**.
- **Nom du dossier backend** : le chemin contient un **espace** (`backend-m3ak 2`) ; toujours utiliser des guillemets dans les commandes PowerShell et `cd`.

---

*README racine — à jour avec la structure monorepo Ma3ak (Nest + Flutter + IA Python). Pour le détail d’un module, suivre les liens du tableau [Documentation détaillée](#documentation-détaillée).*
