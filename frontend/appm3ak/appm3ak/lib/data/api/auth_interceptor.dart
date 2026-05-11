import 'package:dio/dio.dart';

/// Chemins pour lesquels on n'envoie pas le token (connexion / inscription).
const _pathsWithoutAuth = [
  '/auth/login',
  '/auth/google',
  '/auth/register',
  '/user/register',
];

/// Intercepteur qui ajoute le JWT dans le header Authorization.
/// N'ajoute pas de token pour login, register, auth/google.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.getAccessToken});

  final Future<String?> Function() getAccessToken;

  static bool _isPathWithoutAuth(String pathOrUrl) {
    var path = pathOrUrl.split('?').first;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      path = Uri.tryParse(path)?.path ?? path;
    }
    return _pathsWithoutAuth.any((p) => path == p || path.endsWith(p));
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_isPathWithoutAuth(options.path)) {
      handler.next(options);
      return;
    }
    final token = await getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Token expiré ou invalide - l'app redirigera vers Login via auth state
      handler.next(err);
    } else {
      handler.next(err);
    }
  }
}
