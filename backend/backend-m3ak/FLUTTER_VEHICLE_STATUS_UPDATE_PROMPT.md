# Prompt Ma3ak — Mise à jour du statut des véhicules (Flutter)

> Donne ce prompt à l'IA qui développe l'application mobile Flutter Ma3ak. Il décrit les nouvelles règles d'autorisation pour la modification du statut des véhicules (PATCH /vehicles/:id).

---

## Contexte

Le backend Ma3ak a été mis à jour pour autoriser certains accompagnants et les administrateurs à modifier le **statut** des véhicules (validation/refus des véhicules en attente). L'application Flutter doit adapter l'UI et la logique pour refléter ces permissions.

**Endpoint concerné :** `PATCH /vehicles/:id`

**Header requis :** `Authorization: Bearer <access_token>`

---

## 1. Règles d'autorisation (backend)

| Profil utilisateur | Peut modifier | Champs autorisés |
|--------------------|---------------|------------------|
| **Propriétaire** du véhicule | Son propre véhicule | Tous (marque, modèle, immatriculation, accessibilité, photos, **statut**) |
| **ADMIN** | Tous les véhicules | Tous (marque, modèle, immatriculation, accessibilité, photos, **statut**) |
| **ACCOMPAGNANT** avec `typeAccompagnant: "Chauffeurs solidaires"` | Tous les véhicules | **Statut uniquement** (EN_ATTENTE, VALIDE, REFUSE) |
| Autres (HANDICAPE, ACCOMPAGNANT autre type) | — | **403 Forbidden** |

### Valeur exacte à vérifier

Pour autoriser la modification du statut, l'accompagnant doit avoir :
- `role == "ACCOMPAGNANT"`
- `typeAccompagnant == "Chauffeurs solidaires"` (chaîne exacte)

---

## 2. Statuts possibles (VehicleStatut)

```dart
enum VehicleStatut {
  EN_ATTENTE,  // En attente de validation
  VALIDE,      // Validé
  REFUSE,      // Refusé
}
```

---

## 3. Comportement attendu côté Flutter

### 3.1 Détection des droits

Créer une fonction utilitaire qui détermine ce que l'utilisateur connecté peut faire sur un véhicule donné :

```dart
/// Retourne les permissions de modification pour un véhicule
class VehicleEditPermissions {
  final bool canEditAll;    // Propriétaire ou Admin : modifier tout
  final bool canEditStatus; // Chauffeur solidaire : modifier uniquement le statut
  final bool canEdit;       // Au moins une permission

  static VehicleEditPermissions fromUserAndVehicle(User user, Vehicle vehicle) {
    final isOwner = vehicle.ownerId == user.id;
    final isAdmin = user.role == 'ADMIN';
    final isChauffeurSolidaire = user.role == 'ACCOMPAGNANT' && 
        user.typeAccompagnant == 'Chauffeurs solidaires';

    final canEditAll = isOwner || isAdmin;
    final canEditStatus = canEditAll || isChauffeurSolidaire;

    return VehicleEditPermissions(
      canEditAll: canEditAll,
      canEditStatus: canEditStatus,
      canEdit: canEditStatus,
    );
  }
}
```

### 3.2 Écran détail véhicule

- **Propriétaire / Admin** : afficher le bouton « Modifier » (formulaire complet).
- **Chauffeur solidaire** : afficher uniquement un sélecteur ou des boutons pour changer le **statut** (EN_ATTENTE → VALIDE ou REFUSE), sans accès aux autres champs.
- **Autres** : ne pas afficher de bouton de modification.

### 3.3 Liste des véhicules (pour Chauffeurs solidaires / Admin)

- Afficher une colonne ou un badge « Statut » sur chaque carte véhicule.
- Pour les véhicules en `EN_ATTENTE`, afficher des actions rapides : « Valider » (→ VALIDE), « Refuser » (→ REFUSE).
- Appeler `PATCH /vehicles/:id` avec uniquement `{ "statut": "VALIDE" }` ou `{ "statut": "REFUSE" }`.

### 3.4 Gestion des erreurs

| Code HTTP | Signification | Message suggéré |
|-----------|---------------|-----------------|
| 403 | Accès refusé | « Vous n'avez pas l'autorisation de modifier ce véhicule. » |
| 403 (Chauffeur solidaire + autres champs) | Seul le statut peut être modifié | « Seul le statut peut être modifié par un Chauffeur solidaire. » |
| 401 | Non authentifié | Rediriger vers la connexion |
| 404 | Véhicule non trouvé | « Véhicule introuvable. » |

---

## 4. Exemple d'appel API (mise à jour du statut uniquement)

```dart
Future<Vehicle> updateVehicleStatus(String vehicleId, VehicleStatut newStatut) async {
  final response = await http.patch(
    Uri.parse('$baseUrl/vehicles/$vehicleId'),
    headers: {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({'statut': newStatut.name}),
  );

  if (response.statusCode == 200) {
    return Vehicle.fromJson(jsonDecode(response.body));
  }
  if (response.statusCode == 403) {
    throw Exception('Accès refusé');
  }
  // ... autres cas
}
```

---

## 5. UI recommandée pour « Chauffeurs solidaires »

### Boutons de changement de statut (véhicule EN_ATTENTE)

```
┌─────────────────────────────────────────┐
│ Véhicule Toyota Yaris - 123-456-78      │
│ Propriétaire : Ahmed B.                 │
│ Statut : EN_ATTENTE                     │
│                                         │
│  [ Valider ✓ ]    [ Refuser ✗ ]         │
└─────────────────────────────────────────┘
```

- **Valider** : `PATCH /vehicles/:id` avec `{ "statut": "VALIDE" }`
- **Refuser** : `PATCH /vehicles/:id` avec `{ "statut": "REFUSE" }`

---

## 6. Récapitulatif des tâches Flutter

1. Ajouter `typeAccompagnant` au modèle `User` si absent.
2. Créer `VehicleEditPermissions` (ou équivalent) pour déterminer les droits.
3. Dans l'écran détail véhicule : afficher conditionnellement le formulaire complet ou uniquement le sélecteur de statut.
4. Dans la liste des véhicules (pour Chauffeurs solidaires / Admin) : ajouter les actions rapides Valider / Refuser pour les véhicules EN_ATTENTE.
5. Gérer l'erreur 403 avec un message approprié.
6. Vérifier que le profil utilisateur « Chauffeurs solidaires » est bien proposé lors de l'inscription des accompagnants (enum ou liste prédéfinie incluant « Chauffeurs solidaires »).

---

## 7. Référence backend

- **Swagger :** `http://localhost:3000/api` — endpoint `PATCH /vehicles/{id}`
- **Fichiers backend :** `src/vehicle/vehicle.controller.ts`, `src/vehicle/vehicle.service.ts`
