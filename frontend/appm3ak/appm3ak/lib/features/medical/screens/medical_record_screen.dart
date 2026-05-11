import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../data/models/medical_record_model.dart';
import '../../health/models/health_chat_launch.dart';
import '../../../providers/api_providers.dart';
import '../../../providers/auth_providers.dart';

/// Écran Dossier médical (HANDICAPE uniquement).
class MedicalRecordScreen extends ConsumerStatefulWidget {
  const MedicalRecordScreen({super.key});

  @override
  ConsumerState<MedicalRecordScreen> createState() => _MedicalRecordScreenState();
}

class _MedicalRecordScreenState extends ConsumerState<MedicalRecordScreen> {
  MedicalRecordModel? _record;
  bool _loading = true;
  bool _saving = false;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _groupeSanguinController;
  late TextEditingController _allergiesController;
  late TextEditingController _maladiesController;
  late TextEditingController _medicamentsController;
  late TextEditingController _medecinController;
  late TextEditingController _contactUrgenceController;

  @override
  void initState() {
    super.initState();
    _groupeSanguinController = TextEditingController();
    _allergiesController = TextEditingController();
    _maladiesController = TextEditingController();
    _medicamentsController = TextEditingController();
    _medecinController = TextEditingController();
    _contactUrgenceController = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _groupeSanguinController.dispose();
    _allergiesController.dispose();
    _maladiesController.dispose();
    _medicamentsController.dispose();
    _medecinController.dispose();
    _contactUrgenceController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(medicalRecordsRepositoryProvider);
      final r = await repo.getMe();
      if (mounted) {
        _record = r;
        if (r != null) {
          _groupeSanguinController.text = r.groupeSanguin ?? '';
          _allergiesController.text = r.allergies ?? '';
          _maladiesController.text = r.maladiesChroniques ?? '';
          _medicamentsController.text = r.medicaments ?? '';
          _medecinController.text = r.medecinTraitant ?? '';
          _contactUrgenceController.text = r.contactUrgence ?? '';
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(medicalRecordsRepositoryProvider);
      if (_record == null) {
        await repo.create(
          groupeSanguin: _groupeSanguinController.text.trim().isEmpty ? null : _groupeSanguinController.text.trim(),
          allergies: _allergiesController.text.trim().isEmpty ? null : _allergiesController.text.trim(),
          maladiesChroniques: _maladiesController.text.trim().isEmpty ? null : _maladiesController.text.trim(),
          medicaments: _medicamentsController.text.trim().isEmpty ? null : _medicamentsController.text.trim(),
          medecinTraitant: _medecinController.text.trim().isEmpty ? null : _medecinController.text.trim(),
          contactUrgence: _contactUrgenceController.text.trim().isEmpty ? null : _contactUrgenceController.text.trim(),
        );
      } else {
        await repo.updateMe(
          groupeSanguin: _groupeSanguinController.text.trim().isEmpty ? null : _groupeSanguinController.text.trim(),
          allergies: _allergiesController.text.trim().isEmpty ? null : _allergiesController.text.trim(),
          maladiesChroniques: _maladiesController.text.trim().isEmpty ? null : _maladiesController.text.trim(),
          medicaments: _medicamentsController.text.trim().isEmpty ? null : _medicamentsController.text.trim(),
          medecinTraitant: _medecinController.text.trim().isEmpty ? null : _medecinController.text.trim(),
          contactUrgence: _contactUrgenceController.text.trim().isEmpty ? null : _contactUrgenceController.text.trim(),
        );
      }
      await _load();
    } catch (_) {}
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null || !user.isBeneficiary) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dossier médical')),
        body: const Center(child: Text('Réservé aux utilisateurs Handicapé.')),
      );
    }
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final strings =
        AppStrings.fromPreferredLanguage(user.preferredLanguage?.name);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dossier médical'),
        actions: [
          IconButton(
            icon: const Icon(Icons.smart_toy),
            tooltip: strings.healthOpenChat,
            onPressed: () => context.push(
                  '/health-chat',
                  extra: HealthChatLaunch(user: user),
                ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _groupeSanguinController,
                    decoration: const InputDecoration(
                      labelText: 'Groupe sanguin',
                      prefixIcon: Icon(Icons.bloodtype),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _allergiesController,
                    decoration: const InputDecoration(
                      labelText: 'Allergies',
                      prefixIcon: Icon(Icons.warning_amber_outlined),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _maladiesController,
                    decoration: const InputDecoration(
                      labelText: 'Maladies chroniques',
                      prefixIcon: Icon(Icons.health_and_safety_outlined),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _medicamentsController,
                    decoration: const InputDecoration(
                      labelText: 'Médicaments',
                      prefixIcon: Icon(Icons.medication_outlined),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _medecinController,
                    decoration: const InputDecoration(
                      labelText: 'Médecin traitant',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _contactUrgenceController,
                    decoration: const InputDecoration(
                      labelText: 'Contact urgence',
                      prefixIcon: Icon(Icons.emergency),
                    ),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/activity-posture-detection'),
                    icon: const Icon(Icons.videocam_outlined),
                    label: const Text('Détection activité & posture (caméra)'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Enregistrer'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
