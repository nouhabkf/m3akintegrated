# Projet nettoyé pour partage (.zip)

## Archives séparées (recommandé — **léger**)

Fichiers dans **`C:\Users\DELL\Downloads\`** :

| Fichier | Contenu | Taille indicative |
|---------|---------|-------------------|
| **`appm3ak-flutter-app.zip`** | **Uniquement** le projet Flutter `frontend/appm3ak/appm3ak/` (sources + assets utiles) | **~48 Mo** |
| **`appm3ak-backend.zip`** | Dossier `backend/` (NestJS), sans `node_modules` | **~13 Mo** |

*(L’ancien `appm3ak-frontend.zip` qui contenait tout le dossier `frontend/` était beaucoup plus gros ; préférer **`appm3ak-flutter-app.zip`**.)*

---

## Ce qui a été retiré pour alléger (sans supprimer le code source)

| Supprimé | Rôle |
|----------|------|
| `build/`, `.dart_tool/`, `android/.gradle` | Caches / compilations Flutter |
| `linux/flutter/ephemeral`, `macos/Flutter/ephemeral` | Fichiers régénérés par Flutter (Linux/macOS) |
| Doublons dans **`assets/`** | `face_model.tflite` à la racine de `assets/` (doublon de `assets/models/`) ; vidéos `*.mp4.mp4` en double des fichiers dans `assets/videos/gestures/` |
| `node_modules/`, `dist/` | Backend (réinstallables) |
| `__MACOSX/`, gros logs | Inutiles |

Le modèle **`assets/models/face_model.tflite`** et les vidéos **`assets/videos/gestures/*.mp4`** sont **conservés** (utilisés par l’app).

---

## Ce que votre collègue doit faire après extraction

1. **Flutter** — ouvrir le dossier extrait (projet avec `pubspec.yaml`)  
   ```bash
   flutter pub get
   flutter run
   ```  
   Sous **Linux** / **macOS**, au premier build cible, Flutter recrée les dossiers `ephemeral` si besoin.

2. **Backend** — dans `backend/backend-m3ak 2/` (ou le dossier Nest utilisé)  
   ```bash
   npm install
   npm run start:dev
   ```

3. Internet requis la première fois (`pub.dev`, npm).

Les dossiers **`build/`**, **`.dart_tool/`**, **`node_modules/`** se recréent automatiquement.
