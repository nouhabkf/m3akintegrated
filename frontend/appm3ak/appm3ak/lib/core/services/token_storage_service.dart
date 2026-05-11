import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../utils/storage_keys.dart';

/// Service central pour le stockage du token JWT.
class TokenStorageService {
  TokenStorageService()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  final FlutterSecureStorage _storage;

  Future<String?> getToken() =>
      _storage.read(key: StorageKeys.accessToken);

  Future<void> saveToken(String token) =>
      _storage.write(key: StorageKeys.accessToken, value: token);

  Future<void> clearToken() =>
      _storage.delete(key: StorageKeys.accessToken);
}
