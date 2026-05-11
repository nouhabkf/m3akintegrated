# Guide d'Intégration - Module Communauté

Ce guide vous explique comment ajouter le module communauté (demandes d'aide, forums, réputation) à votre backend existant.

## 📋 Ce qui est nécessaire

Le module communauté nécessite :
1. **Schémas MongoDB** pour les collections
2. **Services** pour la logique métier
3. **Contrôleurs** pour les endpoints API
4. **DTOs** pour la validation
5. **Mise à jour du schéma User** pour la réputation

## 🗂️ Structure des fichiers

Tous les fichiers sont dans le dossier `module-communaute/`. Copiez-les dans votre backend :

```
module-communaute/
├── schemas/              # Schémas MongoDB
│   ├── help-request.schema.ts
│   ├── post.schema.ts
│   ├── comment.schema.ts
│   └── rating.schema.ts
├── dto/                  # DTOs de validation
│   ├── create-help-request.dto.ts
│   ├── update-help-request-status.dto.ts
│   ├── create-post.dto.ts
│   ├── create-comment.dto.ts
│   └── create-rating.dto.ts
├── services/             # Services (logique métier)
│   ├── help-request.service.ts
│   ├── community.service.ts
│   └── reputation.service.ts
├── controllers/          # Contrôleurs (endpoints)
│   ├── help-request.controller.ts
│   ├── community.controller.ts
│   └── reputation.controller.ts
└── modules/              # Modules NestJS
    ├── help-request.module.ts
    ├── community.module.ts
    └── reputation.module.ts
```

## 🔧 Étapes d'intégration

### Étape 1 : Ajouter les schémas MongoDB

Copiez les fichiers de `module-communaute/schemas/` dans votre dossier de schémas existant.

**Important** : Vérifiez que votre schéma `User` contient ces champs pour la réputation :
```typescript
trustPoints: number (default: 0)
badges: string[] (default: [])
totalAidesFournies: number (default: 0)
totalAidesRecues: number (default: 0)
noteMoyenne: number (default: 0.0)
```

Si ces champs n'existent pas, ajoutez-les à votre schéma User existant.

### Étape 2 : Créer les collections MongoDB

Les collections suivantes seront créées automatiquement lors de la première utilisation :
- `helprequests`
- `posts`
- `comments`
- `ratings`

### Étape 3 : Ajouter les modules dans votre AppModule

Dans votre `app.module.ts` existant, ajoutez :

```typescript
import { HelpRequestModule } from './help-request/help-request.module';
import { CommunityModule } from './community/community.module';
import { ReputationModule } from './reputation/reputation.module';

@Module({
  imports: [
    // ... vos modules existants
    HelpRequestModule,
    CommunityModule,
    ReputationModule,
  ],
})
export class AppModule {}
```

### Étape 4 : Installer les dépendances (si nécessaire)

Si vous n'avez pas déjà ces packages :
```bash
npm install @nestjs/mongoose mongoose class-validator class-transformer
```

### Étape 5 : Créer les index MongoDB (recommandé)

Pour optimiser les performances, créez ces index dans MongoDB :

```javascript
// Se connecter à MongoDB
use votre_base_de_donnees

// Index pour helprequests
db.helprequests.createIndex({ latitude: 1, longitude: 1 })
db.helprequests.createIndex({ userId: 1 })
db.helprequests.createIndex({ statut: 1 })
db.helprequests.createIndex({ createdAt: -1 })

// Index pour posts
db.posts.createIndex({ userId: 1 })
db.posts.createIndex({ type: 1 })
db.posts.createIndex({ createdAt: -1 })

// Index pour comments
db.comments.createIndex({ postId: 1 })
db.comments.createIndex({ userId: 1 })
db.comments.createIndex({ createdAt: 1 })

// Index pour ratings
db.ratings.createIndex({ ratedUserId: 1 })
db.ratings.createIndex({ raterUserId: 1 })
db.ratings.createIndex({ helpRequestId: 1 })
db.ratings.createIndex({ ratedUserId: 1, raterUserId: 1, helpRequestId: 1 }, { unique: true })
```

### Étape 6 : Adapter l'authentification

Les contrôleurs utilisent `@Request() req` pour obtenir l'utilisateur. Adaptez selon votre système d'auth :

**Si vous utilisez un Guard JWT** :
```typescript
// Dans les contrôleurs, remplacez :
const userId = req.user?.id || req.user?._id || req.body.userId;

// Par :
const userId = req.user.id; // ou req.user._id selon votre structure
```

**Si vous avez un décorateur @CurrentUser()** :
```typescript
// Remplacez :
@Request() req: any

// Par :
@CurrentUser() user: User

// Et utilisez :
const userId = user.id;
```

## 📡 Endpoints créés

### Demandes d'Aide
- `POST /community/help-requests` - Créer une demande
- `GET /community/help-requests` - Liste toutes les demandes
- `GET /community/help-requests/nearby?latitude=X&longitude=Y&maxDistance=Z` - Demandes à proximité
- `GET /community/help-requests/me` - Mes demandes
- `GET /community/help-requests/:id` - Détails
- `POST /community/help-requests/:id/accept` - Accepter (bénévole)
- `PATCH /community/help-requests/:id/statut` - Mettre à jour le statut
- `DELETE /community/help-requests/:id` - Supprimer

### Forums
- `POST /community/posts` - Créer un post
- `GET /community/posts?type=X` - Liste posts (filtrés)
- `GET /community/posts/:id` - Détails
- `POST /community/posts/:id/like` - Liker/unliker
- `DELETE /community/posts/:id` - Supprimer

### Commentaires
- `POST /community/posts/:postId/comments` - Commenter
- `GET /community/posts/:postId/comments` - Liste commentaires
- `DELETE /community/comments/:id` - Supprimer

### Réputation
- `POST /reputation/ratings/:userId` - Évaluer un utilisateur
- `GET /reputation/ratings/user/:userId` - Évaluations reçues
- `GET /reputation/user/:userId` - Profil de réputation complet

## 🔗 Intégration avec votre User existant

Le module réputation utilise votre schéma User existant. Assurez-vous que :

1. **Votre User schema** a ces champs (ou ajoutez-les) :
```typescript
@Prop({ default: 0 })
trustPoints: number;

@Prop({ type: [String], default: [] })
badges: string[];

@Prop({ default: 0 })
totalAidesFournies: number;

@Prop({ default: 0 })
totalAidesRecues: number;

@Prop({ default: 0.0 })
noteMoyenne: number;
```

2. **Le ReputationModule** importe votre User schema :
```typescript
// Dans reputation.module.ts, vérifiez que :
MongooseModule.forFeature([
  { name: Rating.name, schema: RatingSchema },
  { name: User.name, schema: UserSchema }, // Votre User schema
])
```

## 🧪 Tester l'intégration

1. **Créer une demande d'aide** :
```bash
POST /community/help-requests
{
  "description": "Besoin d'accompagnement à la mairie",
  "type": "ACCOMPAGNEMENT",
  "latitude": 36.8065,
  "longitude": 10.1815
}
```

2. **Rechercher à proximité** :
```bash
GET /community/help-requests/nearby?latitude=36.8065&longitude=10.1815&maxDistance=5
```

3. **Créer un post** :
```bash
POST /community/posts
{
  "contenu": "Bonjour, je cherche des conseils...",
  "type": "handicapMoteur"
}
```

## ⚠️ Points d'attention

1. **Authentification** : Adaptez les contrôleurs à votre système d'auth
2. **Structure User** : Vérifiez que les champs de réputation existent
3. **Base de données** : Assurez-vous que MongoDB est configuré
4. **CORS** : Si nécessaire, configurez CORS pour votre app Flutter

## 📝 Notes

- Les timestamps (`createdAt`, `updatedAt`) sont gérés automatiquement par Mongoose
- Les relations (populate) chargent automatiquement les données utilisateur
- La recherche de proximité utilise la formule de Haversine
- Les badges sont attribués automatiquement selon les critères

## 🆘 Dépannage

**Erreur "User schema not found"** :
- Vérifiez que le ReputationModule importe votre User schema

**Erreur "Cannot find module"** :
- Vérifiez les chemins d'import dans les fichiers
- Assurez-vous que tous les fichiers sont dans les bons dossiers

**Les endpoints ne fonctionnent pas** :
- Vérifiez que les modules sont bien importés dans AppModule
- Vérifiez que MongoDB est connecté
- Vérifiez les logs du serveur pour les erreurs

