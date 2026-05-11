# 📱 EXPLICATION COMPLÈTE DU MODULE COMMUNAUTÉ - Ma3ak

## 🎯 Vue d'ensemble

Le module **Communauté** est le cœur social de l'application Ma3ak. Il permet aux utilisateurs de :
- 📝 **Publier des messages** et échanger des conseils
- 🆘 **Créer des demandes d'aide** pour obtenir de l'assistance
- 💬 **Commenter** les publications
- 📍 **Partager des lieux accessibles** (pharmacies, restaurants, etc.)
- ⭐ **Construire une réputation** basée sur l'entraide

---

## 🏗️ Architecture du Module

### Structure de l'Interface

Le module est organisé en **3 onglets principaux** :

```
┌─────────────────────────────────────────┐
│  📍 Lieux    │  💬 Posts  │  🆘 Aide   │
├─────────────────────────────────────────┤
│                                         │
│         Contenu de l'onglet actif      │
│                                         │
└─────────────────────────────────────────┘
```

1. **📍 Lieux accessibles** : Liste des endroits accessibles partagés par la communauté
2. **💬 Publications** : Forum de discussion avec différents types de posts
3. **🆘 Demandes d'aide** : Demandes d'assistance géolocalisées

---

## 📝 1. LES PUBLICATIONS (POSTS)

### Qu'est-ce qu'une publication ?

Une **publication** est un message posté par un utilisateur dans le forum de la communauté. Elle peut être :
- Un **conseil** pour aider d'autres personnes
- Un **témoignage** d'expérience
- Une **question** ou discussion
- Un message **général** sur un sujet

### Types de publications

Le système supporte **8 types** de publications :

| Type | Description | Icône | Couleur |
|------|-------------|-------|---------|
| **Général** | Discussions générales | 💬 Forum | Bleu primaire |
| **Handicap moteur** | Discussions spécifiques | ♿ Accessible | Bleu |
| **Handicap visuel** | Discussions spécifiques | 👁️ Visibilité | Orange |
| **Handicap auditif** | Discussions spécifiques | 👂 Audition | Violet |
| **Handicap cognitif** | Discussions spécifiques | 🧠 Psychologie | Turquoise |
| **Conseil** | Partage de conseils | 💡 Ampoule | Vert |
| **Témoignage** | Partage d'expériences | ❤️ Cœur | Rouge |
| **Autre** | Autres sujets | 💬 Forum | Bleu primaire |

### Comment ça fonctionne ?

#### 📤 Créer une publication

1. **Accéder au formulaire** :
   - Cliquer sur le bouton **"+"** dans l'onglet "Publications"
   - Ou cliquer sur **"Créer une publication"** si la liste est vide

2. **Remplir le formulaire** :
   - **Type** : Choisir parmi les 8 types disponibles
   - **Contenu** : Écrire le message (conseil, question, témoignage, etc.)

3. **Publier** :
   - Cliquer sur **"Publier"**
   - La publication apparaît immédiatement dans la liste

#### 📋 Voir les publications

- **Liste principale** : Affiche toutes les publications avec pagination (20 par page)
- **Filtres** : Possibilité de filtrer par type (boutons en haut)
- **Carte de publication** affiche :
  - 👤 **Auteur** : Nom de l'utilisateur qui a posté
  - 📅 **Date** : "Il y a X heures/jours" ou date complète
  - 🏷️ **Type** : Badge coloré selon le type
  - 📝 **Contenu** : Les 4 premières lignes du message
  - 💬 **Commentaires** : Nombre de commentaires

#### 💬 Commenter une publication

1. **Cliquer sur une publication** pour voir les détails
2. **Voir les commentaires existants** (s'il y en a)
3. **Ajouter un commentaire** :
   - Écrire dans le champ de texte
   - Cliquer sur **"Commenter"**
   - Le commentaire apparaît immédiatement

#### ❤️ Liker une publication

- Cliquer sur le bouton **"J'aime"** (❤️)
- Le nombre de likes s'incrémente
- Un utilisateur ne peut liker qu'une seule fois par publication

### Données stockées

Chaque publication contient :
- **ID unique** : Identifiant dans la base de données
- **userId** : ID de l'utilisateur qui a créé le post
- **contenu** : Le texte du message
- **type** : Le type de publication (général, conseil, etc.)
- **likesCount** : Nombre de likes
- **commentsCount** : Nombre de commentaires
- **createdAt** : Date et heure de création
- **updatedAt** : Date et heure de dernière modification

---

## 🆘 2. LES DEMANDES D'AIDE

### Qu'est-ce qu'une demande d'aide ?

Une **demande d'aide** est une requête d'assistance créée par un utilisateur qui a besoin d'aide pour :
- 🚶 **Accompagnement** : Se rendre quelque part
- 📋 **Aide administrative** : Remplir des formulaires, etc.
- 🛒 **Courses** : Aide pour faire les courses
- 🏥 **Rendez-vous médicaux** : Accompagnement à un rendez-vous
- Etc.

### Statuts d'une demande

Une demande peut avoir **4 statuts** :

| Statut | Description | Couleur | Icône |
|--------|-------------|---------|-------|
| **En attente** | En attente d'un bénévole | 🟠 Orange | ⏰ Horloge |
| **En cours** | Un bénévole a accepté | 🔵 Bleu | 💼 Travail |
| **Terminée** | L'aide a été fournie | 🟢 Vert | ✅ Cercle |
| **Annulée** | La demande a été annulée | ⚫ Gris | ❌ Annuler |

### Comment ça fonctionne ?

#### 📤 Créer une demande d'aide

1. **Accéder au formulaire** :
   - Cliquer sur le bouton **"+"** dans l'onglet "Demandes d'aide"
   - Ou cliquer sur **"Créer une demande"** si la liste est vide

2. **Remplir le formulaire** :
   - **Description** : Décrire le besoin d'aide
   - **Type** (optionnel) : Type d'aide (accompagnement, administratif, etc.)
   - **Adresse** : Adresse où l'aide est nécessaire
   - **Ville** : Ville
   - **Coordonnées GPS** : Automatiquement détectées ou saisies manuellement

3. **Publier** :
   - Cliquer sur **"Créer la demande"**
   - La demande apparaît avec le statut **"En attente"**

#### 📋 Voir les demandes d'aide

- **Liste principale** : Affiche toutes les demandes avec pagination
- **Carte de demande** affiche :
  - 👤 **Auteur** : Nom de l'utilisateur qui a besoin d'aide
  - 📅 **Date** : "Il y a X heures/jours"
  - 🏷️ **Statut** : Badge coloré selon le statut
  - 📝 **Description** : Les 3 premières lignes de la description
  - 📍 **Localisation** : Coordonnées GPS (latitude, longitude)

#### ✅ Accepter une demande

1. **Voir les demandes "En attente"**
2. **Cliquer sur une demande** pour voir les détails
3. **Cliquer sur "Accepter"** :
   - Le statut passe à **"En cours"**
   - Vous êtes maintenant le bénévole assigné
   - L'utilisateur est notifié

#### 📍 Recherche géolocalisée

- **Demandes à proximité** : Le système peut afficher les demandes près de votre position
- **Distance maximale** : Par défaut 10 km (configurable)
- **Tri par distance** : Les plus proches en premier

#### ✏️ Modifier le statut

L'auteur ou le bénévole peut changer le statut :
- **En attente** → **En cours** : Quand un bénévole accepte
- **En cours** → **Terminée** : Quand l'aide est terminée
- **En cours** → **Annulée** : Si la demande est annulée

### Données stockées

Chaque demande d'aide contient :
- **ID unique** : Identifiant dans la base de données
- **userId** : ID de l'utilisateur qui a créé la demande
- **description** : Description du besoin
- **type** : Type d'aide (accompagnement, administratif, etc.)
- **latitude** : Coordonnée GPS latitude
- **longitude** : Coordonnée GPS longitude
- **statut** : Statut actuel (en attente, en cours, etc.)
- **acceptedBy** : ID du bénévole qui a accepté (si applicable)
- **address** : Adresse textuelle (optionnel)
- **city** : Ville (optionnel)
- **createdAt** : Date et heure de création
- **updatedAt** : Date et heure de dernière modification

---

## 📍 3. LES LIEUX ACCESSIBLES

### Qu'est-ce qu'un lieu accessible ?

Un **lieu accessible** est un endroit (pharmacie, restaurant, hôpital, etc.) partagé par la communauté comme étant **accessible aux personnes en situation de handicap**.

### Catégories de lieux

| Catégorie | Description | Exemples |
|-----------|-------------|----------|
| **Pharmacie** | Pharmacies accessibles | Pharmacie Centrale, etc. |
| **Restaurant** | Restaurants accessibles | Restaurants avec rampe, etc. |
| **Hôpital** | Hôpitaux et cliniques | Hôpitaux avec ascenseurs, etc. |
| **École** | Établissements scolaires | Écoles adaptées |
| **Magasin** | Commerces accessibles | Supermarchés, boutiques |
| **Transport public** | Stations de transport | Métro, bus accessibles |
| **Parc** | Espaces verts | Parcs avec chemins adaptés |
| **Autre** | Autres types de lieux | Divers |

### Comment ça fonctionne ?

#### 📤 Soumettre un lieu

1. **Accéder au formulaire** :
   - Cliquer sur le bouton **"+"** dans l'onglet "Lieux accessibles"

2. **Remplir le formulaire** :
   - **Nom** : Nom du lieu (ex: "Pharmacie Centrale")
   - **Catégorie** : Choisir parmi les catégories
   - **Adresse** : Adresse complète
   - **Ville** : Ville
   - **Description** (optionnel) : Détails sur l'accessibilité
   - **Téléphone** (optionnel) : Numéro de téléphone
   - **Horaires** (optionnel) : Horaires d'ouverture
   - **Photos** (optionnel) : Photos du lieu

3. **Soumettre** :
   - Cliquer sur **"Soumettre"**
   - Le lieu est ajouté à la base de données
   - Il apparaît dans la liste (après modération si nécessaire)

#### 📋 Voir les lieux

- **Liste principale** : Affiche tous les lieux avec pagination
- **Filtres** :
  - **Par catégorie** : Filtrer par type de lieu
  - **Recherche textuelle** : Rechercher par nom ou adresse
- **Carte de lieu** affiche :
  - 📍 **Nom** : Nom du lieu
  - 🏷️ **Catégorie** : Badge avec la catégorie
  - 📍 **Adresse** : Adresse complète
  - 📝 **Description** : Description de l'accessibilité
  - ⭐ **Score d'accessibilité** : Note sur 100 (si disponible)

#### 🔍 Recherche géolocalisée

- **Lieux à proximité** : Afficher les lieux près de votre position
- **Distance maximale** : Par défaut 5 km (configurable)
- **Tri par distance** : Les plus proches en premier

### Données stockées

Chaque lieu contient :
- **ID unique** : Identifiant dans la base de données
- **nom** : Nom du lieu
- **typeLieu** : Catégorie (PHARMACY, RESTAURANT, etc.)
- **adresse** : Adresse complète
- **latitude** : Coordonnée GPS latitude
- **longitude** : Coordonnée GPS longitude
- **location** : Objet GeoJSON pour les requêtes géospatiales
- **description** : Description de l'accessibilité
- **scoreAccessibilite** : Note sur 100 (optionnel)
- **rampe** : Présence d'une rampe (booléen)
- **ascenseur** : Présence d'un ascenseur (booléen)
- **toilettesAdaptees** : Présence de toilettes adaptées (booléen)
- **images** : Liste des URLs des photos
- **createdAt** : Date et heure de création
- **updatedAt** : Date et heure de dernière modification

---

## 💬 4. LES COMMENTAIRES

### Qu'est-ce qu'un commentaire ?

Un **commentaire** est une réponse à une publication. Il permet aux utilisateurs de :
- 💬 **Répondre** à une publication
- 💡 **Donner des conseils** supplémentaires
- ❓ **Poser des questions** de suivi
- 🤝 **Partager des expériences** similaires

### Comment ça fonctionne ?

#### ➕ Ajouter un commentaire

1. **Ouvrir une publication** : Cliquer sur une publication pour voir les détails
2. **Voir les commentaires existants** : Liste de tous les commentaires
3. **Écrire un commentaire** :
   - Saisir le texte dans le champ
   - Cliquer sur **"Commenter"** ou appuyer sur Entrée
4. **Le commentaire apparaît** immédiatement dans la liste

#### ❤️ Liker un commentaire

- Cliquer sur le bouton **"J'aime"** (❤️) sous un commentaire
- Le nombre de likes s'incrémente

#### 🗑️ Supprimer un commentaire

- Seul l'auteur du commentaire peut le supprimer
- Cliquer sur **"Supprimer"** (icône poubelle)
- Le commentaire est retiré de la liste

### Données stockées

Chaque commentaire contient :
- **ID unique** : Identifiant dans la base de données
- **postId** : ID de la publication à laquelle il répond
- **userId** : ID de l'utilisateur qui a créé le commentaire
- **contenu** : Le texte du commentaire
- **likesCount** : Nombre de likes
- **createdAt** : Date et heure de création
- **updatedAt** : Date et heure de dernière modification

---

## ⭐ 5. LE SYSTÈME DE RÉPUTATION

### Qu'est-ce que la réputation ?

La **réputation** est un système qui permet de :
- ⭐ **Évaluer les utilisateurs** après une aide fournie
- 🏆 **Attribuer des badges** selon les contributions
- 📊 **Suivre les statistiques** d'entraide
- 🤝 **Construire la confiance** dans la communauté

### Comment ça fonctionne ?

#### ⭐ Évaluer un utilisateur

1. **Après une aide** : Quand une demande d'aide est terminée
2. **Accéder au profil** de l'utilisateur qui a aidé
3. **Donner une note** : De 1 à 5 étoiles
4. **Ajouter un commentaire** (optionnel) : Témoignage sur l'aide
5. **Soumettre** : La note est enregistrée

#### 🏆 Badges

Les utilisateurs peuvent gagner des **badges** selon leurs actions :
- 🥇 **Bénévole actif** : Plus de 10 aides fournies
- ⭐ **Étoile d'or** : Note moyenne supérieure à 4.5/5
- 💬 **Contributeur** : Plus de 50 commentaires
- 📍 **Explorateur** : Plus de 20 lieux partagés

#### 📊 Statistiques

Chaque utilisateur a des statistiques :
- **Note moyenne** : Moyenne de toutes les évaluations reçues
- **Points de confiance** : Points gagnés par les actions positives
- **Total d'aides fournies** : Nombre de demandes acceptées
- **Total d'aides reçues** : Nombre de demandes créées

### Données stockées

Chaque évaluation contient :
- **ID unique** : Identifiant dans la base de données
- **ratedUserId** : ID de l'utilisateur évalué
- **raterUserId** : ID de l'utilisateur qui évalue
- **helpRequestId** : ID de la demande d'aide liée (optionnel)
- **note** : Note de 1 à 5
- **commentaire** : Commentaire (optionnel)
- **verified** : Si l'évaluation est vérifiée (booléen)
- **createdAt** : Date et heure de création

---

## 🔄 6. FLUX UTILISATEUR COMPLET

### Scénario 1 : Publier un conseil

```
1. Utilisateur ouvre l'app → Module Communauté
2. Clique sur l'onglet "Publications"
3. Clique sur le bouton "+"
4. Remplit le formulaire :
   - Type : "Conseil"
   - Contenu : "Voici un conseil pour..."
5. Clique sur "Publier"
6. La publication apparaît dans la liste
7. D'autres utilisateurs peuvent :
   - Voir la publication
   - Commenter
   - Liker
```

### Scénario 2 : Demander de l'aide

```
1. Utilisateur ouvre l'app → Module Communauté
2. Clique sur l'onglet "Demandes d'aide"
3. Clique sur le bouton "+"
4. Remplit le formulaire :
   - Description : "Besoin d'accompagnement à la mairie"
   - Adresse : "Avenue Habib Bourguiba, Tunis"
   - Coordonnées GPS : Détectées automatiquement
5. Clique sur "Créer la demande"
6. La demande apparaît avec le statut "En attente"
7. Un bénévole voit la demande et clique sur "Accepter"
8. Le statut passe à "En cours"
9. Après l'aide, le statut passe à "Terminée"
10. Le bénévole peut être évalué
```

### Scénario 3 : Partager un lieu accessible

```
1. Utilisateur ouvre l'app → Module Communauté
2. Clique sur l'onglet "Lieux accessibles"
3. Clique sur le bouton "+"
4. Remplit le formulaire :
   - Nom : "Pharmacie Centrale"
   - Catégorie : "Pharmacie"
   - Adresse : "Avenue Habib Bourguiba, Tunis"
   - Description : "Pharmacie avec rampe d'accès"
5. Clique sur "Soumettre"
6. Le lieu apparaît dans la liste
7. D'autres utilisateurs peuvent :
   - Voir le lieu
   - Le rechercher par proximité
   - Voir les détails d'accessibilité
```

---

## 🗄️ 7. ARCHITECTURE TECHNIQUE

### Frontend (Flutter)

```
lib/features/community/
├── screens/
│   ├── community_main_screen.dart      # Écran principal avec onglets
│   ├── community_posts_screen.dart     # Liste des publications
│   ├── post_detail_screen.dart         # Détails d'une publication
│   ├── create_post_screen.dart         # Formulaire de création
│   ├── help_requests_screen.dart      # Liste des demandes d'aide
│   ├── create_help_request_screen.dart # Formulaire de création
│   ├── community_locations_screen.dart # Liste des lieux
│   ├── submit_location_screen.dart    # Formulaire de soumission
│   └── location_detail_screen.dart     # Détails d'un lieu
├── providers/
│   └── community_providers.dart        # Riverpod providers
└── repositories/
    └── community_repository.dart       # Appels API
```

### Backend (NestJS)

```
src/community/
├── community.controller.ts    # Endpoints API
├── community.service.ts      # Logique métier
├── community.module.ts       # Module NestJS
└── schemas/
    ├── post.schema.ts        # Schéma MongoDB pour posts
    ├── comment.schema.ts    # Schéma MongoDB pour commentaires
    └── help-request.schema.ts # Schéma MongoDB pour demandes
```

### Base de données (MongoDB)

**Collections** :
- `posts` : Toutes les publications
- `comments` : Tous les commentaires
- `helprequests` : Toutes les demandes d'aide
- `ratings` : Toutes les évaluations
- `lieux` : Tous les lieux accessibles

**Indexes** :
- `posts.userId` : Pour rechercher les posts d'un utilisateur
- `posts.type` : Pour filtrer par type
- `helprequests.location` : Index géospatial pour la recherche de proximité
- `lieux.location` : Index géospatial pour la recherche de proximité

---

## 🔐 8. SÉCURITÉ ET PERMISSIONS

### Authentification

- **Toutes les actions** nécessitent d'être connecté
- **Token JWT** : Chaque requête inclut un token d'authentification
- **Intercepteur HTTP** : Ajoute automatiquement le token

### Permissions

- **Créer** : Tous les utilisateurs connectés peuvent créer
- **Modifier** : Seul l'auteur peut modifier sa publication/demande
- **Supprimer** : Seul l'auteur peut supprimer
- **Commenter** : Tous les utilisateurs connectés peuvent commenter
- **Liker** : Tous les utilisateurs connectés peuvent liker

---

## 📊 9. PAGINATION ET PERFORMANCE

### Pagination

- **Publications** : 20 par page (configurable)
- **Demandes d'aide** : 20 par page (configurable)
- **Lieux** : 20 par page (configurable)
- **Commentaires** : Tous chargés (pas de pagination)

### Optimisations

- **Lazy loading** : Chargement à la demande
- **Cache** : Les données sont mises en cache par Riverpod
- **Invalidation** : Rafraîchissement automatique après création/modification
- **Indexes MongoDB** : Requêtes optimisées avec indexes

---

## 🎨 10. INTERFACE UTILISATEUR

### Design

- **Material Design 3** : Interface moderne et accessible
- **Thème adaptatif** : S'adapte au thème clair/sombre
- **Couleurs par type** : Chaque type a sa couleur pour faciliter l'identification
- **Icônes intuitives** : Icônes Material Design pour chaque action

### Expérience utilisateur

- **Pull-to-refresh** : Tirer vers le bas pour rafraîchir
- **Navigation fluide** : Navigation entre les écrans
- **Feedback visuel** : Messages de succès/erreur
- **États de chargement** : Indicateurs de chargement
- **Gestion d'erreurs** : Messages d'erreur clairs

---

## 🚀 11. FONCTIONNALITÉS AVANCÉES

### Recherche géolocalisée

- **Demandes d'aide à proximité** : Trouver les demandes près de vous
- **Lieux à proximité** : Trouver les lieux accessibles près de vous
- **Distance maximale** : Configurable (par défaut 5-10 km)

### Notifications (à venir)

- Notification quand quelqu'un commente votre publication
- Notification quand quelqu'un accepte votre demande d'aide
- Notification quand quelqu'un évalue votre aide

### Statistiques (à venir)

- Nombre de publications créées
- Nombre de commentaires écrits
- Nombre de demandes d'aide créées/acceptées
- Score de réputation

---

## 📝 12. RÉSUMÉ

Le module **Communauté** est un système complet qui permet :

✅ **Publications** : Forum de discussion avec 8 types de posts
✅ **Commentaires** : Système de commentaires avec likes
✅ **Demandes d'aide** : Système d'entraide géolocalisé avec statuts
✅ **Lieux accessibles** : Partage de lieux accessibles avec recherche géolocalisée
✅ **Réputation** : Système d'évaluation et de badges
✅ **Pagination** : Gestion efficace des grandes listes
✅ **Sécurité** : Authentification et permissions
✅ **Interface moderne** : Design Material Design 3

---

## 🔗 13. ENDPOINTS API

### Publications

- `POST /community/posts` : Créer une publication
- `GET /community/posts` : Liste des publications (pagination)
- `GET /community/posts/:id` : Détails d'une publication
- `POST /community/posts/:id/like` : Liker une publication
- `DELETE /community/posts/:id` : Supprimer une publication

### Commentaires

- `POST /community/posts/:postId/comments` : Créer un commentaire
- `GET /community/posts/:postId/comments` : Liste des commentaires
- `DELETE /community/comments/:id` : Supprimer un commentaire

### Demandes d'aide

- `POST /community/help-requests` : Créer une demande
- `GET /community/help-requests` : Liste des demandes (pagination)
- `GET /community/help-requests/nearby` : Demandes à proximité
- `GET /community/help-requests/me` : Mes demandes
- `GET /community/help-requests/:id` : Détails d'une demande
- `POST /community/help-requests/:id/accept` : Accepter une demande
- `POST /community/help-requests/:id/statut` : Modifier le statut
- `DELETE /community/help-requests/:id` : Supprimer une demande

### Lieux

- `POST /lieux` : Créer un lieu
- `GET /lieux` : Liste des lieux (pagination)
- `GET /lieux/nearby` : Lieux à proximité
- `GET /lieux/:id` : Détails d'un lieu
- `PATCH /lieux/:id` : Modifier un lieu
- `DELETE /lieux/:id` : Supprimer un lieu

### Réputation

- `POST /reputation/ratings/:userId` : Évaluer un utilisateur
- `GET /reputation/user/:userId` : Profil de réputation

---

**Document créé le** : 2026-02-19  
**Version** : 1.0  
**Application** : Ma3ak - Module Communauté

