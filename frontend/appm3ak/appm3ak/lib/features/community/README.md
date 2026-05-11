# Communauté & aide — état actuel (Ma3ak)

Documentation à jour du **module Communauté** dans l’app Flutter : fils de contenu, lieux, **demandes d’aide** géolocalisées, et parcours **accessibilité** associés.

**Vue d’ensemble dépôt (liens Flutter + backend + API) :** voir à la racine du projet **[README_COMMUNAUTE_AIDE.md](../../../../../../README_COMMUNAUTE_AIDE.md)** (chemin relatif depuis ce fichier : remonter jusqu’à la racine du repo `appm3ak`).

**Référence technique (valeurs API, DTO, payloads, modèles) :** voir le dossier **[docs/](docs/INDEX.md)** (`valeurs_exactes.md`, `modeles_flutter.md`, `backend_dto_schemas.md`, `api_repository_payloads.md`).

---

## Vue d’ensemble

| Zone | Rôle |
|------|------|
| **Posts** | Partage d’informations, signalements, conseils, témoignages (communauté). |
| **Lieux** | Référentiel / soumission / détail de lieux (accessibilité). |
| **À proximité** | Lieux à proximité (app mobile, géolocalisation). |
| **Aide** | Demandes d’urgence ou d’assistance **avec position** ; priorisation côté serveur ; acceptation par un aidant. |

Écran conteneur : `screens/community_main_screen.dart` — **4 onglets** (0 = lieux, 1 = posts, 2 = à proximité, 3 = demandes d’aide).  
Navigation globale : `/home?tab=…&communityTab=…` (onglet principal + sous-onglet communauté).

---

## Routes utiles (`app_router.dart`)

| Route | Écran |
|--------|--------|
| `/community-posts` | `CommunityMainScreen` (onglet posts) |
| `/create-post` | `CreatePostScreen` (texte, images, options inclusives) |
| `/create-post-head-gesture` | Saisie tête / yeux |
| `/create-post-vibration` | Saisie par vibrations codées |
| `/create-post-voice-vibration` | Voix + vibrations |
| `/post-detail/:id` | Détail d’un post |
| `/help-requests` | Liste des demandes d’aide |
| `/create-help-request` | Créer une demande |
| `/help-request-detail` | Détail (via `extra`: `HelpRequestModel`) |
| `/haptic-help` | Aide haptique / vibrations |
| `/community-locations`, `/community-nearby`, `/community-contacts` | Parcours lieux / proches / contacts |
| `/submit-location`, `/location-detail/:id` | Contribution et fiche lieu |

---

## Création de post (actualité produit)

| | |
|---|---|
| **Fichier** | `screens/create_post_screen.dart` |
| **Route** | `/create-post` |
| **API** | `POST /community/posts` (multipart) |

### Champs principaux (rétrocompatibles)

- `contenu`, `type` (type « legacy » dérivé des choix inclusifs), images, latitude / longitude, `dangerLevel` si alerte.

### Champs inclusifs optionnels (modèle `CreatePostInput`)

Nature du post, public cible, mode de saisie, publication pour un tiers, besoins d’accessibilité, mode de partage de position — alignés sur le backend Nest (`postNature`, `targetAudience`, `inputMode`, `isForAnotherPerson`, besoins booléens, `locationSharingMode`, etc.).

### Comportement actuel

- **Qui publie ?** : interrupteur explicite *Je publie pour moi* / *Je publie pour quelqu’un d’autre* ; en mode « autre personne », le mode de saisie peut passer à **accompagnant** si la saisie était au clavier ; texte d’intro possible dans les modèles ; aperçu avec note « message relayé ».
- **Suggestions rapides** : puces basées sur `logic/post_create_preset_config.dart` (signalement, accès, orientation, conseil, témoignage, etc.) — remplissage du texte + nature / public / besoins associés.
- **Besoins d’accessibilité** : cases avec libellés et descriptions (audio, visuel, physique, langage simple).
- **Parcours accessibilité** : préférences + routes dédiées (`features/accessibility/`) ; retour sur le formulaire complet avec reprise de contenu (`AccessibilityPostHandoff`).

Mapping type legacy : `logic/post_create_legacy_type.dart`.  
Chaînes FR / AR : `lib/core/l10n/app_strings.dart` (préfixes `postCreate…`).

---

## Demandes d’aide (résumé)

- **Création** : `create_help_request_screen.dart`, route `/create-help-request`.
- **Liste triée** : `help_requests_screen.dart` ; **détail** : `help_request_detail_screen.dart`.
- **Raccourci volume** (Android) : sur l’onglet Aide, touche volume+ peut lancer une **aide rapide** avec position (`logic/quick_help_volume_action.dart`).
- **Vibrations** : `haptic_help_screen.dart` (`/haptic-help`).

**API** (extrait) : `POST /community/help-requests`, `GET /community/help-requests`, `PATCH …/accept`, etc.  
Priorisation, schéma MongoDB, règles métier : voir la doc détaillée **[README_AIDE.md](README_AIDE.md)**.

---

## Données & state (client)

| Élément | Emplacement |
|---------|-------------|
| Modèles | `lib/data/models/` — `post_model`, `comment_model`, `help_request_model`, `location_model`, `create_post_input`, … |
| API | `lib/data/api/endpoints.dart`, `CommunityRepository` |
| Providers | `lib/providers/community_providers.dart` |

Backend de référence : `backend/backend-m3ak 2` (NestJS), préfixes `/community` pour posts et demandes d’aide.

---

## Fichiers de doc dans ce dossier

| Fichier | Contenu |
|---------|---------|
| **README.md** (ce fichier) | Actualité communauté + aide — vue d’ensemble et liens. |
| **[README_AIDE.md](README_AIDE.md)** | Demandes d’aide géolocalisées : modèle, API, priorité, écrans Flutter. |

---

*Dernière mise à jour : alignée sur le module sous `lib/features/community/` (Flutter app Ma3ak).*
