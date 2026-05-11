# Guide de Connexion - Frontend Flutter

## 🔧 Configuration de l'URL API

Le backend tourne sur le **port 3000**, pas 5000.

### Pour l'émulateur Android

L'app Flutter utilise automatiquement `http://10.0.2.2:3000` (c'est correct ✅)

### Pour un appareil physique ou web

Vous devez spécifier l'URL du backend :

```bash
# Lancer avec l'URL du backend
flutter run --dart-define=API_BASE_URL=http://localhost:3000

# Ou si vous êtes sur le même réseau WiFi
flutter run --dart-define=API_BASE_URL=http://192.168.1.XXX:3000
```

### Trouver l'IP de votre PC

```powershell
ipconfig
# Cherchez "IPv4 Address" (ex: 192.168.1.100)
```

## 🔐 Identifiants de test

### Utilisateur HANDICAPE
```
Email: test@ma3ak.tn
Password: test123
```

### Utilisateur ACCOMPAGNANT
```
Email: benevole@ma3ak.tn
Password: benevole123
```

## ✅ Vérifications

1. **Backend actif** : `http://localhost:3000` doit répondre
2. **Swagger** : `http://localhost:3000/api` doit s'ouvrir
3. **CORS** : Le backend accepte les requêtes depuis le frontend
4. **URL API** : L'app Flutter doit pointer vers le port 3000

## 🐛 Dépannage

### Erreur "Unable to connect"
- Vérifiez que le backend tourne : `curl http://localhost:3000`
- Vérifiez l'URL dans l'app Flutter
- Vérifiez les logs du backend pour les erreurs CORS

### Erreur 401 Unauthorized
- Vérifiez que l'email et le mot de passe sont corrects
- Vérifiez que l'utilisateur existe dans MongoDB

### Erreur CORS
- Le backend accepte maintenant toutes les origines pour le développement
- Redémarrez le backend après les modifications CORS

