import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/widgets/accessible_button.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../providers/auth_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomController;
  late TextEditingController _prenomController;
  late TextEditingController _telephoneController;
  late TextEditingController _typeHandicapController;
  late TextEditingController _besoinSpecifiqueController;
  late TextEditingController _typeAccompagnantController;
  late TextEditingController _specialisationController;
  PreferredLanguage? _preferredLanguage;
  bool _animalAssistance = false;
  bool _disponible = false;
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider).valueOrNull;
    _nomController = TextEditingController(text: user?.nom ?? '');
    _prenomController = TextEditingController(text: user?.prenom ?? '');
    _telephoneController = TextEditingController(text: user?.telephone ?? '');
    _typeHandicapController = TextEditingController(text: user?.typeHandicap ?? '');
    _besoinSpecifiqueController = TextEditingController(text: user?.besoinSpecifique ?? '');
    _typeAccompagnantController = TextEditingController(text: user?.typeAccompagnant ?? '');
    _specialisationController = TextEditingController(text: user?.specialisation ?? '');
    _preferredLanguage = user?.preferredLanguage;
    _animalAssistance = user?.animalAssistance ?? false;
    _disponible = user?.disponible ?? false;
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _telephoneController.dispose();
    _typeHandicapController.dispose();
    _besoinSpecifiqueController.dispose();
    _typeAccompagnantController.dispose();
    _specialisationController.dispose();
    super.dispose();
  }

  Future<void> _changePhoto() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (x == null) return;
    setState(() => _isLoading = true);
    try {
      final userRepo = ref.read(userRepositoryProvider);
      final user = await userRepo.updateProfilePhoto(x);
      ref.read(authStateProvider.notifier).setUser(user);
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final userRepo = ref.read(userRepositoryProvider);
      final user = await userRepo.updateMe(
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
        telephone: _telephoneController.text.trim().isEmpty
            ? null
            : _telephoneController.text.trim(),
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
        disponible: _disponible,
        langue: _preferredLanguage?.name ?? 'fr',
      );
      ref.read(authStateProvider.notifier).setUser(user);
      if (mounted) context.pop();
    } catch (_) {}
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final strings = AppStrings.fromPreferredLanguage(user.preferredLanguage?.name);
    final imageUrl = UserRepository.photoUrl(user.photoProfil);

    return Scaffold(
      appBar: AppBar(title: Text(strings.profile)),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _changePhoto,
                        child: Semantics(
                          button: true,
                          label: strings.changePhoto,
                          child: CircleAvatar(
                            radius: 56,
                            backgroundImage: imageUrl.isNotEmpty
                                ? NetworkImage(imageUrl)
                                : null,
                            child: imageUrl.isEmpty
                                ? const Icon(Icons.person, size: 64)
                                : null,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nomController,
                      decoration: const InputDecoration(
                        labelText: 'Nom de famille',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Obligatoire' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _prenomController,
                      decoration: const InputDecoration(
                        labelText: 'Prénom',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Obligatoire' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _telephoneController,
                      decoration: InputDecoration(
                        labelText: strings.phoneNumber,
                        prefixIcon: const Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(strings.preferredLanguage),
                    Row(
                      children: [
                        Radio<PreferredLanguage?>(
                          value: PreferredLanguage.fr,
                          groupValue: _preferredLanguage,
                          onChanged: (v) =>
                              setState(() => _preferredLanguage = v),
                        ),
                        const Text('Français'),
                        Radio<PreferredLanguage?>(
                          value: PreferredLanguage.ar,
                          groupValue: _preferredLanguage,
                          onChanged: (v) =>
                              setState(() => _preferredLanguage = v),
                        ),
                        const Text('العربية'),
                      ],
                    ),
                    if (user.isBeneficiary) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _typeHandicapController,
                        decoration: const InputDecoration(
                          labelText: 'Type de handicap',
                          prefixIcon: Icon(Icons.accessible),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _besoinSpecifiqueController,
                        decoration: const InputDecoration(
                          labelText: 'Besoins spécifiques',
                          prefixIcon: Icon(Icons.health_and_safety_outlined),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        value: _animalAssistance,
                        onChanged: (v) =>
                            setState(() => _animalAssistance = v ?? false),
                        title: const Text('Animal d\'assistance'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                    if (user.isCompanion) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _typeAccompagnantController,
                        decoration: const InputDecoration(
                          labelText: 'Type accompagnant',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _specialisationController,
                        decoration: const InputDecoration(
                          labelText: 'Spécialisation',
                          prefixIcon: Icon(Icons.school_outlined),
                        ),
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        value: _disponible,
                        onChanged: (v) =>
                            setState(() => _disponible = v ?? false),
                        title: const Text('Disponible'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                    const SizedBox(height: 32),
                    AccessibleButton(
                      label: strings.save,
                      onPressed: _isSaving ? null : _save,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading || _isSaving)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.black26,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}
