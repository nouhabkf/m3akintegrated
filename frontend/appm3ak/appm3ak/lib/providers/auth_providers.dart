import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/user_repository.dart';
import 'api_providers.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return AuthRepository(apiClient: apiClient, tokenStorage: tokenStorage);
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return UserRepository(apiClient: apiClient);
});

/// Fournit l'état d'authentification : connecté avec User ou non.
final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AsyncValue<UserModel?>>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  final userRepo = ref.watch(userRepositoryProvider);
  return AuthStateNotifier(authRepo, userRepo);
});

class AuthStateNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  AuthStateNotifier(this._authRepo, this._userRepo)
      : super(const AsyncValue.loading()) {
    _checkAuth();
  }

  final AuthRepository _authRepo;
  final UserRepository _userRepo;

  Future<void> _checkAuth() async {
    // Mode démo : ne jamais auto‑connecter.
    if (AppConfig.forceLoginOnStart) {
      await _authRepo.logout();
      state = const AsyncValue.data(null);
      return;
    }
    final hasToken = await _authRepo.hasStoredToken();
    if (!hasToken) {
      state = const AsyncValue.data(null);
      return;
    }
    try {
      final user = await _userRepo.getMe();
      state = AsyncValue.data(user);
    } catch (_) {
      await _authRepo.logout();
      state = const AsyncValue.data(null);
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      final auth = await _authRepo.login(email: email, password: password);
      state = AsyncValue.data(auth.user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> loginWithGoogle(String idToken) async {
    state = const AsyncValue.loading();
    try {
      final auth = await _authRepo.loginWithGoogle(idToken: idToken);
      state = AsyncValue.data(auth.user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> logout() async {
    await _authRepo.logout();
    state = const AsyncValue.data(null);
  }

  void setUser(UserModel? user) {
    state = AsyncValue.data(user);
  }

  /// Rafraîchit l'utilisateur courant (après PATCH profil, etc.).
  Future<void> refreshUser() async {
    try {
      final user = await _userRepo.getMe();
      state = AsyncValue.data(user);
    } catch (_) {
      await _authRepo.logout();
      state = const AsyncValue.data(null);
    }
  }
}
