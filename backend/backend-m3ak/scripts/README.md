# Scripts Ma3ak

## Seed de la base de données

Remplit la base avec des utilisateurs de démo inspirés de **Friends** (voir commentaire en tête de `seed.js`).

- **Email** : `prenom.nom@gmail.com` (ex. `rachel.green@gmail.com`)
- **Mot de passe** : identique à l’email

Le script crée aussi des **véhicules** de démo pour les chauffeurs solidaires.

### Prérequis

- MongoDB (local ou **MongoDB Atlas**)
- Fichier `.env` à la racine avec la connexion MongoDB

### Connexion MongoDB Atlas

Dans `.env`, utilisez soit une URI complète, soit les variables Atlas :

```env
# Option A : URI Atlas (depuis le bouton "Connect" > "Connect your application")
MONGODB_URI=mongodb+srv://USER:PASSWORD@cluster0.xxxxx.mongodb.net/ma3ak?retryWrites=true&w=majority

# Option B : variables séparées (même logique que l’API NestJS)
DB_USERNAME=votre_utilisateur
DB_PASSWORD=votre_mot_de_passe
DB_CLUSTER=cluster0.xxxxx.mongodb.net
DB_NAME=ma3ak
```

Sur Atlas : **Network Access** → autoriser votre IP (ou `0.0.0.0/0` pour tester). **Database Access** → utilisateur avec droit readWrite sur la base.

### Lancer le seed

```bash
# À la racine du projet (lit .env)
npm run seed
```

Ou avec le script shell (depuis n’importe quel dossier) :

```bash
./scripts/seed.sh
# ou
bash scripts/seed.sh
```

Ou avec une URI explicite :

```bash
MONGODB_URI=mongodb://localhost:27017/ma3ak node scripts/seed.js
```

Les utilisateurs déjà présents (même email) sont ignorés ; seules les nouvelles données sont ajoutées.
