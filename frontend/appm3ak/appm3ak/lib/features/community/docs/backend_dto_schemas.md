# Backend Nest — DTO et schémas

Racine : `backend/backend-m3ak 2/src/community/`.

## Enums (valeurs)

| Fichier | Contenu |
|---------|---------|
| `enums/post-inclusion.enum.ts` | `POST_NATURE_VALUES`, `POST_TARGET_AUDIENCE_VALUES`, `POST_INPUT_MODE_VALUES`, `POST_LOCATION_SHARING_MODE_VALUES` |
| `enums/post-type.enum.ts` | `POST_TYPE_VALUES` (types de post legacy) |
| `enums/help-request-inclusion.enum.ts` | `HELP_REQUEST_HELP_TYPES`, `HELP_REQUEST_INPUT_MODES`, `HELP_REQUEST_REQUESTER_PROFILES` |

## DTO de création

| Fichier | Usage |
|---------|--------|
| `dto/create-post.dto.ts` | **`CreatePostDto`** — `contenu`, `type`, `latitude`, `longitude`, `dangerLevel`, champs inclusifs posts (bool multipart via `parseOptionalBool`) |
| `dto/create-help-request.dto.ts` | **`CreateHelpRequestDto`** — `description?`, `latitude`, `longitude`, `helpType?`, `inputMode?`, `requesterProfile?`, besoins booléens, `isForAnotherPerson?`, `presetMessageKey?` |

### `dangerLevel` (post)

Constante dans `create-post.dto.ts` :

```ts
const DANGER_LEVELS = ['none', 'low', 'medium', 'critical'] as const;
```

## Schémas Mongoose

| Fichier | Classe |
|---------|--------|
| `schemas/post.schema.ts` | **`Post`** — `contenu`, `type`, `images`, `latitude`, `longitude`, `dangerLevel`, validation obstacle, `merciCount`, champs inclusifs (`postNature`, `targetAudience`, `inputMode`, …), `locationSharingMode` |
| `schemas/help-request.schema.ts` | **`HelpRequest`** — `description`, `latitude`, `longitude`, `statut` (défaut `EN_ATTENTE`), `acceptedBy`, `helperName`, `urgencyScore`, `priority`, `priorityScore`, `priorityReason`, `prioritySignals`, `helpType`, `inputMode`, `requesterProfile`, besoins, `isForAnotherPerson`, `presetMessageKey` |

## Messages prédéfinis aide

| Fichier | Rôle |
|---------|------|
| `help-request-message-builder.constants.ts` | `HELP_REQUEST_PRESET_MESSAGES_FR` (clés `blocked`, `lost`, `cannot_reach`, `medical_urgent`, `escort`) |
| `help-request-message-builder.service.ts` | Génération / enrichissement de la `description` |

## Contrôleur

| Méthode HTTP | Chemin (préfixe `/community`) | Body |
|--------------|-------------------------------|------|
| POST | `posts` | `CreatePostDto` (multipart) |
| POST | `help-requests` | `CreateHelpRequestDto` (JSON) |

*(Préfixe exact selon `community.controller.ts` + `main.ts`.)*
