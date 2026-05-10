# Guide de Configuration - Backend Ma3ak

## 📋 Prérequis

- Node.js (v18 ou supérieur)
- MongoDB (v5 ou supérieur)
- npm ou yarn

## 🔧 Installation

### 1. Installer les dépendances

```bash
cd backend
npm install
```

### 2. Configurer MongoDB

#### Option A: MongoDB Local

1. Installer MongoDB sur votre machine
2. Démarrer MongoDB :
   ```bash
   # Windows
   mongod
   
   # Linux/Mac
   sudo systemctl start mongod
   ```

3. Créer le fichier `.env` :
   ```env
   MONGODB_URI=mongodb://localhost:27017/appm3ak
   PORT=3000
   NODE_ENV=development
   ```

#### Option B: MongoDB Atlas (Cloud)

1. Créer un compte sur [MongoDB Atlas](https://www.mongodb.com/cloud/atlas)
2. Créer un cluster gratuit
3. Obtenir la chaîne de connexion
4. Configurer dans `.env` :
   ```env
   MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/appm3ak
   ```

### 3. Créer les index MongoDB (Optionnel mais recommandé)

Pour optimiser les performances, exécutez ce script dans MongoDB :

```javascript
// Se connecter à MongoDB
use appm3ak

// Index pour les demandes d'aide
db.helprequests.createIndex({ latitude: 1, longitude: 1 })
db.helprequests.createIndex({ userId: 1 })
db.helprequests.createIndex({ statut: 1 })
db.helprequests.createIndex({ createdAt: -1 })

// Index pour les posts
db.posts.createIndex({ userId: 1 })
db.posts.createIndex({ type: 1 })
db.posts.createIndex({ createdAt: -1 })

// Index pour les commentaires
db.comments.createIndex({ postId: 1 })
db.comments.createIndex({ userId: 1 })
db.comments.createIndex({ createdAt: 1 })

// Index pour les évaluations
db.ratings.createIndex({ ratedUserId: 1 })
db.ratings.createIndex({ raterUserId: 1 })
db.ratings.createIndex({ helpRequestId: 1 })
db.ratings.createIndex({ ratedUserId: 1, raterUserId: 1, helpRequestId: 1 }, { unique: true })

// Index pour les utilisateurs
db.users.createIndex({ email: 1 }, { unique: true })
db.users.createIndex({ role: 1 })
```

### 4. Démarrer le serveur

```bash
# Mode développement (avec hot-reload)
npm run start:dev

# Mode production
npm run build
npm run start:prod
```

Le serveur sera accessible sur `http://localhost:3000`

## 🧪 Tester l'API

### Avec cURL

```bash
# Créer une demande d'aide
curl -X POST http://localhost:3000/community/help-requests \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Besoin d accompagnement à la mairie",
    "type": "ACCOMPAGNEMENT",
    "latitude": 36.8065,
    "longitude": 10.1815,
    "address": "Tunis, Tunisie"
  }'

# Rechercher des demandes à proximité
curl "http://localhost:3000/community/help-requests/nearby?latitude=36.8065&longitude=10.1815&maxDistance=5"

# Créer un post
curl -X POST http://localhost:3000/community/posts \
  -H "Content-Type: application/json" \
  -d '{
    "contenu": "Bonjour, je cherche des conseils sur...",
    "type": "handicapMoteur"
  }'
```

### Avec Postman

1. Importer la collection d'API (à créer)
2. Configurer l'URL de base : `http://localhost:3000`
3. Tester les endpoints

## 🔐 Sécurité (À implémenter)

Actuellement, l'authentification n'est pas implémentée. Pour la production :

1. **Installer les packages JWT** :
   ```bash
   npm install @nestjs/jwt @nestjs/passport passport passport-jwt
   ```

2. **Créer un module d'authentification** :
   - JWT Strategy
   - Auth Guard
   - Décorateur @CurrentUser()

3. **Protéger les routes** :
   ```typescript
   @UseGuards(JwtAuthGuard)
   @Get('me')
   findMyRequests(@CurrentUser() user: User) {
     return this.helpRequestService.findByUser(user.id);
   }
   ```

## 📊 Monitoring

### Vérifier la connexion MongoDB

```bash
# Se connecter à MongoDB
mongo

# Vérifier les collections
use appm3ak
show collections

# Compter les documents
db.helprequests.countDocuments()
db.posts.countDocuments()
db.users.countDocuments()
```

## 🐛 Dépannage

### Erreur de connexion MongoDB

- Vérifier que MongoDB est démarré
- Vérifier l'URI dans `.env`
- Vérifier les permissions de connexion

### Erreur de port déjà utilisé

```bash
# Changer le port dans .env
PORT=3001
```

### Erreurs TypeScript

```bash
# Nettoyer et réinstaller
rm -rf node_modules dist
npm install
npm run build
```

## 📝 Notes

- Les timestamps (`createdAt`, `updatedAt`) sont gérés automatiquement par Mongoose
- Les relations (populate) chargent automatiquement les données utilisateur
- La recherche de proximité utilise la formule de Haversine (peut être optimisée avec MongoDB Geospatial)




