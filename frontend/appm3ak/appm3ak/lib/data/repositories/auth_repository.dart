import 'package:dio/dio.dart';

import '../api/api_client.dart';
import '../api/endpoints.dart';
import '../models/auth_response.dart';
import '../../core/services/token_storage_service.dart';

class AuthRepository {
  AuthRepository({
    required ApiClient apiClient,
    required TokenStorageService tokenStorage,
  })  : _api = apiClient,
        _storage = tokenStorage;

  final ApiClient _api;
  final TokenStorageService _storage;

  Future<String?> getStoredToken() => _storage.getToken();

  Future<void> _saveToken(String token) => _storage.saveToken(token);

  Future<void> _clearToken() => _storage.clearToken();

  /// Vérifie si un token est stocké (utilisateur potentiellement connecté).
  Future<bool> hasStoredToken() async {
    final token = await getStoredToken();
    return token != null && token.isNotEmpty;
  }

  /// Login email/password.
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      print('🔵 [AuthRepository] Tentative de connexion:');
      print('   Email: $email');
      print('   URL: ${_api.dio.options.baseUrl}${Endpoints.authLogin}');
      
      final response = await _api.dio.post(
        Endpoints.authLogin,
        data: {
          'email': email.trim().toLowerCase(),
          'password': password,
        },
      );
      
      print('✅ [AuthRepository] Connexion réussie');
      print('   Response: ${response.data}');
      
      final auth = AuthResponse.fromJson(response.data as Map<String, dynamic>);
      await _saveToken(auth.accessToken);
      return auth;
    } catch (e) {
      print('❌ [AuthRepository] Erreur lors de la connexion:');
      print('   Type: ${e.runtimeType}');
      print('   Message: $e');
      if (e is DioException) {
        print('   Status Code: ${e.response?.statusCode}');
        print('   Response Data: ${e.response?.data}');
        print('   Request URL: ${e.requestOptions.uri}');
      }
      rethrow;
    }
  }

  /// Login Google via id_token.
  Future<AuthResponse> loginWithGoogle({required String idToken}) async {
    final response = await _api.dio.post(
      Endpoints.authGoogle,
      data: {'id_token': idToken},
    );
    final auth = AuthResponse.fromJson(response.data as Map<String, dynamic>);
    await _saveToken(auth.accessToken);
    return auth;
  }

  /// Déconnexion : supprime le token local.
  Future<void> logout() => _clearToken();

  /// Vérifie la configuration backend (JWT, Google).
  Future<Map<String, bool>> checkConfig() async {
    try {
      final response = await _api.dio.get(Endpoints.authConfigTest);
      final data = response.data as Map<String, dynamic>;
      return {
        'jwtSecretConfigured': data['jwtSecretConfigured'] as bool? ?? false,
        'googleClientIdConfigured':
            data['googleClientIdConfigured'] as bool? ?? false,
      };
    } catch (_) {
      return {'jwtSecretConfigured': false, 'googleClientIdConfigured': false};
    }
  }
}
