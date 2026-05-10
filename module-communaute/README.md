# Module Communauté - Fichiers à intégrer

Ce dossier contient tous les fichiers nécessaires pour ajouter le module communauté à votre backend existant.

## 📁 Structure

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

## 🚀 Instructions rapides

1. **Copiez les fichiers** dans votre backend existant selon votre structure
2. **Ajoutez les modules** dans votre `app.module.ts`
3. **Vérifiez votre schéma User** - ajoutez les champs de réputation si nécessaire
4. **Adaptez l'authentification** dans les contrôleurs selon votre système
5. **Créez les index MongoDB** (voir guide d'intégration)

Consultez `../INTEGRATION_MODULE_COMMUNAUTE.md` pour le guide complet.




