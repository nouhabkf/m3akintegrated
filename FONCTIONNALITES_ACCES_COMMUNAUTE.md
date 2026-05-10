# Ma3ak — Fichiers du travail (smart filter, vision, TTS, FALC, trust)

Racine dépôt : `C:\Users\DELL\Downloads\appm3ak`  
Flutter (code à jour) : `frontend\appm3ak\appm3ak`  
Backend : `backend\backend-m3ak 2`

---

## 1. Filtre smart (profil HANDICAPE + `typeHandicap`)

| Rôle | Fichier |
|------|---------|
| API liste filtrée | `backend\backend-m3ak 2\src\community\community.service.ts` → `getPostsForViewerProfile` |
| Route JWT | `backend\backend-m3ak 2\src\community\community.controller.ts` → `GET posts/for-me` |
| Logique types de posts | `backend\backend-m3ak 2\src\community\enums\type-handicap.enum.ts` |
| Provider + appel API | `frontend\appm3ak\appm3ak\lib\providers\community_providers.dart` → `communityFeedProvider` |
| Chip « Smart (mon profil) » + liste | `frontend\appm3ak\appm3ak\lib\features\community\screens\community_posts_screen.dart` |
| Enum / mapping côté UI | `frontend\appm3ak\appm3ak\lib\core\enums\type_handicap.dart` |
| Repository | `frontend\appm3ak\appm3ak\lib\data\repositories\community_repository.dart` → `getPostsForMe` |
| Endpoints | `frontend\appm3ak\appm3ak\lib\data\api\endpoints.dart` → `communityPostsForMe` |

---

## 2. Vision (LLaVA / Ollama) — description d’image réelle

| Rôle | Fichier |
|------|---------|
| Lecture fichier + appel multimodal | `backend\backend-m3ak 2\src\accessibility\accessibility.service.ts` → `generateImageAudioDescription`, `analyzeImageWithOllamaVision`, `parseVisionOutput` |
| Chemin disque uploads | `backend\backend-m3ak 2\src\common\upload-paths.ts` |
| Route protégée (profil visuel) | `backend\backend-m3ak 2\src\community\community.controller.ts` → `GET posts/:postId/images/:imageIndex/audio-description` |
| Service qui appelle l’accessibilité | `backend\backend-m3ak 2\src\community\community.service.ts` → `getPostImageAudioDescription` |
| Appel HTTP + modèle | `frontend\appm3ak\appm3ak\lib\data\repositories\community_repository.dart` → `getPostImageAccessibilityDescription` |
| Modèle JSON | `frontend\appm3ak\appm3ak\lib\data\models\image_vision_description_model.dart` |
| Doc `.env` / Ollama | `backend\backend-m3ak 2\.env.example`, `docs\COMMUNAUTE_IA_SANS_FRAIS_FR.md` |

---

## 3. TTS (Text-to-Speech) — détail d’un post

| Rôle | Fichier |
|------|---------|
| `FlutterTts`, init, `speak`, dialogue | `frontend\appm3ak\appm3ak\lib\features\community\screens\post_detail_screen.dart` |
| Affichage bouton si profil visuel | même fichier → `isVisualHandicapProfile` + bouton description image |
| Dépendance | `frontend\appm3ak\appm3ak\pubspec.yaml` → `flutter_tts` |

---

## 4. FALC / simplification de texte (prompt cognitif)

| Rôle | Fichier |
|------|---------|
| Prompt FALC + Ollama | `backend\backend-m3ak 2\src\accessibility\accessibility.service.ts` → `buildFalcSystemPrompt`, `simplifyWithOllama` |
| Bouton « version simplifiée » (post) | `frontend\appm3ak\appm3ak\lib\features\community\screens\post_detail_screen.dart` → `_readSimplified` |

---

## 5. Trust points & badges « helper »

| Rôle | Fichier |
|------|---------|
| Schéma + incrément | `backend\backend-m3ak 2\src\user\schemas\user.schema.ts` → `trustPoints` |
| `addTrustPoints` | `backend\backend-m3ak 2\src\user\user.service.ts` |
| +2 commentaire, +10 accept aide | `backend\backend-m3ak 2\src\community\community.service.ts` |
| Modèle user Flutter | `frontend\appm3ak\appm3ak\lib\data\models\user_model.dart` |
| Widget badge Bronze/Argent/Or | `frontend\appm3ak\appm3ak\lib\widgets\verified_helper_badge.dart` |
| Affichage cartes / commentaires | `community_posts_screen.dart`, `post_detail_screen.dart` |
| Refresh après aide | `frontend\appm3ak\appm3ak\lib\features\community\screens\help_requests_screen.dart` |

---

## 6. Récap API utile

- `GET /community/posts/for-me` — smart filter (JWT)  
- `GET /community/posts/:postId/images/:index/audio-description` — vision + texte (JWT, handicap visuel)  
- `POST /accessibility/simplify-text` — FALC  

---

*Pour lancer le projet : voir `PROJET_UNIFIE.txt` et les scripts dans `scripts\`.*
