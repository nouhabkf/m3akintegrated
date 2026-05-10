# Prompt Ma3ak — Backoffice Web Admin (changements API 2025)

> Donne ce prompt à l'IA qui développe le backoffice web Ma3ak. Il décrit les changements récents du backend.

---

## Contexte

L'API backend Ma3ak a été restructurée. Le backoffice admin doit être mis à jour pour consommer la nouvelle API.

**Base URL API :** `http://localhost:3000` (ou l'URL de production)

**Swagger :** `http://localhost:3000/api` — documentation complète.

---

## 1. Authentification

- `POST /auth/login` — Body : `{ email, password }`  
  Réponse : `{ access_token, user }`
- Header requis pour les routes protégées : `Authorization: Bearer <access_token>`
- Seuls les utilisateurs avec `role: "ADMIN"` peuvent accéder au backoffice.

---

## 2. Changements User (CRUD Admin)

### Nouveaux rôles

| Ancien | Nouveau |
|--------|---------|
| `BENEFICIARY` | `HANDICAPE` |
| `COMPANION` | `ACCOMPAGNANT` |
| `ADMIN` | `ADMIN` |

### Nouveau schéma User

```typescript
interface User {
  _id: string;
  nom: string;           // Nom de famille
  prenom: string;        // Prénom
  email: string;
  telephone?: string;
  role: 'HANDICAPE' | 'ACCOMPAGNANT' | 'ADMIN';
  typeHandicap?: string;
  besoinSpecifique?: string;
  animalAssistance: boolean;
  typeAccompagnant?: string;
  specialisation?: string;
  disponible: boolean;
  noteMoyenne: number;
  langue: string;
  photoProfil?: string;
  statut: string;
  createdAt?: string;
  updatedAt?: string;
}
```

### Endpoints Admin (inchangés, données mises à jour)

- `GET /admin/users` — Liste paginée  
  Query : `page`, `limit`, `role` (HANDICAPE | ACCOMPAGNANT | ADMIN), `search`  
  Réponse : `{ data: User[], total, page, limit, totalPages }`
- `GET /admin/users/:id` — Détail
- `POST /admin/users` — Créer (CreateUserDto)
- `PATCH /admin/users/:id` — Modifier (UpdateUserDto)
- `DELETE /admin/users/:id` — Supprimer

### CreateUserDto (inscription / création admin)

```typescript
{
  nom: string;
  prenom: string;
  email: string;
  password: string;
  telephone?: string;
  role: 'HANDICAPE' | 'ACCOMPAGNANT' | 'ADMIN';
  typeHandicap?: string;
  besoinSpecifique?: string;
  animalAssistance?: boolean;
  typeAccompagnant?: string;
  specialisation?: string;
  disponible?: boolean;
  langue?: string;
  statut?: string;
}
```

### UpdateUserDto

Tous les champs sont optionnels : `nom`, `prenom`, `telephone`, `role`, `typeHandicap`, `besoinSpecifique`, `animalAssistance`, `typeAccompagnant`, `specialisation`, `disponible`, `langue`, `statut`.

---

## 3. Tâches prioritaires pour le backoffice

1. **CRUD Utilisateurs**
   - Adapter les formulaires création/édition aux nouveaux champs (nom, prenom, telephone, typeHandicap, besoinSpecifique, animalAssistance, typeAccompagnant, specialisation, disponible, noteMoyenne, langue, statut).
   - Mettre à jour les filtres par rôle : HANDICAPE, ACCOMPAGNANT, ADMIN.
   - Afficher `photoProfil` au lieu de `image`.

2. **Gestion des lieux** (optionnel, selon besoins)
   - `GET /lieux` — Liste des lieux accessibles.
   - `POST /lieux` — Créer un lieu (champs : nom, adresse, typeLieu, latitude, longitude, description, scoreAccessibilite, rampe, ascenseur, toilettesAdaptees).
   - `PATCH /lieux/:id`, `DELETE /lieux/:id`.

3. **Gestion des modules éducatifs** (optionnel)
   - `GET /education/modules`
   - `POST /education/modules` — Body : `{ titre, type: "BRAILLE" | "LANGUE_SIGNES", niveau, description? }`

4. **Tableau de bord**
   - Afficher des statistiques (nombre d’utilisateurs par rôle, demandes de transport, alertes SOS, etc.) si des endpoints dédiés sont ajoutés côté backend.

---

## 4. Codes HTTP

| Code | Signification |
|------|---------------|
| 200 / 201 | Succès |
| 400 | Données invalides |
| 401 | Non authentifié |
| 403 | Accès refusé (rôle ADMIN requis) |
| 404 | Ressource non trouvée |
| 409 | Conflit (email déjà utilisé) |

---

## 5. Structure des réponses

### Liste paginée (ex. GET /admin/users)

```json
{
  "data": [ /* User[] */ ],
  "total": 42,
  "page": 1,
  "limit": 10,
  "totalPages": 5
}
```

### Erreur de validation (400)

```json
{
  "message": ["email must be an email", "nom must be longer than 2 characters"],
  "error": "Bad Request",
  "statusCode": 400
}
```

---

## 6. Notes

- Les anciens rôles `BENEFICIARY` et `COMPANION` n’existent plus — utiliser `HANDICAPE` et `ACCOMPAGNANT`.
- Le champ `contact` a été remplacé par `telephone`.
- Le champ `image` a été remplacé par `photoProfil`.
- Le champ `nom` contient désormais uniquement le nom de famille ; le prénom est dans `prenom`.
- Pour créer un compte admin : `POST /user/register` avec `"role": "ADMIN"` (ou modifier un utilisateur existant en base).
