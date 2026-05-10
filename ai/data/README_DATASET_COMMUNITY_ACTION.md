# README — Dataset `community_action_dataset.csv`

Ce document décrit le dataset utilisé par le **Community Action Planner**.

---

## 1) Fichier concerné

- `ai/data/community_action_dataset.csv`

Ce CSV est la source d'entraînement principale du modèle IA communauté.

---

## 2) Rôle du dataset

Le dataset apprend au modèle à prédire:

- l'action principale (`create_post` ou `create_help_request`)
- des attributs de post (nature, audience, niveau de danger, mode de saisie)
- des attributs d'aide (type d'aide, profil demandeur, preset)
- des flags d'accessibilité (audio/visuel/physique/langage simple)

---

## 3) Schéma (colonnes)

Ordre actuel des colonnes:

1. `text`
2. `inputModeHint`
3. `isForAnotherPersonHint`
4. `actionType`
5. `postNature`
6. `targetAudience`
7. `postInputMode`
8. `locationSharingMode`
9. `dangerLevel`
10. `helpType`
11. `requesterProfile`
12. `helpInputMode`
13. `presetMessageKey`
14. `needsAudioGuidance`
15. `needsVisualSupport`
16. `needsPhysicalAssistance`
17. `needsSimpleLanguage`
18. `isForAnotherPerson`

Important:

- garder exactement les mêmes noms de colonnes
- ne pas changer l'ordre
- ne pas supprimer de colonne (compatibilité entraînement + backend)

---

## 4) Règles de remplissage

- `actionType`:
  - `create_post`
  - `create_help_request`
- Pour une ligne **post**:
  - colonnes aide (`helpType`, `requesterProfile`, `helpInputMode`, `presetMessageKey`) => `none`
- Pour une ligne **help**:
  - colonnes post (`postNature`, `targetAudience`, `postInputMode`, `locationSharingMode`, `dangerLevel`) => `none`
- Booléens: utiliser `true/false` ou `True/False` de façon cohérente
- Texte:
  - court, naturel, proche des phrases utilisateur réelles
  - couvrir français + darja/arabe latin quand possible

---

## 5) Valeurs utiles (référence rapide)

- `inputModeHint`: `keyboard`, `voice`, `headEyes`, `vibration`, `deafBlind`, `caregiver`, `text`, `tap`, `haptic`, `volume_shortcut`
- `postNature`: `signalement`, `alerte`, `information`, `conseil`, `temoignage`
- `targetAudience`: `all`, `motor`, `visual`, `hearing`, `cognitive`, `caregiver`, `none`
- `locationSharingMode`: `none`, `approximate`, `precise`
- `dangerLevel`: `none`, `low`, `medium`, `critical`
- `helpType`: `mobility`, `orientation`, `communication`, `medical`, `escort`, `unsafe_access`, `other`, `none`
- `presetMessageKey`: `none`, `blocked`, `lost`, `cannot_reach`, `medical_urgent`, `escort`

---

## 6) Exemples post-oriented (entrée communauté)

Exemples recommandés pour améliorer l'entrée post:

- `je veux publier`
- `je veux poster une photo`
- `je veux signaler un obstacle`
- `escalier sans rampe`
- `entrée inaccessible`
- `rampe absente`
- `accès difficile`
- `dernier post`
- `voir les posts`
- `nheb nposti`
- `nheb nposti taswira`
- `nhabet post`
- `fama obstacle`
- `ma famech rampe`
- `nheb nchouf les posts`

Pour ces lignes orientées post, garder les colonnes aide à `none`.

---

## 7) Workflow après modification

Depuis `ai/`:

```powershell
python src/validate_dataset.py
python src/train_model.py
```

Vérifier ensuite quelques phrases critiques via `predict.py` ou l'API `/ai/community/action-plan`.

---

## 8) Bonnes pratiques qualité

- Ajouter des lignes par petits lots (10-30), puis valider/train immédiatement
- Équilibrer progressivement post/help pour éviter le biais de classe
- Éviter les doublons exacts
- Ajouter des variantes orthographiques STT (accents, darja, fautes réalistes)
- Documenter les nouvelles familles de phrases dans le PR

---

## 9) Erreurs fréquentes

- colonnes déplacées ou renommées
- lignes post avec colonnes help non `none` (ou inverse)
- valeurs hors vocabulaire attendu (`actionType` invalide, etc.)
- ajout massif de lignes d'un seul type, qui dégrade l'équilibre

---

## 10) Fichiers liés

- `ai/src/validate_dataset.py` (validation structure + cohérence)
- `ai/src/train_model.py` (entraînement)
- `ai/src/predict.py` (inférence + règles hybrides)
- `ai/src/labels.py` (groupes de colonnes bool/post/help)

mer