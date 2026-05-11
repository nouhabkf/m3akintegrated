import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/theme_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _looksLikeEmail(String v) =>
      v.trim().contains('@') &&
      // Accepte les TLD longs (ex: .local, .museum) et sous-domaines.
      RegExp(r'^[\w.+-]+@([\w-]+\.)+[\w-]{2,24}$').hasMatch(v.trim());

  Future<void> _submit() async {
    if (!mounted) return;
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });
    if (!_formKey.currentState!.validate()) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      return;
    }
    final input = _emailController.text.trim();
    final email = _looksLikeEmail(input) ? input : null;
    if (email == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Veuillez entrer une adresse e-mail pour vous connecter.';
      });
      return;
    }
    try {
      await ref.read(authStateProvider.notifier).login(
            email: email.trim().toLowerCase(),
            password: _passwordController.text,
          );
      if (mounted) context.go('/home');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        String errorMsg = AppStrings.fr().errorGeneric;
        if (e is DioException) {
          if (e.response != null) {
            final statusCode = e.response!.statusCode;
            final data = e.response!.data;
            
            // Gestion des codes de statut spécifiques
            if (statusCode == 401) {
              errorMsg = 'Email ou mot de passe incorrect';
            } else if (statusCode == 400) {
              errorMsg = 'Données invalides. Vérifiez votre email et mot de passe.';
            } else if (statusCode == 500) {
              errorMsg = 'Erreur serveur. Veuillez réessayer plus tard.';
            }
            
            // Essayer d'extraire le message d'erreur du backend
            if (data is Map) {
              if (data['message'] != null) {
                errorMsg = data['message'].toString();
              } else if (data['error'] != null) {
                errorMsg = data['error'].toString();
              }
            } else if (data is String) {
              errorMsg = data;
            }
          } else if (e.type == DioExceptionType.connectionError) {
            errorMsg =
                'Connexion impossible à l’API. Vérifiez : 1) le backend tourne (npm run start:dev dans backend-m3ak 2) sur le port 3000 ; '
                '2) sur téléphone, utilisez l’IP du PC (même Wi‑Fi) via --dart-define=API_BASE_URL=http://<IP_PC>:3000 ; '
                '3) sur émulateur Android, 10.0.2.2 fonctionne.';
          } else if (e.type == DioExceptionType.connectionTimeout || 
                     e.type == DioExceptionType.receiveTimeout) {
            errorMsg =
                'Timeout: serveur injoignable. Si vous êtes sur téléphone, '
                '10.0.2.2 ne marche pas → mettez API_BASE_URL=http://<IP_PC>:3000.';
          }
        }
        _errorMessage = errorMsg;
      });
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });
    // TODO: intégrer google_sign_in
    setState(() {
      _isLoading = false;
      _errorMessage = 'Google Sign-In à configurer (voir README)';
    });
  }

  @override
  Widget build(BuildContext context) {
    // Si le splash a renvoyé ici pendant que /user/me chargeait encore, on envoie vers /home dès que l’utilisateur est connu.
    ref.listen(authStateProvider, (_, next) {
      if (next.hasValue && next.requireValue != null && context.mounted) {
        context.go('/home');
      }
    });

    final strings = AppStrings.fr();
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    ref.watch(themeModeProvider);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    // Logo
                    Semantics(
                      label: strings.appTitle,
                      child: AppLogo(
                        size: 80,
                        borderRadius: 16,
                        backgroundColor: primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      strings.appTitle,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      strings.tagline,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 40),
                    // E-mail / Téléphone
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        strings.emailOrPhone,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      decoration: InputDecoration(
                        hintText: strings.hintEmailOrPhone,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.mic_none, color: primary),
                          onPressed: () {},
                          tooltip: 'Saisie vocale',
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Champ obligatoire';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    // Mot de passe
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        strings.password,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: strings.hintPassword,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: primary,
                          ),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Champ obligatoire' : null,
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    // Bouton Connexion
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Flexible(
                              child: Text(
                                strings.connexion,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Mot de passe oublié
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        strings.forgotPassword,
                        style: TextStyle(
                          color: primary,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // OU
                    Row(
                      children: [
                        Expanded(child: Divider(color: theme.colorScheme.outline)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            strings.or,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: theme.colorScheme.outline)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Google
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _loginWithGoogle,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: theme.colorScheme.outline),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          foregroundColor: theme.colorScheme.onSurface,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.g_mobiledata, size: 28, color: primary),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                strings.signInWithGoogle,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Pas encore de compte
                    Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        Text(
                          strings.noAccount,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/register'),
                          child: Text(
                            strings.signUp,
                            style: TextStyle(
                              color: primary,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
            // FAB Accessibilité
            Positioned(
              right: 16,
              bottom: 24,
              child: Semantics(
                button: true,
                label: 'Options d\'accessibilité',
                    child: FloatingActionButton(
                      onPressed: () {},
                      backgroundColor: theme.colorScheme.surface,
                      foregroundColor: primary,
                  heroTag: 'accessibility',
                  child: const Icon(Icons.accessibility_new, size: 28),
                ),
              ),
            ),
            // Bouton mode clair / sombre (au-dessus du contenu pour rester cliquable)
            Positioned(
              top: 0,
              right: 0,
              child: Material(
                color: Colors.transparent,
                child: IconButton(
                  icon: Icon(
                    isDark ? Icons.light_mode : Icons.dark_mode,
                    color: theme.colorScheme.onSurface,
                  ),
                  onPressed: () {
                    final notifier = ref.read(themeModeProvider.notifier);
                    notifier.setThemeMode(
                      isDark ? ThemeMode.light : ThemeMode.dark,
                    );
                  },
                  tooltip: isDark ? 'Mode clair' : 'Mode sombre',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

