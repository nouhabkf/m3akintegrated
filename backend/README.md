# Backend NestJS - Application Ma3ak

Backend complet pour l'application Ma3ak avec gestion de la base de données MongoDB pour :
- ✅ Demandes d'aide avec géolocalisation
- ✅ Forums et discussions par type de handicap
- ✅ Système de réputation et badges

## 🚀 Installation

```bash
# Installer les dépendances
npm install

# Créer un fichier .env à partir de .env.example
cp .env.example .env

# Configurer MongoDB dans .env
MONGODB_URI=mongodb://localhost:27017/appm3ak
```

## 📦 Structure du Projet

```
src/
├── main.ts                    # Point d'entrée de l'application
├── app.module.ts             # Module principal
├── user/                     # Module utilisateur
│   └── schemas/
│       └── user.schema.ts    # Schéma MongoDB pour les utilisateurs
├── help-request/             # Module demandes d'aide
│   ├── schemas/
│   │   └── help-request.schema.ts
│   ├── dto/
│   ├── help-request.service.ts
│   ├── help-request.controller.ts
│   └── help-request.module.ts
├── community/                # Module communauté (forums)
│   ├── schemas/
│   │   ├── post.schema.ts
│   │   └── comment.schema.ts
│   ├── dto/
│   ├── community.service.ts
│   ├── community.controller.ts
│   └── community.module.ts
└── reputation/               # Module réputation et badges
    ├── schemas/
    │   └── rating.schema.ts
    ├── dto/
    ├── reputation.service.ts
    ├── reputation.controller.ts
    └── reputation.module.ts
```

## 🗄️ Base de Données

### Collections MongoDB

1. **users** - Utilisateurs (handicapés, accompagnants, admins)
   - Informations personnelles
   - Système de réputation (trustPoints, badges, noteMoyenne)
   - Statistiques (totalAidesFournies, totalAidesRecues)

2. **helprequests** - Demandes d'aide
   - Description, type, géolocalisation
   - Statut (EN_ATTENTE, EN_COURS, TERMINEE, ANNULEE)
   - Index géospatial pour recherches de proximité

3. **posts** - Posts de la communauté
   - Contenu, type (par handicap)
   - Compteurs (likesCount, commentsCount)

4. **comments** - Commentaires sur les posts
   - Référence au post et à l'utilisateur

5. **ratings** - Évaluations des bénévoles
   - Note (1-5), commentaire
   - Lien avec les demandes d'aide

## 📡 Endpoints API

### Demandes d'Aide

- `POST /community/help-requests` - Créer une demande
- `GET /community/help-requests` - Liste toutes les demandes
- `GET /community/help-requests/nearby?latitude=X&longitude=Y&maxDistance=Z` - Demandes à proximité
- `GET /community/help-requests/me` - Mes demandes
- `GET /community/help-requests/:id` - Détails d'une demande
- `POST /community/help-requests/:id/accept` - Accepter une demande (bénévole)
- `PATCH /community/help-requests/:id/statut` - Mettre à jour le statut
- `DELETE /community/help-requests/:id` - Supprimer une demande

### Forums

- `POST /community/posts` - Créer un post
- `GET /community/posts?type=handicapMoteur` - Liste des posts (filtrés par type)
- `GET /community/posts/:id` - Détails d'un post
- `POST /community/posts/:id/like` - Liker/unliker un post
- `DELETE /community/posts/:id` - Supprimer un post

### Commentaires

- `POST /community/posts/:postId/comments` - Créer un commentaire
- `GET /community/posts/:postId/comments` - Liste des commentaires d'un post
- `DELETE /community/comments/:id` - Supprimer un commentaire

### Réputation

- `POST /reputation/ratings/:userId` - Évaluer un utilisateur
- `GET /reputation/ratings/user/:userId` - Évaluations d'un utilisateur
- `GET /reputation/user/:userId` - Profil de réputation complet

## 🎯 Fonctionnalités Clés

### 1. Stockage des Demandes d'Aide
- ✅ Géolocalisation (latitude/longitude)
- ✅ Recherche de proximité (calcul de distance)
- ✅ Statuts multiples (en attente, en cours, terminée, annulée)
- ✅ Association avec bénévole acceptant

### 2. Gestion des Forums
- ✅ Posts par type de handicap
- ✅ Commentaires avec compteurs
- ✅ Système de likes
- ✅ Tri chronologique

### 3. Système de Réputation
- ✅ Notes de 1 à 5 étoiles
- ✅ Points de confiance (trustPoints)
- ✅ Badges automatiques :
  - 🏅 PREMIER_PAS (1ère aide)
  - 🏅 BENEVOLE_ACTIF (10 aides)
  - 🏅 SUPER_BENEVOLE (50 aides)
  - 🏅 FIABLE (note ≥ 4.5)
  - 🏅 EXPERT (note ≥ 4.8 + 20 aides)
  - 🏅 CONFIANCE (100+ trust points)
- ✅ Calcul automatique de la note moyenne
- ✅ Statistiques d'aide (fournies/reçues)

## 🔧 Développement

```bash
# Démarrer en mode développement
npm run start:dev

# Build pour production
npm run build

# Démarrer en production
npm run start:prod
```

## 🔐 Sécurité

⚠️ **Note importante** : Les routes sont actuellement sans authentification pour faciliter les tests. Il faut implémenter :
- JWT Authentication
- Guards sur les routes protégées
- Validation des permissions

## 📝 Exemple d'Utilisation

### Créer une demande d'aide

```bash
POST /community/help-requests
{
  "description": "Besoin d'accompagnement à la mairie",
  "type": "ACCOMPAGNEMENT",
  "latitude": 36.8065,
  "longitude": 10.1815,
  "address": "Tunis, Tunisie"
}
```

### Rechercher des demandes à proximité

```bash
GET /community/help-requests/nearby?latitude=36.8065&longitude=10.1815&maxDistance=5
```

### Évaluer un bénévole

```bash
POST /reputation/ratings/USER_ID
{
  "note": 5,
  "commentaire": "Excellent accompagnement !",
  "helpRequestId": "HELP_REQUEST_ID"
}
```

## 🗺️ Intégration avec Flutter

Le backend est conçu pour correspondre aux endpoints définis dans `lib/data/api/endpoints.dart` de l'application Flutter.

Les modèles Flutter (`help_request_model.dart`, `post_model.dart`, etc.) correspondent aux schémas MongoDB du backend.




