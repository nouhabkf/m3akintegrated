# IA dans le module Communauté (Ma3ak)

Ce document résume **toutes les briques « IA » ou intelligentes** liées à la communauté : où elles tournent, comment elles communiquent, et quels fichiers lire en priorité.

Pour le détail technique bout-en-bout (contrats API, invariants), voir aussi [`README_IA_GLOBAL.md`](README_IA_GLOBAL.md).  
Pour le modèle ML actuel (dataset, entraînement, limites), voir [`README_MODELE_IA_ACTUELLE.md`](README_MODELE_IA_ACTUELLE.md).

---

## 1) Vue d’ensemble : ce n’est pas « une seule IA »

Dans la communauté, on combine :

| Brique | Rôle | Où ça tourne |
|--------|------|----------------|
| **Règles locales Flutter** | Phrases fixes (ex. obstacle, aide rapide, dernier post) → navigation **sans** appeler le serveur ML | Téléphone |
| **Plan d’action IA (classifieur)** | À partir du texte (souvent STT), propose une action + route + champs pour pré-remplir les écrans | Service **Python** local (FastAPI), appelé via **Nest** |
| **Tête / yeux + caméra** | Navigation par visage (ML Kit) : **pas** le même pipeline que le classifieur Python | Téléphone (Android / iOS), **pas** le web |
| **Vision / audio image / FALC** (si backend configuré) | Description d’image, simplification de texte, etc. | **Nest** + services configurés (ex. Ollama / clés selon `.env`) |

---

## 2) Flux principal « entrée IA communauté »

1. L’utilisateur est sur **`CommunityAiEntryScreen`** (`frontend/appm3ak/appm3ak/lib/features/community/screens/community_ai_entry_screen.dart`).
2. **D’abord**, des règles **locales** peuvent court-circuiter l’appel réseau (phrases reconnues).
3. Sinon, Flutter appelle Nest : **`POST /community/ai/action-plan`**.
4. Nest proxifie vers Python : **`POST {AI_COMMUNITY_BASE_URL}/ai/community/action-plan`** (par défaut `http://127.0.0.1:8000`).
5. La réponse guide la navigation (`recommendedRoute`, confiance, champs extra).

Fichiers utiles côté app :

- Écran : `community_ai_entry_screen.dart`
- Endpoint : `frontend/appm3ak/appm3ak/lib/data/api/endpoints.dart` → `communityAiActionPlan`
- Appel HTTP : `frontend/appm3ak/appm3ak/lib/data/repositories/community_repository.dart`
- Modèle réponse : `frontend/appm3ak/appm3ak/lib/data/models/community_action_plan_result.dart`

Côté serveur :

- Nest : `backend/backend-m3ak 2/src/community/community.controller.ts`, `community.service.ts`
- DTO : `community-action-plan-request.dto.ts`, `community-action-plan-response.dto.ts`

---

## 3) Service Python (modèle + dataset)

| Élément | Chemin |
|--------|--------|
| API FastAPI | `ai/src/app.py` |
| Inférence + règles | `ai/src/predict.py` |
| Labels | `ai/src/labels.py` |
| Entraînement | `ai/src/train_model.py` |
| Validation données | `ai/src/validate_dataset.py` |
| **Dataset** | `ai/data/community_action_dataset.csv` |
| **Modèle exporté** | `ai/models/community_action_planner.joblib` |

Type de modèle (résumé) : vectorisation texte (TF‑IDF) + forêt aléatoire multi-sorties — voir [`README_MODELE_IA_ACTUELLE.md`](README_MODELE_IA_ACTUELLE.md).

**Local par défaut** : le téléphone ne charge pas le `.joblib` ; c’est le service Python sur la machine (ou un serveur dont l’URL est dans `AI_COMMUNITY_BASE_URL`) qui fait l’inférence.

---

## 4) Variables d’environnement importantes (Nest)

À configurer dans le `.env` du backend (ne pas committer les secrets) :

- `AI_COMMUNITY_BASE_URL` — URL du service Python (souvent `http://127.0.0.1:8000` en dev)
- `AI_COMMUNITY_TIMEOUT_MS` — timeout de l’appel proxy

Si Python est arrêté ou l’URL est fausse, l’app peut recevoir une erreur du type **service IA indisponible** (Nest ne joint pas FastAPI).

Les options **Ollama / Gemini / etc.** pour vision et FALC sont documentées côté backend (fichiers `.env.example` et docs dans `backend/backend-m3ak 2/`).

---

## 5) Autres routes « IA » côté communauté (optionnelles)

Déclarées dans `endpoints.dart` (à brancher ou compléter côté Nest selon votre version) :

- `/ai/community/summarize-post`
- `/ai/community/summarize-comments`
- `/ai/community/post-to-help-request`

L’usage réel dépend des implémentations présentes dans votre branche du backend.

---

## 6) Tête / yeux (caméra) — à ne pas confondre avec le classifieur

- Utilise **`google_mlkit_face_detection`** + **`camera`** sur l’appareil.
- **Pas** le même service que `community_action_planner.joblib`.
- **Web** : le mode caméra tête/yeux n’est pas supporté dans ce flux (message d’information à l’utilisateur).

---

## 7) Démarrage rapide dev (ordre conseillé)

1. Lancer Python IA (depuis `ai/`) — voir commandes dans [`README_IA_GLOBAL.md`](README_IA_GLOBAL.md) section 6.
2. Lancer Nest (`backend/backend-m3ak 2`) avec `AI_COMMUNITY_BASE_URL` correct.
3. Lancer Flutter (`frontend/appm3ak/appm3ak`) avec `API_BASE_URL` pointant vers Nest.

Vérifications rapides (même fichier `README_IA_GLOBAL.md`, section « Checks rapides ») : codes HTTP sur `/community/posts` et `/health` côté Python.

---

## 8) Documents complémentaires déjà dans le dépôt

| Fichier | Contenu |
|---------|---------|
| [`README_IA_GLOBAL.md`](README_IA_GLOBAL.md) | Architecture complète, endpoints, erreurs fréquentes, invariants |
| [`README_MODELE_IA_ACTUELLE.md`](README_MODELE_IA_ACTUELLE.md) | Dataset, pipeline ML, commandes train/predict |
| [`FONCTIONNALITES_ACCES_COMMUNAUTE.md`](FONCTIONNALITES_ACCES_COMMUNAUTE.md) | Pointers fichiers smart filter, vision, TTS, FALC, trust |
| [`frontend/.../features/community/README_AI_ENTRY_FLOW.md`](frontend/appm3ak/appm3ak/lib/features/community/README_AI_ENTRY_FLOW.md) | Flux écran d’entrée IA (si présent) |

---

*Ce README est l’entrée « produit + dev » pour l’IA communauté ; le détail contractuel reste dans `README_IA_GLOBAL.md`.*
