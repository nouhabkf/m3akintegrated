# Community AI Entry Flow - Documentation precise

Ce document décrit en detail le fonctionnement de l'entree IA du module communaute dans l'application Ma3ak.

---

## 1) Objectif

L'ecran `CommunityAiEntryScreen` est un point d'entree intelligent avant le module communaute classique.

Il permet de:

- comprendre l'intention utilisateur (publier, demander de l'aide, lieux)
- appeler l'IA de plan d'action communautaire
- naviguer automatiquement ou proposer une route selon le niveau de confiance
- transmettre le resultat IA aux ecrans cibles via `GoRouter extra` pour pre-remplissage

---

## 2) Fichiers principaux

### Ecran d'entree IA

- `lib/features/community/screens/community_ai_entry_screen.dart`

Responsabilites:

- UI d'entree (micro, texte, suggestions, continuer)
- TTS d'accueil
- appel IA via provider
- logique de navigation intelligente

### Routing

- `lib/router/app_router.dart`

Routes concernees:

- `/community-ai-entry`
- `/create-post`
- `/create-help-request`

### Ecrans de destination (autofill)

- `lib/features/community/screens/create_post_screen.dart`
- `lib/features/community/screens/create_help_request_screen.dart`

Ces ecrans acceptent `CommunityActionPlanResult` en `extra` et pre-remplissent le formulaire.

### Provider / repository / model

- `lib/providers/community_providers.dart`
- `lib/data/repositories/community_repository.dart`
- `lib/data/models/community_action_plan_result.dart`
- `lib/data/api/endpoints.dart`

Endpoint utilise:

- `/community/ai/action-plan` (cote backend Nest)

---

## 3) Parcours utilisateur exact

## 3.1 Depuis Home

Depuis les cartes communaute/accessibilite de `home_tab`, la navigation ouvre:

- `/community-ai-entry`

et non plus directement `/community-posts`.

## 3.2 Sur l'ecran IA

L'utilisateur peut:

- taper un texte puis appuyer sur `Continuer`
- cliquer une suggestion rapide (appel IA automatique)
- appuyer sur `Ouvrir le module classique` (route directe vers `/community-posts`)

## 3.3 Appel IA

L'ecran appelle:

- `communityActionPlanProvider(...)`

avec:

- `text`
- `contextHint` (derive de l'intention)
- autres hints optionnels

## 3.4 Reponse IA et navigation

Si `recommendedRoute` est present:

- confiance >= seuil (85%): navigation automatique
- confiance < seuil: suggestion affichee + action utilisateur `Ouvrir`

Si `recommendedRoute` est absent:

- fallback par intention (publish/help/location)
- sinon on reste sur l'ecran avec message d'information

---

## 4) Intentions supportees

Intentions couvertes cote UI:

### Publish intent

Exemples:

- `je veux publier`
- `je veux poster`
- `je veux poster une photo`
- `je veux faire une publication`
- `je veux signaler un obstacle`

Fallback route:

- `/create-post`

### Help intent

Exemples:

- `j'ai besoin d'aide`
- `je suis perdu`
- `je suis bloque`
- `urgence`

Fallback route:

- `/create-help-request`

### Location intent

Exemples:

- `je cherche un lieu accessible`
- `je veux voir les lieux`
- `je veux un lieu proche`

Fallback route:

- `/community-locations`

---

## 5) Regles de confiance

Seuil actuel:

- `0.85` (85%)

Comportement:

- >= 85%: ouverture auto de la route IA
- < 85%: suggestion non bloquante avec bouton `Ouvrir`

Avantage:

- evite les mauvaises redirections automatiques
- laisse l'utilisateur garder le controle quand la prediction est moyenne

---

## 6) Passage du resultat IA (extra)

Lors des navigations IA, l'ecran passe:

- `extra: CommunityActionPlanResult`

But:

- permettre aux ecrans cibles de pre-remplir leurs champs
- conserver le contexte et les recommandations IA

---

## 7) Pre-remplissage ecrans cibles

## 7.1 Create Post

`CreatePostScreen`:

- accepte `initialAiPlan`
- applique `toCreatePostInput()`
- conserve edition manuelle (aucun champ verrouille)
- affiche `Analyse intelligente appliquee`

## 7.2 Create Help Request

`CreateHelpRequestScreen`:

- accepte `initialAiPlan`
- applique `toCreateHelpRequestInput(...)`
- tente de recuperer la position actuelle avant mapping (si dispo)
- conserve edition manuelle
- affiche `Analyse intelligente appliquee`

---

## 8) TTS

Sur `CommunityAiEntryScreen`:

- phrase lue au chargement: `Comment puis-je vous aider ?`
- protection anti-repetition sur rebuild
- bouton `Repeter` pour relancer manuellement

Package utilise:

- `flutter_tts`

---

## 9) Backend attendu

Le frontend consomme:

- `POST /community/ai/action-plan`

Si vous utilisez une IA Python separée (`ai/`), il faut:

- soit exposer un proxy Nest vers cette API Python
- soit aligner l'appel frontend sur l'endpoint Python (moins recommande)

Sans backend actif/joignable:

- l'ecran bascule sur les fallbacks par intention

---

## 10) Commandes utiles (dev)

## Flutter

```powershell
cd "C:\Users\DELL\Downloads\appm3ak\frontend\appm3ak\appm3ak"
flutter pub get
dart analyze lib
flutter run
```

## IA Python locale (si utilisee)

```powershell
cd "C:\Users\DELL\Downloads\appm3ak\ai"
python -m venv .venv
.\.venv\Scripts\activate
pip install -r requirements.txt
python src/validate_dataset.py
python src/train_model.py
uvicorn src.app:app --reload --host 127.0.0.1 --port 8000
```

Test API Python:

```powershell
curl -Method POST "http://127.0.0.1:8000/ai/community/action-plan" `
  -ContentType "application/json" `
  -Body '{"text":"je veux publier","contextHint":"post"}'
```

---

## 11) Troubleshooting rapide

## "L'IA ne fait rien"

Verifier:

- backend IA joignable
- endpoint correct
- logs reseau (code HTTP)

Note:

- si confiance basse, l'app ne force pas la navigation
- une suggestion avec action `Ouvrir` est proposee

## "Toujours 75%"

C'est une confiance moyenne:

- comportement attendu = suggestion (pas auto-open)
- vous pouvez reduire le seuil (ex: 0.70) si besoin produit

## "Build failed"

Recuperer la vraie erreur:

```powershell
flutter run -v *> run_verbose.log
Select-String -Path .\run_verbose.log -Pattern "Error:|FAILURE:|Exception:|Target .* failed" -CaseSensitive:$false
```

---

## 12) Extension conseillee

Prochaines ameliorations possibles:

- afficher un bandeau "Analyse en cours..."
- ajouter confirmation UI pour les confiances intermediaires
- telemetrie (intent detecte, route proposee, route ouverte)
- seuil de confiance configurable via remote config

