# Modèles Flutter — chemins et rôle

Racine package : `lib/` (sous `frontend/appm3ak/appm3ak/`).

## `CreatePostInput`

**Fichier :** `lib/data/models/create_post_input.dart`

Paramètres pour `POST /community/posts` (multipart). Champs :

| Champ | Type | Note |
|-------|------|------|
| `contenu` | `String` | requis |
| `type` | `String` | API legacy (`PostType.toApiString()`) |
| `images` | `List<XFile>?` | optionnel |
| `latitude` / `longitude` | `double?` | optionnel |
| `dangerLevel` | `String?` | optionnel |
| `postNature` | `String?` | optionnel |
| `targetAudience` | `String?` | optionnel |
| `inputMode` | `String?` | optionnel |
| `isForAnotherPerson` | `bool?` | optionnel |
| `needsAudioGuidance` | `bool?` | optionnel |
| `needsVisualSupport` | `bool?` | optionnel |
| `needsPhysicalAssistance` | `bool?` | optionnel |
| `needsSimpleLanguage` | `bool?` | optionnel |
| `locationSharingMode` | `String?` | optionnel |

Factory : `CreatePostInput.legacy(...)` (sans champs inclusifs).

## `PostModel`

**Fichier :** `lib/data/models/post_model.dart`

- Enum **`PostType`** : `general`, `handicapMoteur`, `handicapVisuel`, `handicapAuditif`, `handicapCognitif`, `conseil`, `temoignage`, `autre` — `toApiString()` = nom de l’enum (camelCase).
- Champs inclusifs optionnels : `postNature`, `targetAudience`, `inputMode`, `isForAnotherPerson`, besoins booléens, `locationSharingMode` (tous `String?` ou `bool?` selon le champ).

## `CreateHelpRequestInput`

**Fichier :** `lib/data/models/create_help_request_input.dart`

| Champ | Type | Commentaire dans le code |
|-------|------|---------------------------|
| `description` | `String?` | peut être vide si le serveur génère |
| `latitude` / `longitude` | `double` | requis |
| `helpType` | `String?` | voir `valeurs_exactes.md` |
| `inputMode` | `String?` | idem |
| `requesterProfile` | `String?` | idem |
| besoins | `bool?` × 4 | idem posts |
| `isForAnotherPerson` | `bool?` | |
| `presetMessageKey` | `String?` | commentaire fichier : `blocked` \| `lost` \| … |

Factory : `CreateHelpRequestInput.legacy(description, latitude, longitude)`.

## `HelpRequestModel`

**Fichier :** `lib/data/models/help_request_model.dart`

- Enum **`HelpRequestStatus`** → API : `EN_ATTENTE`, `EN_COURS`, `TERMINEE`, `ANNULEE`.
- Champs : `description`, `latitude`, `longitude`, `statut`, `urgencyScore`, `priority`, `priorityScore`, `priorityReason`, `prioritySignals`, `helpType`, `inputMode`, `requesterProfile`, besoins, `isForAnotherPerson`, `presetMessageKey`, `acceptedBy`, `helperName`, `user`, dates.

## Fichiers liés (presets aide)

- `lib/features/community/models/help_request_quick_preset.dart` — mapping scénarios UI → `helpType` / `presetMessageKey` / `requesterProfile`.
