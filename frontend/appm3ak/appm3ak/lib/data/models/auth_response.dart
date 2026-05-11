import 'user_model.dart';

class AuthResponse {
  const AuthResponse({
    required this.accessToken,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    try {
      print('🔵 [AuthResponse] Parsing response: $json');
      final token = json['access_token'] ?? json['accessToken'];
      if (token == null) {
        throw Exception('access_token manquant dans la réponse: $json');
      }
      final userData = json['user'];
      if (userData == null) {
        throw Exception('user manquant dans la réponse: $json');
      }
      return AuthResponse(
        accessToken: token as String,
        user: UserModel.fromJson(userData as Map<String, dynamic>),
      );
    } catch (e) {
      print('❌ [AuthResponse] Erreur lors du parsing: $e');
      print('   JSON reçu: $json');
      rethrow;
    }
  }

  final String accessToken;
  final UserModel user;
}
