# HelpRequestMessageBuilderService — utilisation

## Rôle

`HelpRequestMessageBuilderService` produit la **chaîne `description`** stockée en base à partir de :

- texte libre optionnel (`description`) ;
- type de besoin (`helpType`), mode de saisie (`inputMode`), profil (`requesterProfile`) ;
- drapeaux d’accessibilité (`needsAudioGuidance`, etc.) ;
- tiers (`isForAnotherPerson`) ou profil `caregiver` ;
- clé de préréglage (`presetMessageKey`).

## Où l’appeler

Dans le flux **`POST /community/help-requests`**, **avant** :

1. `CommunityVisionService.getUrgencyScore(...)` (score IA sur le texte final) ;
2. `HelpPriorityService.computePriority({ text: ... })` (priorité métier) ;
3. `helpRequestModel.create({ description: finalDescription, ... })`.

C’est déjà branché dans `CommunityService.createHelpRequest`.

## Règles principales

1. Si `description` est **non vide** et atteint la longueur minimale (`MEANINGFUL_DESCRIPTION_MIN_LENGTH`), elle est **conservée telle quelle**.
2. Sinon, génération à partir des préréglages (`help-request-message-builder.constants.ts`), du `helpType`, du `requesterProfile`, et des besoins.
3. `isForAnotherPerson === true` **ou** `requesterProfile === 'caregiver'` → formulations **tiers / accompagnant**.
4. Les besoins booléens sont ajoutés en **suffixes** courts en français.

## Extension

Pour de nouveaux préréglages, ajouter une entrée dans `HELP_REQUEST_PRESET_MESSAGES_FR` et, si besoin, une branche dans `tryPreset()` ou `refineWithProfile()`.
