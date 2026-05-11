import 'app_config_stub.dart'
    if (dart.library.io) 'app_config_io.dart' as impl;

/// Configuration de l'application Ma3ak.
/// Les valeurs peuvent être surchargées via --dart-define ou environnement.
class AppConfig {
  AppConfig._();

  static const String _envApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  /// URL de base de l'API. Sur l'émulateur Android, "localhost" du PC
  /// est accessible via 10.0.2.2 (utilisé par défaut si API_BASE_URL non défini).
  static String get apiBaseUrl {
    if (_envApiBaseUrl.isNotEmpty) return _envApiBaseUrl;
    return impl.getDefaultApiBaseUrl();
  }

  static String get uploadsBaseUrl => apiBaseUrl;

  /// Mode démo: autoriser l’accès sans login (mode invité).
  /// Active-le via `--dart-define=ALLOW_GUEST=true`.
  static const bool allowGuest = bool.fromEnvironment(
    'ALLOW_GUEST',
    defaultValue: false,
  );

  /// Mode démo : forcer l’écran login à chaque lancement.
  /// Active-le via `--dart-define=FORCE_LOGIN_ON_START=true`.
  static const bool forceLoginOnStart = bool.fromEnvironment(
    'FORCE_LOGIN_ON_START',
    defaultValue: false,
  );

  /// Routes `/ai/community/*` (résumé post, commentaires). Désactivé par défaut : repli local.
  /// Activez quand le backend Nest expose ces endpoints.
  static const bool aiCommunityRemoteEnabled = bool.fromEnvironment(
    'AI_COMMUNITY_REMOTE',
    defaultValue: false,
  );
}
