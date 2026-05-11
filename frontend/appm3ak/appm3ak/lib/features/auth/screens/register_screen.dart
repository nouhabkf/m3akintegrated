import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../data/models/user_model.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/theme_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  int _step = 0;
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailOrPhoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _typeHandicapController = TextEditingController();
  final _besoinSpecifiqueController = TextEditingController();
  final _typeAccompagnantController = TextEditingController();
  final _specialisationController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _animalAssistance = false;
  String? _errorMessage;
  UserRole _role = UserRole.handicape;
  PreferredLanguage? _preferredLanguage = PreferredLanguage.fr;

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailOrPhoneController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _typeHandicapController.dispose();
    _besoinSpecifiqueController.dispose();
    _typeAccompagnantController.dispose();
    _specialisationController.dispose();
    super.dispose();
  }

  bool _looksLikeEmail(String v) =>
      v.trim().contains('@') &&
      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim());

  String? get _emailValue {
    final v = _emailOrPhoneController.text.trim();
    if (_looksLikeEmail(v)) return v;
    return _emailController.text.trim().isEmpty ? null : _emailController.text.trim();
  }

  String get _telephoneValue => _telephoneController.text.trim();

  Future<void> _submit() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });
    if (!_formKey.currentState!.validate()) {
      setState(() => _isLoading = false);
      return;
    }
    final emailRaw = _emailValue;
    if (emailRaw == null || emailRaw.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'L\'adresse e-mail est obligatoire.';
      });
      return;
    }
    final email = emailRaw.trim().toLowerCase();
    if (_telephoneValue.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Le téléphone est obligatoire.';
      });
      return;
    }
    try {
      print('🔵 [RegisterScreen] Début de l\'inscription');
      print('   Nom: ${_nomController.text.trim()}');
      print('   Prénom: ${_prenomController.text.trim()}');
      print('   Email: $email');
      print('   Téléphone: $_telephoneValue');
      print('   Rôle: ${_role.toApiString()}');
      
      final userRepo = ref.read(userRepositoryProvider);
      await userRepo.register(
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
        email: email,
        password: _passwordController.text,
        telephone: _telephoneValue,
        role: _role.toApiString(),
        typeHandicap: _typeHandicapController.text.trim().isEmpty
            ? null
            : _typeHandicapController.text.trim(),
        besoinSpecifique: _besoinSpecifiqueController.text.trim().isEmpty
            ? null
            : _besoinSpecifiqueController.text.trim(),
        animalAssistance: _animalAssistance,
        typeAccompagnant: _typeAccompagnantController.text.trim().isEmpty
            ? null
            : _typeAccompagnantController.text.trim(),
        specialisation: _specialisationController.text.trim().isEmpty
            ? null
            : _specialisationController.text.trim(),
        langue: _preferredLanguage?.name ?? 'fr',
      );
      if (!mounted) return;
      // Connexion immédiate avec le même mot de passe (évite échecs de login
      // dus à casse d’e-mail / oubli de se reconnecter manuellement).
      await ref.read(authStateProvider.notifier).login(
            email: email,
            password: _passwordController.text,
          );
      if (!mounted) return;
      setState(() => _isLoading = false);
      context.go('/home');
    } catch (e) {
      setState(() {
        _isLoading = false;
        // Afficher le message d'erreur détaillé
        print('❌ [RegisterScreen] Erreur capturée: $e');
        if (e is DioException) {
          if (e.response != null) {
            // Erreur du serveur avec réponse
            final data = e.response!.data;
            print('   Response Status: ${e.response!.statusCode}');
            print('   Response Data: $data');
            
            if (data is Map) {
              // Essayer différents formats de message d'erreur
              if (data['message'] != null) {
                _errorMessage = data['message'].toString();
              } else if (data['error'] != null) {
                _errorMessage = data['error'].toString();
              } else if (data['msg'] != null) {
                _errorMessage = data['msg'].toString();
              } else if (data['errors'] != null) {
                // Si c'est un objet d'erreurs de validation
                final errors = data['errors'];
                if (errors is Map) {
                  final errorList = errors.values.expand((e) => e is List ? e : [e]).toList();
                  _errorMessage = errorList.join(', ');
                } else {
                  _errorMessage = errors.toString();
                }
              } else {
                _errorMessage = 'Erreur ${e.response!.statusCode}: ${data.toString()}';
              }
            } else if (data is String) {
              _errorMessage = data;
            } else {
              _errorMessage = 'Erreur: ${e.response!.statusCode} - ${e.response!.statusMessage ?? "Erreur inconnue"}';
            }
          } else if (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout) {
            _errorMessage = 'Timeout: Le serveur ne répond pas. Vérifiez que le backend est démarré.';
          } else if (e.type == DioExceptionType.connectionError) {
            _errorMessage = 'Impossible de se connecter au serveur. Vérifiez que le backend est démarré sur http://localhost:3000';
          } else {
            _errorMessage = 'Erreur de connexion: ${e.message}';
          }
        } else {
          _errorMessage = 'Erreur: ${e.toString()}';
        }
      });
    }
  }

  void _nextStep() {
    if (_step < 3) {
      if (_formKey.currentState?.validate() ?? false) {
        setState(() => _step++);
      }
    } else {
      _submit();
    }
  }


  /// Couleurs du nouveau design (thème sombre Ma3ak)
  static const Color _scaffoldBg = Color(0xFF1A2024);
  static const Color _accent = Color(0xFF00A3DA);
  static const Color _fieldBg = Color(0xFF2C4F57);
  static const Color _onSurface = Color(0xFFFFFFFF);
  static const Color _onSurfaceVariant = Color(0xFFB0B0B0);

  InputDecoration _darkInput({
    required String hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: _onSurfaceVariant, fontSize: 16),
      filled: true,
      fillColor: _fieldBg,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCF6679)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      suffixIcon: suffixIcon,
    );
  }

  bool _isDarkMode(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    if (themeMode == ThemeMode.dark) return true;
    if (themeMode == ThemeMode.light) return false;
    return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
  }

  Widget _roleSelector(AppStrings strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.iAm,
          style: const TextStyle(
            color: _onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Material(
                color: _role == UserRole.handicape ? _accent : _fieldBg,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => setState(() => _role = UserRole.handicape),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Center(
                      child: Text(
                        'Handicapé',
                        style: const TextStyle(
                          color: _onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Material(
                color: _role == UserRole.accompagnant ? _accent : _fieldBg,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => setState(() => _role = UserRole.accompagnant),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Center(
                      child: Text(
                        strings.companion,
                        style: const TextStyle(
                          color: _onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.fr();
    ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: _scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _onSurface),
          onPressed: () {
            if (_step > 0) {
              setState(() => _step--);
            } else {
              context.pop();
            }
          },
        ),
        title: Text(
          strings.appTitle,
          style: const TextStyle(
            color: _onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isDarkMode(context) ? Icons.light_mode : Icons.dark_mode,
              color: _onSurface,
            ),
            onPressed: () {
              final notifier = ref.read(themeModeProvider.notifier);
              notifier.setThemeMode(
                _isDarkMode(context) ? ThemeMode.light : ThemeMode.dark,
              );
            },
            tooltip: _isDarkMode(context) ? 'Mode clair' : 'Mode sombre',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final active = i <= _step;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active ? _accent : _fieldBg,
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      if (_step == 0) ...[
                        Text(
                          strings.registerPageTitle,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          strings.registerSubtitle,
                          style: const TextStyle(
                            fontSize: 14,
                            color: _onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _roleSelector(strings),
                        const SizedBox(height: 20),
                        Text(
                          'Nom de famille *',
                          style: const TextStyle(
                            color: _onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nomController,
                          style: const TextStyle(color: _onSurface),
                          decoration: _darkInput(
                            hintText: 'Ex: Ben Ali',
                            suffixIcon: const Padding(
                              padding: EdgeInsets.only(right: 12),
                              child: Icon(Icons.person_outline, color: _onSurfaceVariant, size: 22),
                            ),
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Obligatoire' : null,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Prénom *',
                          style: TextStyle(
                            color: _onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _prenomController,
                          style: const TextStyle(color: _onSurface),
                          decoration: _darkInput(
                            hintText: 'Ex: Ahmed',
                            suffixIcon: const Padding(
                              padding: EdgeInsets.only(right: 12),
                              child: Icon(Icons.person_outline, color: _onSurfaceVariant, size: 22),
                            ),
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Obligatoire' : null,
                        ),
                        if (_role == UserRole.handicape) ...[
                          const SizedBox(height: 20),
                          const Text(
                            'Type de handicap (optionnel)',
                            style: TextStyle(
                              color: _onSurface,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _typeHandicapController,
                            style: const TextStyle(color: _onSurface),
                            decoration: _darkInput(hintText: 'Ex: Fauteuil roulant'),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Besoins spécifiques (optionnel)',
                            style: TextStyle(
                              color: _onSurface,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _besoinSpecifiqueController,
                            style: const TextStyle(color: _onSurface),
                            decoration: _darkInput(hintText: 'Décrivez vos besoins'),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 8),
                          CheckboxListTile(
                            value: _animalAssistance,
                            onChanged: (v) => setState(() => _animalAssistance = v ?? false),
                            title: const Text('Animal d\'assistance', style: TextStyle(color: _onSurface)),
                            activeColor: _accent,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                        const SizedBox(height: 20),
                        Text(
                          strings.emailOrPhoneRequired,
                          style: const TextStyle(
                            color: _onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailOrPhoneController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: _onSurface),
                          decoration: _darkInput(
                            hintText: 'votre@email.tn',
                            suffixIcon: const Padding(
                              padding: EdgeInsets.only(right: 12),
                              child: Icon(Icons.mail_outline, color: _onSurfaceVariant, size: 22),
                            ),
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Obligatoire' : null,
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: _fieldBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.info_outline, color: _accent, size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  strings.dataSecurityMessage,
                                  style: const TextStyle(
                                    color: _onSurface,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (_step == 1) ...[
                        Text(
                          'Mot de passe et rôle',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: _onSurface,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _roleSelector(strings),
                        const SizedBox(height: 20),
                        if (!_looksLikeEmail(_emailOrPhoneController.text.trim())) ...[
                          const Text(
                            'Adresse e-mail *',
                            style: TextStyle(
                              color: _onSurface,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: _onSurface),
                            decoration: _darkInput(
                              hintText: 'email@exemple.com',
                              suffixIcon: const Padding(
                                padding: EdgeInsets.only(right: 12),
                                child: Icon(Icons.mail_outline, color: _onSurfaceVariant, size: 22),
                              ),
                            ),
                            validator: (v) {
                              if (_looksLikeEmail(
                                  _emailOrPhoneController.text.trim())) {
                                return null;
                              }
                              if (v == null || v.trim().isEmpty) {
                                return 'Obligatoire';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                  .hasMatch(v)) {
                                return 'Email invalide';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                        ],
                        const Text(
                          'Numéro de téléphone *',
                          style: TextStyle(
                            color: _onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _telephoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: _onSurface),
                          decoration: _darkInput(
                            hintText: '99 000 000',
                            suffixIcon: const Padding(
                              padding: EdgeInsets.only(right: 12),
                              child: Icon(Icons.phone_outlined, color: _onSurfaceVariant, size: 22),
                            ),
                          ).copyWith(
                            prefixText: '+216 ',
                            prefixStyle: const TextStyle(color: _onSurfaceVariant, fontSize: 16),
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Obligatoire' : null,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Mot de passe *',
                          style: TextStyle(
                            color: _onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(color: _onSurface),
                          decoration: _darkInput(
                            hintText: strings.hintPassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: _accent,
                                size: 22,
                              ),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (v) => (v == null || v.length < 6)
                              ? 'Min. 6 caractères'
                              : null,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Confirmer le mot de passe *',
                          style: TextStyle(
                            color: _onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirm,
                          style: const TextStyle(color: _onSurface),
                          decoration: _darkInput(
                            hintText: 'Confirmez votre mot de passe',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: _accent,
                                size: 22,
                              ),
                              onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm),
                            ),
                          ),
                          validator: (v) {
                            if (v != _passwordController.text) {
                              return 'Les mots de passe ne correspondent pas';
                            }
                            return null;
                          },
                        ),
                      ],
                      if (_step == 2) ...[
                        const Text(
                          'Langue',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: _onSurface,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          '${strings.preferredLanguage} (optionnel)',
                          style: const TextStyle(
                            color: _onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Radio<PreferredLanguage?>(
                              value: PreferredLanguage.fr,
                              groupValue: _preferredLanguage,
                              activeColor: _accent,
                              onChanged: (v) =>
                                  setState(() => _preferredLanguage = v),
                            ),
                            const Text('Français', style: TextStyle(color: _onSurface)),
                            Radio<PreferredLanguage?>(
                              value: PreferredLanguage.ar,
                              groupValue: _preferredLanguage,
                              activeColor: _accent,
                              onChanged: (v) =>
                                  setState(() => _preferredLanguage = v),
                            ),
                            const Text('العربية', style: TextStyle(color: _onSurface)),
                          ],
                        ),
                      ],
                      if (_step == 3) ...[
                        Text(
                          _role == UserRole.accompagnant
                              ? 'Accompagnant : type et spécialisation'
                              : 'Finalisation',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: _onSurface,
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (_role == UserRole.accompagnant) ...[
                          const Text(
                            'Type accompagnant (optionnel)',
                            style: TextStyle(
                              color: _onSurface,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _typeAccompagnantController,
                            style: const TextStyle(color: _onSurface),
                            decoration: _darkInput(hintText: 'Ex: Bénévole'),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Spécialisation (optionnel)',
                            style: TextStyle(
                              color: _onSurface,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _specialisationController,
                            style: const TextStyle(color: _onSurface),
                            decoration: _darkInput(hintText: 'Ex: Médical'),
                          ),
                        ] else
                          const Text(
                            'Vérifiez vos informations puis cliquez sur S\'inscrire.',
                            style: TextStyle(color: _onSurfaceVariant, fontSize: 14),
                          ),
                      ],
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFCF6679).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFCF6679),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Color(0xFFCF6679),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: Color(0xFFCF6679),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _nextStep,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: _onSurface,
                            disabledBackgroundColor: _fieldBg,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: _onSurface,
                                  ),
                                )
                              : Text(
                                  _step < 3
                                      ? strings.continueBtn
                                      : strings.signUp,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            strings.registerAlready,
                            style: const TextStyle(
                              color: _onSurface,
                              fontSize: 14,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go('/login'),
                            style: TextButton.styleFrom(
                              foregroundColor: _accent,
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              strings.loginButton,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
