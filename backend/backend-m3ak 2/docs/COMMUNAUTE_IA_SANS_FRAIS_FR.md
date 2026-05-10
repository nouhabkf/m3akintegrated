# Communauté : fonctionnalités « IA » sans frais (ou quasi gratuites)

Objectif : garder **simplification de texte**, **résumés**, **analyse d’image**, etc. **sans carte bancaire obligatoire** et **sans facturation cloud** (Google Vision exige une facturation activée).

---

## 1. Ce qui est **vraiment gratuit** (0 €, 0 carte)

| Besoin | Solution | Remarque |
|--------|----------|----------|
| **Simplifier un texte (FALC léger)** | **Règles + synonymes** dans le backend (`AccessibilityService.simplifyText`) | Déjà prévu dans ce dépôt : **aucune clé API**. Qualité correcte pour du dev / secours, pas du GPT. |
| **Résumé flash des commentaires** | **Heuristique** (extraits de phrases) dans `flashSummaryFromComments` | Idem, **0 €**. |
| **« Vraie » IA (LLM)** sur votre PC | **[Ollama](https://ollama.com/)** (Llama, Mistral, etc.) en **local** | Gratuit, tourne sur **votre machine** ; pas de frais cloud. Nécessite un PC un peu costaud. |
| **Vision / image** sans Google | **Pas de cloud** : afficher l’image + **texte du post** ; ou **mode simulation** (scores fictifs) | Qualité « IA image » réelle sans service = difficile sans API ou sans modèle local lourd. |

---

## 2. Gratuit avec **compte** mais **limites** (souvent sans carte au début)

| Service | Usage typique | Coût |
|---------|----------------|------|
| **Google AI Studio (Gemini)** | Reformulation, résumé, FALC | [Quotas gratuits](https://ai.google.dev/pricing) — à vérifier selon l’offre actuelle |
| **Hugging Face Inference** | Petits modèles en API | Gratuit avec **rate limit** |
| **OpenAI** | GPT | Crédit d’essai parfois, puis **payant** |

➡️ Pour **zéro frais garantis**, privilégiez **règles locales + Ollama**, pas les APIs facturées.

---

## 3. Ce qui **n’est pas** gratuit sans conditions

- **Google Cloud Vision** : l’API exige en pratique **facturation activée** sur le projet (même avec essai).
- **OpenAI** : après le crédit gratuit éventuel, **payant**.

---

## 4. Recommandation pour **Ma3ak / module Communauté**

### Court terme (sans rien installer)

1. Garder **`OPENAI_API_KEY` vide** → le backend bascule sur **simulation / règles** (selon votre branche).
2. Utiliser le backend de ce dépôt où **`simplify-text`** et **flash summary** sont déjà en **mode règles** → **pas de frais**.

### Moyen terme (meilleure qualité texte, toujours 0 € cloud)

1. Installer **Ollama** sur le PC du serveur (ou votre poste en dev).
2. Télécharger un modèle léger (`llama3.2`, `mistral`, etc.).
3. Brancher le backend sur `http://localhost:11434` (à coder : un `OllamaService` qui appelle `/api/generate` pour la simplification FALC).

Exemple de test manuel (PowerShell) une fois Ollama lancé :

```powershell
curl http://localhost:11434/api/generate -Method POST -ContentType "application/json" -Body '{"model":"llama3.2","prompt":"Simplifie en francais simple, 3 phrases max: Votre texte ici...","stream":false}'
```

---

## 5. Côté **application Flutter**

Aucun changement obligatoire : l’app appelle toujours les mêmes routes (`/accessibility/simplify-text`, etc.). Seul le **backend** décide s’il répond par **règles**, **Ollama**, ou une API cloud.

---

## 6. Résumé

- **Sans frais et sans carte** : **règles + Ollama local** = stratégie réaliste pour du **vrai** texte intelligent sans payer.
- **Google Vision** = pas adapté si vous refusez **toute** facturation GCP.
- Les fonctionnalités « IA » du module communauté peuvent rester **utiles** avec le **mode léger** déjà intégré ici.

## 7. Activation dans ce backend (déjà implémenté)

Dans le fichier **`.env`** à la racine du backend :

```env
OLLAMA_ENABLED=true
OLLAMA_BASE_URL=http://127.0.0.1:11434
OLLAMA_MODEL=llama3.2
```

1. Installez [Ollama](https://ollama.com) et téléchargez un modèle : `ollama pull llama3.2` (ou `mistral`, etc.).
2. Lancez Ollama (service en arrière-plan sur le port **11434**).
3. Redémarrez l’API Nest (`npm run start:dev`).

Comportement :

- **`POST /accessibility/simplify-text`** : utilise Ollama si `OLLAMA_ENABLED=true`, sinon **règles locales**.
- **`GET /community/posts/:postId/comments/flash-summary`** : idem pour le résumé des commentaires.

Si Ollama est indisponible (mauvais port, modèle absent), le backend **basculle automatiquement** sur les heuristiques (aucune erreur bloquante).

### Vision (images) — LLaVA via Ollama

Pour **`GET /community/posts/:postId/images/:index/audio-description`** avec **vraie analyse d’image** (non-voyant / malvoyant) :

1. `OLLAMA_ENABLED=true`
2. Télécharger un modèle **vision** : `ollama pull llava` (ou `llava:13b`, etc.)
3. Optionnel : `OLLAMA_VISION_MODEL=llava` (défaut), `OLLAMA_VISION_TIMEOUT_MS=180000`

Si le fichier image est absent ou le modèle vision échoue, le service retombe sur une **description textuelle** dérivée du contenu du post (repli).

---

## 8. Fichiers uploadés (`/uploads/…`) — éviter les **404**

- **Cause fréquente** : Multer écrit les fichiers dans `process.cwd()/uploads` alors que `useStaticAssets` pointait vers un autre dossier (`__dirname/../uploads`). Les chemins divergent selon **où** le processus Node est lancé.
- **Correction dans ce dépôt** : un seul point de vérité — `getUploadsRoot()` dans `src/common/upload-paths.ts` — utilisé pour **créer le dossier**, **`useStaticAssets`**, et **`destination` Multer** (posts, lieux, photo profil).
- **Côté Flutter** : `CommunityRepository.uploadUrl` normalise aussi les `\` en `/` pour l’URL.

Toujours lancer l’API depuis le dossier du backend où se trouve `package.json` (pour que `process.cwd()` pointe vers le bon `uploads/`), par exemple sous Windows :

`cd "C:\Users\DELL\Downloads\backend-m3ak\backend-m3ak 2"` puis `npm run start:dev`.

---

## 9. LSF / vidéo signes — statut **`pending`** (démo async)

Si une réponse JSON contient par ex. `"lsfVideo": { "status": "pending" }`, c’est **volontairement** le modèle d’un traitement **asynchrone** : l’utilisateur peut continuer à naviguer pendant qu’un job (transcodage, génération, IA) tourne en arrière-plan. La suite consiste à exposer un **polling** ou des **notifications** quand `status` passe à `ready` / `failed` — ce schéma est adapté aux démos d’architecture.
