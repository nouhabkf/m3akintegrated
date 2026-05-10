# Intégration Ma3ak — `apppm3ak` + projet `appmaakferiel`

Date : 8 mai 2026

## Pourquoi ce dossier

Le dépôt Cursor / disque indiqué comme `C:\Program Files\appmaakferiel` est **protégé par Windows** (écriture refusée pour les copies et l’éditeur). Toute l’intégration a donc été produite dans un répertoire utilisateur **accessible en écriture** :

`C:\Users\nouha\Ma3ak_integrated_appmaakferiel`

C’est l’**unique copie de travail prête** : monorepo (backend NestJS, service Python `ai/`, app Flutter) + apports de `C:\Users\nouha\apppm3ak` sans remplacer les fichiers déjà présents dans votre app Flutter d’origine (logique *fichiers manquants seulement* pour le code source, en excluant `build/`, `.dart_tool/`, `ios/Pods/`, etc.).

## Contenu

| Élément | Source | Remarque |
|--------|--------|----------|
| `appm3ak/` | Base = copie de `C:\Program Files\appmaakferiel\appm3ak` + **79 fichiers** issus de `apppm3ak\frontend\appm3ak\appm3ak` (chemins inexistants dans la base) | Aucun fichier existant n’a été écrasé. |
| `backend/` | `apppm3ak\backend` | `node_modules` / `dist` non copiés : lancer `npm install` puis `npm run start:dev` dans `backend\backend-m3ak 2`. |
| `ai/` | `apppm3ak\ai` | Créer `ai/.env` (voir README racine). |
| `scripts/`, `module-communaute/`, `seed/` | `apppm3ak` | Comme dans le README monorepo. |
| Fichiers racine | `package.json`, `seed.js`, `README.md` (monorepo), guides `README_*.md`, etc. | Alignés sur `apppm3ak`. |

## Ajustements faits pour un build propre (Flutter)

Fichiers modifiés **dans ce dossier intégré** (pas dans Program Files) :

- `appm3ak/lib/core/l10n/app_strings.dart` : ajout de `navLieux` et `nearbyPlacesNav` (requis par les écrans importés depuis `apppm3ak`).
- `appm3ak/pubspec.yaml` : ajout de `http`, `intl`, et déclaration d’assets `assets/accessibility/`.

Commandes vérifiées :

- `flutter pub get` — OK  
- `flutter analyze` — aucune ligne `error -` (des infos / warnings peuvent rester).

## Utiliser ce projet dans Cursor

1. **Fichier → Ouvrir le dossier** : `C:\Users\nouha\Ma3ak_integrated_appmaakferiel`
2. Ou remplacer votre ancienne copie : après sauvegarde, copier **tout** ce dossier vers l’emplacement souhaité (voir ci‑dessous).

## Remplacer `C:\Program Files\appmaakferiel` (optionnel, droits admin)

Ouvrir **PowerShell en administrateur**, puis par exemple :

```powershell
$src = "C:\Users\nouha\Ma3ak_integrated_appmaakferiel"
$dst = "C:\Program Files\appmaakferiel"
# Sauvegarde recommandée du dossier actuel avant écrasement.
robocopy $src $dst /MIR /XD node_modules .dart_tool build ios/Pods android\.gradle /XF
```

Adapter `$dst` si votre projet vit ailleurs. `/MIR` synchronise : **supprime** sur la cible ce qui n’est pas à la source ; préférer une copie manuelle ou **sans** `/MIR` si vous voulez seulement fusionner.

## README monorepo d’origine (`apppm3ak`)

Le fichier `README.md` à la racine de ce dossier est celui du monorepo **Ma3ak** (Nest + Flutter + FastAPI) : structure, ports, variables `AI_COMMUNITY_BASE_URL`, etc. Les chemins y citent `frontend\appm3ak\appm3ak` ; **ici l’app Flutter est directement dans `appm3ak/`** (équivalent fonctionnel).

Pour les chemins machine mis à jour localement, vous pouvez éditer `PROJET_UNIFIE.txt` et `CHEMINS_PROJET.txt` dans ce dossier.

---

*Intégration réalisée pour rapprocher le travail sous `C:\Users\nouha\apppm3ak` du projet ouvert sous `appmaakferiel`, sans destruction du code déjà présent.*
