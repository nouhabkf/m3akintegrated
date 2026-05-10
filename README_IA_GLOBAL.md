# README IA global (Flutter + Nest + Python)

Ce document est la reference centrale pour tout ce qui concerne l'IA du module communaute dans ce repo.
Il est ecrit pour preparer une grande refonte en evitant les regressions.

---

## 1) Perimetre IA dans ce projet

L'IA actuelle couvre surtout:

- entree intelligente communaute (`CommunityAiEntryScreen`)
- classification d'intention (post / help / route suggeree)
- pre-remplissage des formulaires `CreatePost` / `CreateHelpRequest`
- navigation automatique conditionnee par confiance + regles locales

L'IA n'est pas un LLM externe direct cote Flutter. Flutter parle a Nest, Nest proxy vers FastAPI Python.

---

## 2) Architecture bout-en-bout

1. **Flutter**
   - Ecran d'entree IA: `frontend/appm3ak/appm3ak/lib/features/community/screens/community_ai_entry_screen.dart`
   - Appel repository vers endpoint Nest: `POST /community/ai/action-plan`

2. **NestJS (backend)**
   - Controller: `backend/backend-m3ak 2/src/community/community.controller.ts`
   - Service proxy IA: `backend/backend-m3ak 2/src/community/community.service.ts` (`analyzeCommunityAction`)
   - Nest appelle Python: `POST {AI_COMMUNITY_BASE_URL}/ai/community/action-plan`

3. **Python FastAPI**
   - API: `ai/src/app.py`
   - Inference/regles: `ai/src/predict.py`
   - Modele: `ai/models/community_action_planner.joblib`
   - Dataset: `ai/data/community_action_dataset.csv`

---

## 3) Endpoints et contrats

## Flutter -> Nest

- Endpoint: `/community/ai/action-plan`
- Fichier endpoint: `frontend/appm3ak/appm3ak/lib/data/api/endpoints.dart`
- Repository: `frontend/appm3ak/appm3ak/lib/data/repositories/community_repository.dart`
- Provider: `frontend/appm3ak/appm3ak/lib/providers/community_providers.dart`

Payload principal (DTO Nest):

- `text` (obligatoire)
- `contextHint`: `post | help | community` (optionnel)
- `inputModeHint`: `keyboard | voice | headEyes | vibration | deafBlind | caregiver | text | tap | haptic | volume_shortcut` (optionnel)
- `isForAnotherPersonHint` (optionnel)

DTO: `backend/backend-m3ak 2/src/community/dto/community-action-plan-request.dto.ts`

## Nest -> Python

Dans `CommunityService.analyzeCommunityAction`:

- base URL: `AI_COMMUNITY_BASE_URL` (defaut `http://127.0.0.1:8000`)
- timeout: `AI_COMMUNITY_TIMEOUT_MS` (defaut `10000`)
- route Python: `/ai/community/action-plan`

Si Python est indisponible, Nest renvoie `503 ServiceUnavailableException`.

---

## 4) Flux UX IA actuel (etat reel)

Fichier source principal: `community_ai_entry_screen.dart`

Comportements:

- UX voice-first immersive (orb central + gradient + waveform)
- analyse vocale automatique a la fin de la dictee (finalResult STT)
- clavier minimal:
  - saisie texte
  - validation via touche `Done` ou icone `send`
- bouton "Analyser" classique retire
- bouton "Parler" classique retire (interaction sur orb)

Regles avant appel IA (routage local prioritaire):

- "dernier post" -> ouverture dernier post
- "aide rapide / fisa / ani dhay3a ..." -> SOS tactile
- "non voyant ..." -> route voice-vibration
- "poster photo / nhabet taswira ..." -> parcours photo adapte

Sinon: appel IA backend, puis navigation selon:

- `recommendedRoute`
- confiance / heuristiques
- fallback par intention locale (`publish/help/location`)

---

## 5) Fichiers critiques par couche

## Flutter

- `frontend/appm3ak/appm3ak/lib/features/community/screens/community_ai_entry_screen.dart`
- `frontend/appm3ak/appm3ak/lib/data/models/community_action_plan_result.dart`
- `frontend/appm3ak/appm3ak/lib/features/community/screens/create_post_screen.dart`
- `frontend/appm3ak/appm3ak/lib/features/community/screens/create_help_request_screen.dart`
- `frontend/appm3ak/appm3ak/lib/router/app_router.dart`
- `frontend/appm3ak/appm3ak/lib/features/accessibility/voice_vibration_post_screen.dart`
- `frontend/appm3ak/appm3ak/lib/features/accessibility/head_gesture_post_screen.dart`

## Backend Nest

- `backend/backend-m3ak 2/src/community/community.controller.ts`
- `backend/backend-m3ak 2/src/community/community.service.ts`
- `backend/backend-m3ak 2/src/community/dto/community-action-plan-request.dto.ts`
- `backend/backend-m3ak 2/src/community/dto/community-action-plan-response.dto.ts`
- `backend/backend-m3ak 2/.env`

## Python IA

- `ai/src/app.py`
- `ai/src/predict.py`
- `ai/src/labels.py`
- `ai/src/train_model.py`
- `ai/src/validate_dataset.py`
- `ai/models/community_action_planner.joblib`
- `ai/data/community_action_dataset.csv`

---

## 6) Commandes dev minimales

## Python IA

```powershell
cd "C:\Users\DELL\Downloads\appm3ak\ai"
.\.venv\Scripts\activate
uvicorn src.app:app --reload --host 127.0.0.1 --port 8000
```

## Nest

```powershell
cd "C:\Users\DELL\Downloads\appm3ak\backend\backend-m3ak 2"
npm run start:dev
```

## Checks rapides

```powershell
curl.exe -s -o NUL -w "nest:%{http_code}`n" http://127.0.0.1:3000/community/posts
curl.exe -s -o NUL -w "ai:%{http_code}`n" http://127.0.0.1:8000/health
```

---

## 7) Erreurs frequentes et cause racine

## Message: "Le serveur repond mais le service IA est indisponible"

Ca signifie en pratique:

- Nest est joignable
- mais Nest n'arrive pas a joindre Python (`AI_COMMUNITY_BASE_URL` faux ou service down)

A verifier:

- `ai` tourne bien sur `127.0.0.1:8000`
- `.env` backend: `AI_COMMUNITY_BASE_URL=http://127.0.0.1:8000`
- Nest redemarre apres changement `.env`

## "Done clavier n'ouvre pas"

Sur certains claviers Android, `Done` est inconsistant.
Le fallback actuel est l'icone `send` dans le champ texte.

---

## 8) Si tu fais une "grande modification" (plan conseille)

Ordre recommande:

1. **Figer le contrat API**
   - stabiliser request/response DTO Nest + model Flutter
2. **Refactor Python**
   - garder route `/ai/community/action-plan` compatible temporairement
3. **Refactor Nest proxy**
   - ajouter logs clairs + gestion timeout + fallback propre
4. **Refactor UI Flutter**
   - separer clairement:
     - regles locales deterministes
     - appel IA
     - decision navigation
5. **Ajouter tests de non-regression**
   - phrases critiques: `dernier post`, `aide rapide`, `non voyant`, `nhabet taswira`

---

## 9) Invariants a ne pas casser

- route Flutter d'entree IA: `/community-ai-entry`
- route backend: `POST /community/ai/action-plan`
- route Python: `POST /ai/community/action-plan`
- reponse doit rester compatible avec `CommunityActionPlanResult` Flutter
- navigation `recommendedRoute + extra` doit continuer a fonctionner

---

## 10) Docs existantes deja utiles

- IA Python detaillee: `ai/README_AI.md`
- Flux ecran d'entree IA: `frontend/appm3ak/appm3ak/lib/features/community/README_AI_ENTRY_FLOW.md`

Ce fichier `README_IA_GLOBAL.md` est volontairement operationnel et oriente refonte.
