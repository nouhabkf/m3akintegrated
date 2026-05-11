# Demandes d’aide (communauté Ma3ak) — documentation détaillée

Ce document décrit **uniquement** la fonctionnalité **demande d’aide géolocalisée** : création, priorisation métier, liste triée, acceptation par un aidant, et interface Flutter associée.  
Code serveur de référence : `backend/backend-m3ak 2` (NestJS). Client : app Flutter sous `lib/features/community/` et `lib/data/`.

---

## 1. Rôle produit

- Un utilisateur **authentifié** peut **créer** une demande avec un **texte** + **coordonnées GPS**.
- Le serveur calcule :
  - un **score d’urgence textuel** (`urgencyScore`, 1–5) via le service « vision » / LLM (Ollama) ;
  - une **priorité métier** (`priority`, `priorityScore`, `priorityReason`, `prioritySignals`) via des **règles déterministes** (`HelpPriorityService`).
- La **liste** des demandes est renvoyée **triée** : niveau de priorité (critical → low), puis score numérique décroissant, puis date.
- Un autre membre peut **accepter** une demande encore en attente : statut passe à « en cours », points de confiance pour l’aidant, etc.

---

## 2. Modèle de données côté API (MongoDB)

Collection Mongoose : alignée sur la classe `HelpRequest` (`backend/.../community/schemas/help-request.schema.ts`).

| Champ | Type | Description |
|--------|------|-------------|
| `userId` | ObjectId → User | Auteur de la demande |
| `description` | string | Texte libre |
| `latitude` / `longitude` | number | Position |
| `statut` | string | `EN_ATTENTE`, `EN_COURS`, `TERMINEE`, `ANNULEE` (valeurs usuelles) |
| `acceptedBy` | ObjectId \| null | Aidant ayant accepté |
| `helperName` | string \| null | Nom affiché de l’aidant |
| `urgencyScore` | number | Score 1–5 (estimation **IA** sur le texte) |
| `priority` | string \| null | Niveau métier : `low` \| `medium` \| `high` \| `critical` |
| `priorityScore` | number \| null | Score agrégé **avant** seuils (règles) |
| `priorityReason` | string \| null | Phrase explicative en **français** |
| `prioritySignals` | string[] | Tags machine (`texte:...`, `contexte:...`, etc.) |
| `helpType` | string \| null | Optionnel : `mobility`, `orientation`, `communication`, `medical`, `escort`, `unsafe_access`, `other` |
| `inputMode` | string \| null | Optionnel : `text`, `voice`, `tap`, `haptic`, `volume_shortcut`, `caregiver` |
| `requesterProfile` | string \| null | Optionnel : `visual`, `motor`, `hearing`, `cognitive`, `caregiver`, `unknown` |
| `needsAudioGuidance` / `needsVisualSupport` / `needsPhysicalAssistance` / `needsSimpleLanguage` | bool \| null | Besoins déclarés |
| `isForAnotherPerson` | bool \| null | Demande pour un tiers |
| `presetMessageKey` | string \| null | Clé de message rapide (ex. `blocked`, `lost`) |
| `createdAt` / `updatedAt` | date | Timestamps |

La **description finale** peut être **générée côté serveur** à partir de ces options si le texte libre est absent ou trop court (`HelpRequestMessageBuilderService`). Voir le backend : `src/community/HELP_REQUEST_MESSAGE_BUILDER.md`.

Les anciennes fiches sans `priority` restent valides ; en liste, elles sont traitées comme priorité la plus basse pour le tri.

---

## 3. API REST (`/community`)

Base URL : celle configurée dans l’app (`AppConfig` / client Dio). Préfixe controller : **`/community`**.

### 3.1 Créer une demande

- **Méthode / chemin** : `POST /community/help-requests`
- **Auth** : **JWT obligatoire** (`Authorization: Bearer …`)
- **Corps JSON** :

```json
{
  "description": "string",
  "latitude": 36.8,
  "longitude": 10.18
}
```

- **Réponse** : document `HelpRequest` créé, incluant notamment `urgencyScore`, `priority`, `priorityScore`, `priorityReason`, `prioritySignals`.

### 3.2 Lister les demandes (pagination)

- **Méthode / chemin** : `GET /community/help-requests`
- **Auth** : **non** requise dans le controller actuel (liste publique côté route ; à durcir si besoin métier).
- **Query** : `page` (défaut 1), `limit` (défaut 20).
- **Réponse** :

```json
{
  "data": [ /* HelpRequest enrichi : userId souvent peuplé en objet User (sans password) */ ],
  "total": 0,
  "page": 1,
  "limit": 20,
  "totalPages": 0
}
```

**Ordre de tri côté serveur** :

1. Rang de priorité : `critical` > `high` > `medium` > `low` > (absent / ancien).
2. `priorityScore` décroissant (valeurs manquantes en dernier).
3. `createdAt` décroissant.

Implémentation : agrégation MongoDB (`community.service.ts` → pipeline `$addFields` + `$sort` + `$lookup` users + remplacement de `userId` par le document utilisateur).

### 3.3 Mettre à jour le statut

- **Méthode / chemin** : `POST /community/help-requests/:id/statut`
- **Auth** : JWT
- **Corps** : `{ "statut": "..." }`

### 3.4 Accepter une demande

- **Méthode / chemin** : `PATCH /community/help-requests/:id/accept`
- **Auth** : JWT
- **Corps** : `{}` (le serveur utilise l’utilisateur courant comme aidant et compose `helperName` à partir de `prenom` / `nom`).

---

## 4. Logique métier : `HelpPriorityService` (backend)

Fichiers principaux : `src/help-priority/`

- `help-priority.text.ts` — normalisation du texte (`toLowerCase`, `trim`).
- `help-priority.scoring-rules.ts` — règles (mots-clés, contexte, attente, nuit, profils).
- `help-priority.french-reason.ts` — phrase française de synthèse.
- `help-priority.constants.ts` — listes de mots-clés et poids.
- `help-priority.service.ts` — orchestration : `computePriority(input)`.

### 4.1 Entrée (`HelpPriorityInput`)

Champs utilisés à la **création** depuis `CommunityService` :

- `text` : la `description` ;
- `hasAcceptedHelper: false` ;
- `waitingMinutes: 0` ;
- `hour` : heure **serveur** (`new Date().getHours()`) ;
- `userProfile` : dérivé du rôle + `typeHandicap` (ex. moteur → `motor`, visuel → `visual`, accompagnant → `caregiver`).

Les champs optionnels `hasNearbyObstacle`, `isAlone` peuvent être branchés plus tard si l’API les expose.

### 4.2 Score et signaux (résumé)

- **Mots-clés** (texte normalisé) : groupes *urgent* / *modéré* / *faible urgence* avec scores fixes (voir constantes).
- **Contexte** : obstacle proche, seul, pas d’aidant accepté, attente ≥ 15 ou ≥ 30 minutes, fenêtre **nuit** (21h–6h, heure locale entière).
- **Profils** : bonus si le texte contient des indices compatibles (ex. moteur + accès / rampe ; visuel + perte de repères).

Les **signaux** sont des chaînes stables du type `texte:mots_urgents(...)`, `contexte:seul`, etc., pour la traçabilité et la phrase FR.

### 4.3 Conversion score → niveau

Seuils inclusifs sur le score total (voir `LOW_MAX`, `MEDIUM_MAX`, `HIGH_MAX` dans `help-priority.constants.ts`) :

- `≤ 2` → `low`
- `≤ 5` → `medium`
- `≤ 8` → `high`
- `> 8` → `critical`

### 4.4 Urgence « IA » vs priorité métier

- **`urgencyScore`** : produit par `CommunityVisionService.getUrgencyScore(description)` (échelle 1–5, autre pipeline).
- **`priority` / `priorityScore`** : entièrement **règles métier** ; les deux coexistent sur le même document.

### 4.5 Extension future (ML)

- Interface `HelpPriorityMlContributor` dans `help-priority.types.ts` : permet d’envisager un complément de score / signaux fusionné avec l’évaluation par règles.

---

## 5. Côté Flutter

### 5.1 Fichiers clés

| Fichier | Rôle |
|---------|------|
| `lib/data/models/help_request_model.dart` | Modèle + `fromJson` (`priority`, `priorityScore`, `priorityReason`, `prioritySignals`) |
| `lib/data/repositories/community_repository.dart` | `createHelpRequest`, `getHelpRequests`, `updateHelpRequestStatus`, `acceptHelpRequest` |
| `lib/data/api/endpoints.dart` | `communityHelpRequests`, `communityHelpRequestStatut`, `communityHelpRequestAccept` |
| `lib/providers/community_providers.dart` | `helpRequestsProvider`, `createHelpRequestProvider`, etc. |
| `lib/features/community/screens/help_requests_screen.dart` | Liste, pagination, accepter, navigation détail |
| `lib/features/community/screens/create_help_request_screen.dart` | Saisie + envoi |
| `lib/features/community/screens/help_request_detail_screen.dart` | Détail, badge priorité, `priorityReason`, accepter |
| `lib/features/community/widgets/help_request_priority_badge.dart` | Badge accessible (texte + icône + bordure) |
| `lib/core/l10n/app_strings.dart` | Libellés priorité (FR/AR), titres écrans |
| `lib/router/app_router.dart` | `/help-requests`, `/create-help-request`, `/help-request-detail` (extra : `HelpRequestModel`) |

### 5.2 Affichage priorité

- Mapping API → libellés affichés (ex. `critical` → **CRITIQUE**, `high` → **URGENT**, etc.) via `AppStrings.helpRequestPriorityLabel`.
- Liste : badge compact sous l’en-tête de carte ; repli sur l’ancien indicateur « Urgent (score IA) » si `priority` absent.
- Détail : badge large, bloc optionnel **Justification de la priorité** si `priorityReason` non vide.

### 5.3 Accessibilité (UI)

- Badges : **texte lisible**, **bordure**, **icône** — pas de signification par la couleur seule.
- `Semantics` pour annoncer « Priorité : … ».

### 5.4 Raccourcis liés à l’aide (hors écran liste strict)

- `logic/quick_help_volume_action.dart` — raccourci volume (Android) vers création rapide de demande.
- `screens/haptic_help_screen.dart` — parcours SOS / haptique (lié au module Aide, pas à la liste HTTP seule).

---

## 6. Parcours de navigation (GoRouter)

- `/help-requests` — liste.
- `/create-help-request` — création.
- `/help-request-detail` — détail ; le `HelpRequestModel` est passé en **`extra`** (pas d’endpoint `GET /help-requests/:id` dédié dans les endpoints listés ci-dessus).

---

## 7. Points d’attention pour la maintenance

1. **Cohérence tri** : toute évolution des valeurs de `priority` doit rester alignée avec le `$switch` Mongo (rangs 4→1) et l’UI.
2. **Heure** : la fenêtre nocturne utilise l’heure du **serveur** à la création ; pour une cohérence fuseau utilisateur, il faudrait passer l’heure ou le fuseau côté client.
3. **Liste sans auth** : vérifier si la politique de sécurité doit exiger JWT sur `GET /community/help-requests`.
4. **Tests** : le module priorité dispose de `help-priority.service.spec.ts` ; lancer les tests si le script npm `test` est ajouté au projet.

---

## 8. Références rapides Swagger

Avec l’API Nest + Swagger activé : modèles `HelpRequest`, `HelpRequestsPaginatedDto` pour les réponses documentées des routes help-requests du `CommunityController`.

---

*Document généré pour faciliter l’onboarding et la maintenance du périmètre « demandes d’aide » uniquement.*
