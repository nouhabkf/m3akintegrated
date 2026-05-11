# Valeurs exactes (chaînes autorisées dans le code)

## Posts

Source backend : `backend/backend-m3ak 2/src/community/enums/post-inclusion.enum.ts`.

### `postNature`

- `signalement`
- `conseil`
- `temoignage`
- `information`
- `alerte`

### `targetAudience`

- `all`
- `motor`
- `visual`
- `hearing`
- `cognitive`
- `caregiver`

### `inputMode`

- `keyboard`
- `voice`
- `headEyes`
- `vibration`
- `deafBlind`
- `caregiver`

### `locationSharingMode`

- `none`
- `approximate`
- `precise`

### `dangerLevel`

Validé côté DTO (`CreatePostDto`) :

- `none`
- `low`
- `medium`
- `critical`

**Comportement Flutter** (`create_post_screen.dart`) : pour une nature `alerte`, l’app envoie en pratique **`medium`** ou **`critical`** (pas `none`/`low` depuis cet écran). Si la nature n’est pas `alerte`, `dangerLevel` n’est en général pas envoyé.

### `type` (post legacy, requis)

Aligné sur `POST_TYPE_VALUES` côté Nest et `PostType.toApiString()` côté Flutter (ex. `general`, `handicapMoteur`, `conseil`, `temoignage`, …). Voir `backend/.../enums/post-type.enum.ts` et `lib/data/models/post_model.dart` (`enum PostType`).

---

## Aide (demandes d’aide)

Source backend : `backend/backend-m3ak 2/src/community/enums/help-request-inclusion.enum.ts`.

### `helpType`

- `mobility`
- `orientation`
- `communication`
- `medical`
- `escort`
- `unsafe_access`
- `other`

### `inputMode`

- `text`
- `voice`
- `tap`
- `haptic`
- `volume_shortcut`
- `caregiver`

*(L’app envoie par ex. `volume_shortcut` depuis l’aide rapide volume : `quick_help_volume_action.dart`.)*

### `requesterProfile`

- `visual`
- `motor`
- `hearing`
- `cognitive`
- `caregiver`
- `unknown`

### `priority` (réponse / stockage — **pas** dans le body de création)

Valeurs calculées côté serveur (`HelpPriorityService` + tri Mongo) :

- `critical`
- `high`
- `medium`
- `low`

### `statut`

Stockage / API (chaînes) :

- `EN_ATTENTE` (défaut à la création)
- `EN_COURS`
- `TERMINEE`
- `ANNULEE`

Flutter : enum `HelpRequestStatus` → `toApiString()` dans `help_request_model.dart`.

### `presetMessageKey` (optionnel, création)

Clés reconnues par le message builder (`help-request-message-builder.constants.ts`) :

- `blocked`
- `lost`
- `cannot_reach`
- `medical_urgent`
- `escort`

*(L’UI peut combiner `helpType` + `presetMessageKey` selon `help_request_quick_preset.dart`.)*
