# Ma3ak — Application mobile Flutter

Documentation technique et fonctionnelle du **frontend** principal (`frontend/appm3ak/appm3ak`). L’application **Ma3ak** vise la mobilité, l’autonomie et l’inclusion des personnes en situation de handicap en Tunisie et de leurs accompagnants.

---

## 1. Vue d’ensemble

| Élément | Détail |
|--------|--------|
| **Framework** | Flutter (SDK Dart ^3.10) |
| **État global** | Riverpod (`flutter_riverpod`) |
| **Navigation** | `go_router` avec garde d’auth et redirections |
| **HTTP** | `dio` via une couche `ApiClient` + JWT dans `flutter_secure_storage` |
| **Thème** | Clair / sombre (`theme_provider`) |
| **i18n** | Chaînes centralisées (`core/l10n/app_strings.dart`) selon la langue préférée utilisateur |
| **API** | Backend NestJS documenté dans `backend/backend-m3ak 2/README.md` |

---

## 2. Structure des dossiers (`lib/`)

```
lib/
├── main.dart                 # Point d’entrée, ProviderScope, init volume Android
├── app.dart                  # MaterialApp.router, thème, M3akGlobalAssistantLayer
├── core/
│   ├── config/               # AppConfig : API_BASE_URL, ALLOW_GUEST, FORCE_LOGIN_ON_START
│   ├── l10n/                 # AppStrings (FR/AR selon profil)
│   ├── theme/                # AppTheme
│   ├── widgets/              # Composants partagés
│   ├── location/             # Position courante (géoloc)
│   └── volume/               # Hub volume Android (raccourcis accessibilité)
├── data/
│   ├── api/                  # ApiClient, Endpoints (chemins REST alignés backend)
│   ├── models/               # User, posts, SOS, lieux, etc.
│   └── repositories/         # Auth, user, community, SOS, transport, medical, emergency, location
├── providers/
│   ├── api_providers.dart    # ApiClient, repositories « transverses »
│   ├── auth_providers.dart   # AuthStateNotifier, login / Google / refresh profil
│   ├── community_providers.dart
│   ├── health_providers.dart
│   └── theme_provider.dart
├── router/
│   └── app_router.dart       # Toutes les routes GoRouter + redirect auth
├── features/                 # Écrans par domaine métier
│   ├── auth/                 # Splash, login, register
│   ├── home/                 # MainShell, onglets Accueil / Santé / Transport / Milieux / Profil
│   ├── health/               # Onglet santé, chat IA santé (HealthAiChatScreen)
│   ├── community/            # Hub communauté, posts, lieux, demandes d’aide, accessibilité moteur
│   ├── profile/              # Profil
│   ├── sos/                  # Alertes SOS
│   ├── medical/              # Dossier médical, détection posture (expérimental)
│   ├── accompaniment/        # Contacts urgence, demandes transport
│   ├── m3ak/                 # Page inclusion (point d’entrée vers port M3AK)
│   └── accessibility/        # Création de post sans tactile classique (vibration, geste, voix)
├── m3ak_port/                # Module « inclusion » : LSF, gestes, Braille, visages, défis, API /m3ak
├── m3ak_assist/              # Assistant global vocal (TTS/STT), navigation vocale, lancement création post
```

---

## 3. Configuration et exécution

### Variables (`--dart-define`)

| Variable | Rôle |
|----------|------|
| `API_BASE_URL` | URL du backend (ex. `http://192.168.1.10:3000` sur téléphone physique). Si vide, défaut plateforme : Android émulateur → `http://10.0.2.2:3000`, sinon `http://localhost:3000` (`app_config_io.dart`). |
| `ALLOW_GUEST=true` | Mode invité : navigation sans login (redirect vers `/home`). |
| `FORCE_LOGIN_ON_START=true` | Force déconnexion au démarrage (démo). |

### Commandes usuelles

```bash
cd frontend/appm3ak/appm3ak
flutter pub get
flutter run
# Exemple avec API distante :
flutter run --dart-define=API_BASE_URL=http://IP_DU_PC:3000
```

### Dépendances notables (`pubspec.yaml`)

- **Réseau / sécurité** : `dio`, `flutter_secure_storage`, `shared_preferences`
- **Auth Google** : `google_sign_in`
- **Médias / ML** : `camera`, `google_ml_kit`, `tflite_flutter`, `image_picker`
- **Accessibilité** : `flutter_tts`, `speech_to_text`, `vibration`, `sensors_plus`
- **Géoloc** : `geolocator`
- **Navigation** : `go_router`

---

## 4. Authentification et navigation

### Flux

1. **Splash** (`/`) : chargement de l’état auth (`authStateProvider`).
2. **Sans token** : routes publiques `/`, `/login`, `/register` ; toute autre route → `/login`.
3. **Avec token valide** : `GET /user/me` ; utilisateur chargé.
4. **Token invalide** : logout silencieux.
5. **`AppConfig.allowGuest`** : bypass login, redirection `/home` depuis splash/login/register.

### `GoRouter` (`router/app_router.dart`)

- **Shell principal** : `/home?tab=0..4` — `MainShell` avec `initialIndex` et option `communityTab` pour le sous-onglet « Milieux ».
- **Profil** : `/profile`, `/profile-edit`.
- **Communauté** : `/community-posts`, `/create-post` (extra : texte initial, `M3akCreatePostLaunch`, `AccessibilityPostHandoff`), `/post-detail/:id`, `/help-requests`, `/create-help-request`, `/community-locations`, `/community-nearby`, `/community-contacts`, `/location-detail/:id`, `/submit-location`, `/haptic-help`.
- **Accessibilité création de post** : `/create-post-head-gesture`, `/create-post-vibration`, `/create-post-voice-vibration`.
- **Santé** : `/health-chat` (avec `HealthChatLaunch`), redirect `/sante` → `/home?tab=1`.
- **Autres** : `/accompagnants`, `/beneficiaires`, `/medical-record`, `/sos-alerts`, `/activity-posture-detection`, `/m3ak-inclusion`.

---

## 5. Shell principal (`MainShell`)

Barre du bas à **5 onglets** :

| Index | Libellé (concept) | Contenu |
|-------|-------------------|---------|
| 0 | Accueil | `HomeTab` si utilisateur **bénéficiaire** (`isBeneficiary`), sinon `HomeCompanionTab` pour accompagnant. |
| 1 | Santé | `HealthTabScreen` — santé, liens vers chat IA santé. |
| 2 | Transport | Placeholder (transport détaillé peut être branché ailleurs : `/beneficiaires`, repositories transport). |
| 3 | Milieux | `M3akCommunityHubScreen` — hub **POST / AIDE / LIEU** avec guide vocal. |
| 4 | Profil | `ProfileTab`. |

Les URLs sont synchronisées avec `context.go('/home?tab=N&communityTab=M')` pour le deep linking et les commandes vocales.

---

## 6. Couche données

### `Endpoints` (`data/api/endpoints.dart`)

Centralise les chemins REST (auth, user, medical-records, sos-alerts, emergency-contacts, location, transport, transport-reviews, lieux, lieu-reservations, community, accessibility, education, notifications).  
**Note** : des constantes `surveillance/*` peuvent exister côté client pour une fonctionnalité « proches » ; vérifier l’implémentation réelle sur le backend ciblé.

### Repositories

| Fichier | Responsabilité |
|---------|----------------|
| `auth_repository.dart` | Login email/mot de passe, Google, stockage JWT |
| `user_repository.dart` | Profil, recherche utilisateurs |
| `community_repository.dart` | Posts, commentaires, demandes d’aide, lieux voisins |
| `sos_repository.dart` | Alertes SOS |
| `transport_repository.dart` | Demandes et matching transport |
| `emergency_contacts_repository.dart` | Contacts urgence |
| `medical_records_repository.dart` | Dossier médical |
| `location_repository.dart` | Mise à jour position (proches / carte) |

### Client HTTP

`ApiClient` injecte le **Bearer token** via `TokenStorageService`. Les providers dans `api_providers.dart` exposent le client et les repositories SOS, transport, medical, emergency.

---

## 7. Fonctionnalités métier (scénarios)

### 7.1 Accueil

- Vue différentiée **handicapé** / **accompagnant**.
- Accès rapide vers SOS, santé, communauté selon les cartes / actions définies dans `home_tab.dart` / `home_companion_tab.dart`.

### 7.2 Santé

- Onglet santé avec chaînes localisées.
- **Chat IA santé** (`HealthAiChatScreen`) : conversation contextualisée avec le profil utilisateur ; route dédiée `/health-chat`.

### 7.3 Communauté et « Milieux »

- **Posts** : création avec texte, images, géolocalisation, niveau de danger ; détail avec commentaires.
- **Demandes d’aide** : liste, création, statuts.
- **Lieux** : liste, détail, soumission de lieu, lieux à proximité (`CommunityNearbyPlacesScreen`).
- **Hub** (`M3akCommunityHubScreen`) : regroupe les flux POST / AIDE / LIEU avec **navigation vocale** (`voice_navigation_*`).
- **Pont critique → SOS** : géré côté serveur si danger critique + coordonnées (voir README backend).

### 7.4 Accessibilité moteure (création de contenu)

Écrans dédiés pour utilisateurs ayant des difficultés avec le tactile classique :

- **Vibration codée** (`VibrationCodedPostScreen`)
- **Gestes tête** (`HeadGesturePostScreen`) + capteurs (`back_tap_sensors.dart`)
- **Voix + vibration** (`VoiceVibrationPostScreen`)
- Handoff vers `CreatePostScreen` via `AccessibilityPostHandoff`
- Widgets : `motor_accessible_action.dart`, préférences `accessibility_post_prefs.dart`, `accessibility_motor_prefs.dart`

### 7.5 Assistant global (`M3akGlobalAssistantLayer`)

Calque au-dessus de toute l’app :

- **TTS** (`flutter_tts`) pour la lecture des retours.
- **STT** pour commandes vocales (navigation vers onglets, ouverture création de post, etc.).
- **Maintien long** (≈ 3 s) pour ouvrir l’assistant (réglages dans le fichier du layer).
- Intégration avec `m3akRootNavigatorKey` pour `go_router`.

### 7.6 Module M3AK Port (`m3ak_port/`)

Portage du volet **inclusion** (LSF, Braille, reconnaissance de gestes / visages) :

- **Écrans** : `m3ak_home_screen.dart`, `learning_center_screen`, `sign_language_screen`, `face_recognition_screen`, `converter_screen` (Braille), `daily_challenge_screen`, `practical_scenarios_screen`, `gesture_illustrations.dart`, etc.
- **Services** : appels vers API backend préfixe `/m3ak` (`api_service.dart`) — prédiction Braille, exercices, explication de signes, détection visage (TensorFlow.js côté serveur pour certaines routes ; TFLite côté app pour flux locaux selon écran).
- **Entrée UI** : `features/m3ak/m3ak_inclusion_page.dart` → route `/m3ak-inclusion`.

### 7.7 SOS et accompagnement

- **SOS** : écran alertes, appels repository (création, liste, proximité selon API).
- **Contacts urgence** : `EmergencyContactsScreen` (`/accompagnants`).
- **Transport** : `TransportRequestsScreen` (`/beneficiaires`) + repositories transport.

### 7.8 Dossier médical

- `MedicalRecordScreen` — données alignées sur `GET/PATCH /medical-records/me`.

---

## 8. Thème et accessibilité UI

- Thèmes clair / sombre dans `core/theme/`.
- Taille de texte et contrastes : suivre Material et les réglages système.
- `ReadAloudButton` et composants similaires pour la lecture des contenus.

---

## 9. Assets

Déclarés dans `pubspec.yaml` : `assets/images/`, `animations/`, `videos/`, `models/` (TFLite), polices `NotoSansSymbols2`.

---

## 10. Tests

- `test/` — exemple `widget_test.dart` ; étendre avec tests des repositories mockés si besoin.

---

## 11. Projet jumeau à la racine

Le dépôt peut contenir un autre dossier Flutter `appm3ak/` à la racine (copie ou variante). **La copie décrite ici comme référence active est** `frontend/appm3ak/appm3ak/`. Vérifier quel module votre équipe build avant release.

---

## 12. Références

- Backend : `backend/backend-m3ak 2/README.md`
- Swagger backend : `http://<host>:3000/api`

---

## Licence

Alignée sur le dépôt parent (souvent MIT côté backend ; vérifier le fichier LICENSE à la racine).
