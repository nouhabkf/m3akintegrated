# Communauté & aide — guide du dépôt (Ma3ak)

Ce fichier est le **point d’entrée** pour comprendre le **module Communauté** (posts, lieux, accessibilité / IA optionnelle) et le **module Aide** (demandes d’assistance géolocalisées, priorisation, acceptation).

---

## Sommaire

1. [Deux périmètres produit](#deux-périmètres-produit)
2. [Où est le code ?](#où-est-le-code)
3. [Documentation détaillée (à lire ensuite)](#documentation-détaillée-à-lire-ensuite)
4. [Routes Flutter (GoRouter)](#routes-flutter-gorouter)
5. [API backend (résumé)](#api-backend-résumé)
6. [IA & accessibilité (communauté)](#ia--accessibilité-communauté)
7. [Démarrage rapide après clonage](#démarrage-rapide-après-clonage)

---

## Deux périmètres produit

| Périmètre | Rôle | Exemples côté app |
|-----------|------|-------------------|
| **Communauté** | Fil de **posts** (texte, images), **lieux** (carte, soumission, détail), parcours **inclusifs** (création de post, FALC / analyse d’image si backend configuré). | `CommunityMainScreen` (4 onglets), `CreatePostScreen`, `PostDetailScreen`, lieux / proximité. |
| **Aide** | **Demandes d’aide** avec **position GPS**, texte, **priorité métier** + score d’urgence côté serveur ; un aidant peut **accepter** une demande. | `HelpRequestsScreen`, `CreateHelpRequestScreen`, `HelpRequestDetailScreen`, `HapticHelpScreen`. |

Navigation principale : écran d’accueil avec onglets — `MainShell` — query ` /home?tab=…&communityTab=…` pour choisir l’onglet principal et le sous-onglet communauté.

---

## Où est le code ?

| Rôle | Chemin |
|------|--------|
| **Écrans & logique UI communauté + aide** | [`frontend/appm3ak/appm3ak/lib/features/community/`](frontend/appm3ak/appm3ak/lib/features/community/) |
| **Modèles** | [`frontend/appm3ak/appm3ak/lib/data/models/`](frontend/appm3ak/appm3ak/lib/data/models/) — `post_model`, `help_request_model`, `create_post_input`, etc. |
| **Appels API** | [`frontend/appm3ak/appm3ak/lib/data/repositories/community_repository.dart`](frontend/appm3ak/appm3ak/lib/data/repositories/community_repository.dart) |
| **Providers Riverpod** | [`frontend/appm3ak/appm3ak/lib/providers/community_providers.dart`](frontend/appm3ak/appm3ak/lib/providers/community_providers.dart) |
| **Routes** | [`frontend/appm3ak/appm3ak/lib/router/app_router.dart`](frontend/appm3ak/appm3ak/lib/router/app_router.dart) |
| **Backend NestJS** | [`backend/backend-m3ak 2/`](backend/backend-m3ak%202/) — préfixe **`/community`** |

---

## Documentation détaillée (à lire ensuite)

| Document | Contenu |
|----------|---------|
| **[`README_COMMUNAUTE_IA.md`](README_COMMUNAUTE_IA.md)** | **IA communauté** : architecture (Flutter → Nest → Python), dataset/modèle, variables d’env, liens vers la doc technique. |
| **[`README_MODULE_COMMUNAUTE_SCENARIOS.md`](README_MODULE_COMMUNAUTE_SCENARIOS.md)** | Vue **métier** par module avec scénarios utilisateur pas-à-pas. |
| **[`frontend/.../features/community/README.md`](frontend/appm3ak/appm3ak/lib/features/community/README.md)** | Vue d’ensemble **Flutter** : onglets, création de post inclusive, liens vers routes et données. |
| **[`frontend/.../features/community/README_AIDE.md`](frontend/appm3ak/appm3ak/lib/features/community/README_AIDE.md)** | **Demandes d’aide** : modèle MongoDB, API, priorisation (`HelpPriorityService`), écrans et badges. |
| **[`frontend/.../features/community/docs/INDEX.md`](frontend/appm3ak/appm3ak/lib/features/community/docs/INDEX.md)** | Index de la **référence technique** (valeurs exactes, DTO backend, payloads repository, modèles). |

---

## Routes Flutter (GoRouter)

Extraits utiles (voir `app_router.dart` pour la liste complète) :

| Route | Écran / usage |
|-------|----------------|
| `/home?tab=…&communityTab=…` | Accueil + sous-onglet communauté |
| `/community-posts` | Communauté, onglet posts |
| `/create-post` | Créer un post |
| `/post-detail/:id` | Détail d’un post |
| `/help-requests` | Liste des demandes d’aide |
| `/create-help-request` | Créer une demande |
| `/help-request-detail` | Détail (modèle passé en **`extra`**) |
| `/community-locations`, `/community-nearby`, `/community-contacts` | Lieux / proximité / contacts |
| `/submit-location`, `/location-detail/:id` | Contribution et fiche lieu |
| `/haptic-help` | Parcours aide haptique / SOS |

---

## API backend (résumé)

Base URL : celle de l’app (`AppConfig` / client Dio). Contrôleur **`CommunityController`** — préfixe **`/community`**.

| Besoin | Méthode | Chemin indicatif |
|--------|---------|------------------|
| Créer un post | `POST` | `/community/posts` (souvent **multipart** : texte, type, images) |
| Créer une demande d’aide | `POST` | `/community/help-requests` (**JSON** : position, description, champs inclusifs) |
| Lister les demandes | `GET` | `/community/help-requests` |
| Accepter une demande | `PATCH` | `/community/help-requests/:id/accept` |

Schémas et enums : dossier `src/community/` du backend (`post.schema`, `help-request.schema`, DTO `create-post`, `create-help-request`).

---

## IA & accessibilité (communauté)

Fonctions optionnelles (selon `.env` du serveur : **Ollama**, **Gemini**, etc.) :

- **FALC / simplification de texte** et **capacités** : routes du type `/community/vision/…` (voir `community_repository.dart` et `endpoints.dart`).
- **Description audio / analyse d’image** pour les posts avec photos : aligné sur le service d’accessibilité côté Nest (`AccessibilityService` / `CommunityVisionService`).

Sans clé API ni Ollama joignable, l’app peut retomber sur des **repli** (heuristique, texte statique). Voir `.env.example` du backend pour `OLLAMA_*`, `GEMINI_*`.

---

## Démarrage rapide après clonage

1. **Flutter** : `cd frontend/appm3ak/appm3ak` → `flutter pub get`
2. **Backend** : `cd "backend/backend-m3ak 2"` → `npm install` → `npm run start:dev` (ou script équivalent dans `package.json`)
3. Variables d’environnement : ne pas committer les secrets ; suivre les `.env.example` présents.

Voir aussi [`PARTAGE_ZIP.md`](PARTAGE_ZIP.md) si le projet a été partagé sans `node_modules` ni builds.

---

*Ce fichier centralise les liens ; le détail métier « aide seule » reste dans [`README_AIDE.md`](frontend/appm3ak/appm3ak/lib/features/community/README_AIDE.md).*
