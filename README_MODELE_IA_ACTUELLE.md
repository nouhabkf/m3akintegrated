# README — Modèle IA actuel (Community Action Planner)

Ce document décrit uniquement le **modèle IA actuel** utilisé pour le module communauté.

---

## 1) Objectif du modèle

Le modèle prend un texte utilisateur et aide à décider un plan d'action communauté:

- `create_post`
- `create_help_request`

Il renvoie aussi des champs structurés utiles au pré-remplissage Flutter (nature de post, aide, recommandations de route, etc.).

---

## 2) Où se trouve le modèle

Dossier IA:

- `ai/`

Fichiers clés:

- `ai/src/train_model.py` (entraînement)
- `ai/src/predict.py` (inférence + règles)
- `ai/src/app.py` (API FastAPI)
- `ai/src/labels.py` (labels)
- `ai/data/community_action_dataset.csv` (dataset)
- `ai/models/community_action_planner.joblib` (modèle exporté)

---

## 3) Pipeline ML actuel

Le pipeline entraîné est basé sur:

- `TfidfVectorizer` (ngrams 1-2)
- `MultiOutputClassifier(RandomForestClassifier)`

Le modèle est **multi-sorties**: il prédit plusieurs champs en même temps, pas seulement une classe unique.

---

## 4) Entrées utilisées par le modèle

Entrée principale:

- `text`

Signaux additionnels injectés dans les features:

- `contextHint` (`post`, `help`, `community`)
- `inputModeHint` (ex: `voice`, `keyboard`, `headEyes`, `volume_shortcut`, etc.)
- `isForAnotherPersonHint`

Important: `inputModeHint` influence la décision finale (règles dans `predict.py`), surtout en cas de texte ambigu.

---

## 5) Sorties principales

Le backend Python renvoie un plan avec notamment:

- `action`
- `recommendedRoute`
- `confidence`
- `decisionSummary`
- champs de pré-remplissage post/aide

La navigation finale est ensuite gérée côté Flutter/Nest selon confiance + règles locales.

---

## 6) API du modèle

Endpoint principal:

- `POST /ai/community/action-plan`

Health check:

- `GET /health`

Si le modèle `.joblib` est absent, l'API peut renvoyer une erreur (service non prêt / 503 selon le cas).

---

## 7) Commandes utiles

Depuis `ai/`:

```powershell
python -m venv .venv
.\.venv\Scripts\activate
pip install -r requirements.txt
python src/validate_dataset.py
python src/train_model.py
uvicorn src.app:app --reload --host 127.0.0.1 --port 8000
```

Test rapide:

```powershell
curl.exe -X POST http://127.0.0.1:8000/ai/community/action-plan ^
  -H "Content-Type: application/json" ^
  -d "{\"text\":\"Je veux publier un obstacle\",\"contextHint\":\"post\",\"inputModeHint\":\"voice\"}"
```

---

## 8) Limites actuelles

- Dataset encore limité (phrases nouvelles/dialectes peuvent être mal classés).
- `confidence` est en partie heuristique; ce n'est pas une probabilité parfaitement calibrée.
- Le modèle dépend fortement de la qualité du texte STT.

---

## 9) Recommandations avant grosse refonte

1. Geler le contrat de sortie (`CommunityActionPlanResponseDto`).
2. Ajouter des exemples réels dans `community_action_dataset.csv`.
3. Réentraîner puis valider avec phrases critiques:
   - "dernier post"
   - "aide rapide"
   - "non voyant"
   - "nhabet taswira"
4. Comparer ancien vs nouveau modèle sur un lot de tests avant déploiement.

