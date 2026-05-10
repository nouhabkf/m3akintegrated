# IA communauté — Community Action Planner (état actuel)

Ce dossier `ai/` héberge le service **Community Action Planner** : à partir d’un **texte libre** utilisateur, il propose un **plan d’action** compatible avec l’app Ma3ak : soit **créer un post** (`create_post`), soit **créer une demande d’aide** (`create_help_request`), avec des champs structurés (nature du post, public cible, besoins inclusifs, etc.).

---

## 1. Rôle produit

- **Entrée** : phrase ou courte description (écran « Assistant intelligent » communauté, boutons « Analyser avec IA » sur les formulaires).
- **Sortie** : JSON consommé par Flutter pour **préremplir** les écrans « Créer un post » / « Demande d’aide », plus une **route Flutter** suggérée (`recommendedRoute`) et un **niveau de confiance** pour la navigation automatique côté UI.

L’IA **ne vérifie pas** le profil utilisateur au sens compte / identité : elle **classifie le texte** et déduit des **labels** paramétrables (audience, type d’aide, modes de saisie, etc.).

---

## 2. Architecture dans le projet

| Couche | Rôle |
|--------|------|
| **Flutter** | Appelle `POST /community/ai/action-plan` sur l’API Nest (`Endpoints.communityAiActionPlan`). |
| **NestJS** (`CommunityService.analyzeCommunityAction`) | **Proxy HTTP** vers le service Python. URL de base : variable d’environnement **`AI_COMMUNITY_BASE_URL`** (défaut `http://127.0.0.1:8000`), timeout **`AI_COMMUNITY_TIMEOUT_MS`** (défaut `10000`). |
| **Python (FastAPI)** | `POST /ai/community/action-plan` — charge le modèle joblib, renvoie le JSON du plan d’action. |

Flux typique en développement : Nest et Python sur le **même PC** ; Flutter (émulateur ou téléphone) parle à Nest ; Nest appelle Python en **localhost**.

---

## 3. Modèle ML (implémentation actuelle)

- **Données** : `data/community_action_dataset.csv` (jeu limité, adapté au prototype).
- **Features texte** : concaténation du texte normalisé avec des indices optionnels alignés sur le client :  
  `… \| input_mode_hint:… \| for_another_person_hint:…`
- **Pipeline** (`train_model.py`) :
  - `TfidfVectorizer` (ngrams 1–2)
  - `MultiOutputClassifier(RandomForestClassifier)` sur les colonnes définies dans `src/labels.py`
- **Artefact** : `models/community_action_planner.joblib` (à régénérer après `python src/train_model.py` si le dataset ou les labels changent).

### Post-traitement dans `predict.py` (important à comprendre)

- **`contextHint`** (`post` / `help`) **force** le type d’action après inférence, pour rester aligné avec l’intention déjà choisie dans l’UI.
- **`predictedPriority`** : heuristique **lexicale** (`infer_priority`), pas une sortie du Random Forest.
- **`recommendedRoute`, `routeReason`, `confidence`** : produits par **`infer_recommended_route`** selon le mode de saisie détecté / défini — la **`confidence`** reflète une **heuristique de navigation** (ex. 0,92 pour certains parcours accessibilité), **pas** une probabilité calibrée du classifieur sur tous les labels.
- Textes générés : `generatedContent` (post), `generatedDescription` (aide) à partir des prédictions et du texte utilisateur.

---

## 4. API FastAPI

**Route** : `POST /ai/community/action-plan`  
**Payload** (champs principaux) :

- `text` (obligatoire, min. 2 caractères côté schéma Pydantic)
- `contextHint` : `post` \| `help` \| `community` (optionnel)
- `inputModeHint` : aligné sur les modes Flutter / DTO Nest (optionnel)
- `isForAnotherPersonHint` : booléen optionnel

**Santé** : `GET /health`

Si le fichier modèle est absent → **503** avec message indiquant d’exécuter `train_model.py`.

---

## 5. Intégration Nest (rappel)

Dans `.env` du backend (exemple) :

```env
AI_COMMUNITY_BASE_URL=http://127.0.0.1:8000
AI_COMMUNITY_TIMEOUT_MS=10000
```

Sans service Python joignable, Nest renvoie une erreur **503** au client ; Flutter peut alors basculer sur des **parcours de secours** (intentions locales).

---

## 6. Commandes utiles (développement)

Depuis le dossier `ai/` :

```powershell
python -m venv .venv
.\.venv\Scripts\activate
pip install -r requirements.txt
python src/validate_dataset.py
python src/train_model.py
uvicorn src.app:app --reload --host 127.0.0.1 --port 8000
```

Test manuel :

```powershell
curl.exe -X POST http://127.0.0.1:8000/ai/community/action-plan `
  -H "Content-Type: application/json" `
  -Body '{"text":"Je veux publier un signalement","contextHint":"post"}'
```

---

## 7. Limites connues (V1)

- Taille du dataset modeste → comportement **approximatif** sur formulations très nouvelles ou dialectes.
- **`confidence`** ≠ fiabilité globale du modèle ; sert surtout au **seuil d’auto-navigation** dans Flutter (~0,85 dans l’écran d’entrée IA).
- Pas d’authentification sur le service Python en local : à sécuriser si exposition réseau large.

---

## 8. Fichiers clés

| Fichier | Rôle |
|---------|------|
| `src/labels.py` | Colonnes de labels, enums booléens / post-only / help-only |
| `src/train_model.py` | Entraînement + export `community_action_planner.joblib` |
| `src/predict.py` | Inférence + règles de route / priorité / textes générés |
| `src/app.py` | Application FastAPI |
| `data/community_action_dataset.csv` | Données d’entraînement |

Pour le **parcours utilisateur Flutter** (navigation, `extra`, seuils), voir aussi :  
`frontend/appm3ak/appm3ak/lib/features/community/README_AI_ENTRY_FLOW.md`.

---

*Document aligné sur l’implémentation actuelle du dépôt ; à faire évoluer si le modèle, les endpoints ou les variables d’environnement changent.*
