# API — méthodes repository et corps envoyés

**Fichier repository :** `lib/data/repositories/community_repository.dart`  
**Endpoints :** `lib/data/api/endpoints.dart` (ex. `communityPosts`, `communityHelpRequests`).

---

## Créer un post

- **Méthode HTTP :** `POST`
- **Content-Type :** `multipart/form-data` (Dio `FormData`)
- **Méthode Dart :** `CommunityRepository.createPost(CreatePostInput input)`

### Champs texte (toujours)

| Clé form | Valeur |
|----------|--------|
| `contenu` | `input.contenu` |
| `type` | `input.type` |

### Champs optionnels (si non null)

| Clé | Condition |
|-----|-----------|
| `latitude` | `input.latitude != null` → stringifié |
| `longitude` | idem |
| `dangerLevel` | non vide |
| `postNature` | `putIfNonNull` |
| `targetAudience` | idem |
| `inputMode` | idem |
| `isForAnotherPerson` | `"true"` ou `"false"` |
| `needsAudioGuidance` | idem |
| `needsVisualSupport` | idem |
| `needsPhysicalAssistance` | idem |
| `needsSimpleLanguage` | idem |
| `locationSharingMode` | string |

### Fichiers

- Clé répétée : **`images`** — un `MultipartFile` par image (`fromFile` ou `fromBytes` sur le web).

### Exemple conceptuel (multipart)

Pas un JSON unique : paires champs + une ou plusieurs parties `images`.

---

## Créer une demande d’aide

- **Méthode HTTP :** `POST`
- **Content-Type :** `application/json`
- **Méthode Dart :** `CommunityRepository.createHelpRequest(CreateHelpRequestInput input)`

### Corps minimal (toujours présent)

```json
{
  "latitude": 36.8065,
  "longitude": 10.1815
}
```

### Champs optionnels ajoutés si non null

- `description` (si trim non vide)
- `helpType`
- `inputMode`
- `requesterProfile`
- `needsAudioGuidance`
- `needsVisualSupport`
- `needsPhysicalAssistance`
- `needsSimpleLanguage`
- `isForAnotherPerson`
- `presetMessageKey`

### Exemple JSON complet (tous les optionnels renseignés)

```json
{
  "latitude": 36.8065,
  "longitude": 10.1815,
  "description": "texte libre",
  "helpType": "mobility",
  "inputMode": "text",
  "requesterProfile": "motor",
  "needsAudioGuidance": true,
  "needsVisualSupport": true,
  "needsPhysicalAssistance": true,
  "needsSimpleLanguage": true,
  "isForAnotherPerson": true,
  "presetMessageKey": "blocked"
}
```

### Champs **non** envoyés à la création

- `priority`, `priorityScore`, `priorityReason`, `prioritySignals` — calculés côté serveur après création.
- `statut` — défini par le serveur (`EN_ATTENTE`).

---

## Autres appels utiles (même repository)

- `updateHelpRequestStatus` → `POST` …/statut avec `{"statut": "<string>"}` (valeurs `EN_ATTENTE`, etc. selon usage).
- `acceptHelpRequest` → `PATCH` …/accept avec `{}`.
