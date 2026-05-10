# Activer l’analyse d’image réelle (Google Cloud Vision API)

Ce guide permet de remplacer le **mode simulation** par une **vraie analyse** des photos (labels, texte, objets) dans l’API Ma3ak (module `VisionService`).

---

## 0. Prérequis

- Compte **Google** (Gmail).
- Carte bancaire éventuellement demandée par Google Cloud (souvent **crédit d’essai** ; Vision a un **niveau gratuit limité** — vérifiez la [tarification Vision](https://cloud.google.com/vision/pricing)).
- Backend avec le package **`@google-cloud/vision`** installé :

```bash
npm install @google-cloud/vision
```

---

## 1. Créer un projet Google Cloud

1. Allez sur [Google Cloud Console](https://console.cloud.google.com/).
2. En haut : **Sélectionner un projet** → **Nouveau projet**.
3. Donnez un nom (ex. `ma3ak-vision`) → **Créer**.
4. Notez l’**ID du projet** (ex. `ma3ak-vision-123456`) — vous en aurez besoin pour `GOOGLE_CLOUD_PROJECT_ID`.

---

## 2. Activer l’API Cloud Vision

1. Menu **☰** → **APIs et services** → **Bibliothèque**.
2. Recherchez **Cloud Vision API**.
3. Ouvrez-la → **Activer**.

---

## 3. Compte de service + clé JSON

1. **APIs et services** → **Comptes de service**.
2. **Créer un compte de service** :
   - Nom : ex. `ma3ak-vision-api`
   - **Créer et continuer**.
3. Rôle : au minimum **`Cloud Vision AI User`** (ou **`Projet` → `Éditeur`** en dev uniquement — moins recommandé en prod).
4. **Terminer**.
5. Sur la ligne du compte → **⋮** → **Gérer les clés** → **Ajouter une clé** → **JSON**.
6. Un fichier `.json` est **téléchargé** — **ne le commitez jamais** dans Git.

Placez ce fichier dans un dossier **hors du dépôt**, par exemple :

- Windows : `C:\secrets\ma3ak-gcp-vision.json`
- Linux / macOS : `/home/vous/secrets/ma3ak-gcp-vision.json`

---

## 4. Variables d’environnement

Créez ou modifiez le fichier **`.env`** à la racine du backend (à côté de `package.json`).

### Windows (chemin recommandé : slashes `/`)

```env
# Chemin ABSOLU vers le fichier JSON du compte de service
GOOGLE_APPLICATION_CREDENTIALS=C:/secrets/ma3ak-gcp-vision.json

# ID du projet GCP (visible dans la console, ou champ "project_id" dans le JSON)
GOOGLE_CLOUD_PROJECT_ID=votre-id-projet-gcp
```

Évitez les espaces dans le chemin. Si vous utilisez des antislashs, en `.env` vous pouvez tester :

```env
GOOGLE_APPLICATION_CREDENTIALS=C:\\secrets\\ma3ak-gcp-vision.json
```

### Linux / macOS

```env
GOOGLE_APPLICATION_CREDENTIALS=/home/vous/secrets/ma3ak-gcp-vision.json
GOOGLE_CLOUD_PROJECT_ID=votre-id-projet-gcp
```

`@nestjs/config` charge en général `.env` au démarrage : **redémarrez** le serveur après toute modification.

---

## 5. Redémarrer l’API

```bash
cd "chemin/vers/backend-m3ak 2"
npm run start:dev
```

Dans les logs, vous devriez voir une ligne du type :

`Google Vision API client initialisé`

Si vous voyez encore des avertissements sur la configuration, vérifiez :

- le **chemin** du JSON (fichier existe, droits en lecture) ;
- l’API **Vision** est bien **activée** sur **le même projet** que dans le JSON ;
- pas de **quotas** / facturation bloqués dans la console.

---

## 6. Vérification rapide

- Créez un post **avec une image** via l’app ou Swagger.
- La réponse ne doit plus contenir le texte fixe *« Analyse d’image non disponible. Configurez Google Vision API… »* en description simulée ; vous devriez obtenir des **labels** / **score** / **description** issus de l’API (selon l’image).

---

## Sécurité

- Ne versionnez **pas** le `.json` ni le `.env` avec des secrets.
- En production, utilisez les secrets du hébergeur (variables d’environnement, Secret Manager, etc.) plutôt qu’un fichier sur le disque si possible.

---

## Dépannage

| Problème | Piste |
|----------|--------|
| `Could not load the default credentials` | `GOOGLE_APPLICATION_CREDENTIALS` incorrect ou fichier introuvable. |
| `PERMISSION_DENIED` | Rôle du compte de service insuffisant ou mauvais projet. |
| `API has not been used` / désactivée | Réactiver **Cloud Vision API** sur le projet. |
| Toujours « mode simulation » | Redémarrer Nest après `.env` ; vérifier que `ConfigModule` charge bien `.env`. |
