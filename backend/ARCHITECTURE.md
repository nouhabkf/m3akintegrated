# Architecture du Backend - Application Ma3ak

## 🏗️ Vue d'ensemble

Le backend NestJS gère trois modules principaux qui nécessitent une base de données persistante :

1. **Demandes d'Aide** - Stockage permanent des demandes avec géolocalisation
2. **Forums et Discussions** - Messages et commentaires par type de handicap
3. **Système de Réputation** - Notes, badges et points de confiance

## 📊 Flux de Données

### 1. Création d'une Demande d'Aide

```
Flutter App
    ↓ POST /community/help-requests
NestJS Controller
    ↓ Validation (DTO)
HelpRequestService
    ↓ Création document
MongoDB (Collection: helprequests)
    ↓ Sauvegarde permanente
```

**Données stockées** :
- Description du besoin
- Type d'aide (ACCOMPAGNEMENT, ADMINISTRATIF, etc.)
- Géolocalisation (latitude, longitude)
- Statut (EN_ATTENTE, EN_COURS, TERMINEE, ANNULEE)
- Référence à l'utilisateur demandeur
- Référence au bénévole acceptant (si applicable)

### 2. Recherche de Demandes à Proximité

```
Bénévole ouvre l'app
    ↓ GET /community/help-requests/nearby?latitude=X&longitude=Y
HelpRequestService.findNearby()
    ↓ Calcul de distance (Haversine)
MongoDB Query (filtre par statut EN_ATTENTE)
    ↓ Tri par distance
Retour des demandes à proximité
```

**Pourquoi la base de données est essentielle** :
- Les demandes doivent être disponibles même après fermeture de l'app
- Les bénévoles doivent voir les demandes créées par d'autres utilisateurs
- L'historique des demandes est conservé

### 3. Publication dans un Forum

```
Utilisateur publie un post
    ↓ POST /community/posts
CommunityService.createPost()
    ↓ Création document
MongoDB (Collection: posts)
    ↓ Sauvegarde permanente
```

**Données stockées** :
- Contenu du message
- Type de handicap (handicapMoteur, handicapVisuel, etc.)
- Référence à l'utilisateur auteur
- Compteurs (likesCount, commentsCount)
- Timestamp (createdAt)

**Commentaires** :
- Stockés dans la collection `comments`
- Liés au post via `postId`
- Compteur mis à jour automatiquement dans le post

### 4. Système de Réputation

```
Bénévole termine une aide
    ↓ PATCH /community/help-requests/:id/statut (TERMINEE)
HelpRequestService.updateStatus()
    ↓ Incrémente statistiques
ReputationService.incrementAidesFournies()
    ↓ Mise à jour utilisateur
MongoDB (Collection: users)
    ↓ totalAidesFournies++, trustPoints++
```

**Évaluation** :
```
Utilisateur évalue le bénévole
    ↓ POST /reputation/ratings/:userId
ReputationService.createRating()
    ↓ Calcul note moyenne
MongoDB (Collection: ratings + users)
    ↓ Sauvegarde évaluation + mise à jour noteMoyenne
ReputationService.checkAndAssignBadges()
    ↓ Attribution automatique de badges
```

## 🔄 Intégration entre Modules

### HelpRequest ↔ Reputation

Quand une demande est marquée comme `TERMINEE` :
1. `HelpRequestService` appelle `ReputationService.incrementAidesFournies()` pour le bénévole
2. `HelpRequestService` appelle `ReputationService.incrementAidesRecues()` pour le demandeur
3. Les badges sont vérifiés automatiquement

### Rating ↔ User

Quand une évaluation est créée :
1. La note moyenne est recalculée automatiquement
2. Les points de confiance sont ajoutés/soustraits
3. Les badges sont vérifiés et attribués si les critères sont remplis

## 🗄️ Structure de la Base de Données

### Collection: users

```javascript
{
  _id: ObjectId,
  nom: String,
  prenom: String,
  email: String (unique),
  role: "HANDICAPE" | "ACCOMPAGNANT" | "ADMIN",
  // Réputation
  noteMoyenne: Number (0-5),
  trustPoints: Number,
  badges: [String],
  totalAidesFournies: Number,
  totalAidesRecues: Number,
  // Autres champs...
  createdAt: Date,
  updatedAt: Date
}
```

### Collection: helprequests

```javascript
{
  _id: ObjectId,
  userId: ObjectId (ref: users),
  description: String,
  type: "ACCOMPAGNEMENT" | "ADMINISTRATIF" | "TRANSPORT" | "AUTRE",
  latitude: Number,
  longitude: Number,
  statut: "EN_ATTENTE" | "EN_COURS" | "TERMINEE" | "ANNULEE",
  acceptedBy: ObjectId? (ref: users),
  address: String?,
  city: String?,
  createdAt: Date,
  updatedAt: Date
}
```

### Collection: posts

```javascript
{
  _id: ObjectId,
  userId: ObjectId (ref: users),
  contenu: String,
  type: "general" | "handicapMoteur" | "handicapVisuel" | ...,
  likesCount: Number,
  commentsCount: Number,
  likedBy: [ObjectId] (ref: users),
  createdAt: Date,
  updatedAt: Date
}
```

### Collection: comments

```javascript
{
  _id: ObjectId,
  postId: ObjectId (ref: posts),
  userId: ObjectId (ref: users),
  contenu: String,
  likesCount: Number,
  likedBy: [ObjectId] (ref: users),
  createdAt: Date,
  updatedAt: Date
}
```

### Collection: ratings

```javascript
{
  _id: ObjectId,
  ratedUserId: ObjectId (ref: users), // Bénévole évalué
  raterUserId: ObjectId (ref: users), // Utilisateur qui évalue
  helpRequestId: ObjectId? (ref: helprequests),
  note: Number (1-5),
  commentaire: String?,
  verified: Boolean, // true si associé à une demande d'aide
  createdAt: Date,
  updatedAt: Date
}
```

## 🔍 Index MongoDB

Pour optimiser les performances :

```javascript
// helprequests
{ latitude: 1, longitude: 1 } // Recherche géospatiale
{ userId: 1 } // Demandes d'un utilisateur
{ statut: 1 } // Filtrage par statut
{ createdAt: -1 } // Tri chronologique

// posts
{ userId: 1 } // Posts d'un utilisateur
{ type: 1 } // Filtrage par type de handicap
{ createdAt: -1 } // Tri chronologique

// comments
{ postId: 1 } // Commentaires d'un post
{ userId: 1 } // Commentaires d'un utilisateur

// ratings
{ ratedUserId: 1 } // Évaluations reçues
{ raterUserId: 1 } // Évaluations données
{ ratedUserId: 1, raterUserId: 1, helpRequestId: 1 } // Unique (empêcher doublons)
```

## 🎯 Points Clés

### Pourquoi MongoDB est indispensable

1. **Persistance** : Sans base de données, toutes les données disparaissent à la fermeture de l'app
2. **Partage** : Les utilisateurs doivent voir les données créées par d'autres
3. **Historique** : Conservation des demandes, posts et évaluations passés
4. **Recherche** : Indexation pour recherches rapides (proximité, type, etc.)
5. **Relations** : Références entre collections (user → helpRequest → rating)

### Sécurité des Données

- Validation des données avec `class-validator`
- Vérification des permissions (propriétaire peut supprimer)
- Empêcher l'auto-évaluation
- Empêcher les doublons d'évaluation

### Performance

- Index MongoDB pour accélérer les requêtes
- Populate pour charger les relations efficacement
- Calcul de distance optimisé (peut être amélioré avec MongoDB Geospatial)

## 🚀 Prochaines Étapes

1. **Authentification JWT** : Protéger les routes
2. **MongoDB Geospatial** : Utiliser `$near` pour recherches de proximité natives
3. **Notifications** : Système de notifications en temps réel
4. **Cache** : Redis pour améliorer les performances
5. **Tests** : Tests unitaires et d'intégration




