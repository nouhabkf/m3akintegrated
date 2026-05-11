import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../data/models/emergency_contact_model.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../providers/api_providers.dart';
import '../../../providers/auth_providers.dart';

/// Écran Contacts d'urgence (remplace Mes accompagnants).
class EmergencyContactsScreen extends ConsumerStatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  ConsumerState<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends ConsumerState<EmergencyContactsScreen> {
  List<EmergencyContactModel> _contacts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final repo = ref.read(emergencyContactsRepositoryProvider);
      final list = await repo.getMyContacts();
      if (mounted) setState(() => _contacts = list);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = AppStrings.fr().errorGeneric;
          _contacts = [];
        });
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _remove(String id) async {
    try {
      final repo = ref.read(emergencyContactsRepositoryProvider);
      await repo.delete(id);
      await _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final strings = AppStrings.fromPreferredLanguage(user?.preferredLanguage?.name);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts d\'urgence'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _load,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _load,
                        child: Text(strings.save),
                      ),
                    ],
                  ),
                )
              : _contacts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.emergency, size: 64),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun contact d\'urgence',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ajoutez des accompagnants à contacter en priorité.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          OutlinedButton.icon(
                            onPressed: () => _showAddDialog(context),
                            icon: const Icon(Icons.add),
                            label: const Text('Ajouter un contact'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _contacts.length,
                        itemBuilder: (_, i) {
                          final c = _contacts[i];
                          final u = c.accompagnant;
                          final photo = UserRepository.photoUrl(u?.photoProfil);
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage: photo.isNotEmpty
                                    ? NetworkImage(photo)
                                    : null,
                                child: photo.isEmpty
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              title: Text(u?.displayName ?? 'Contact #${c.ordrePriorite}'),
                              subtitle: Text(u?.contact ?? c.accompagnantId),
                              trailing: IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () => _remove(c.id),
                                tooltip: 'Retirer',
                              ),
                              minVerticalPadding: 12,
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: _contacts.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _showAddDialog(context),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _showAddDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ajouter un contact d\'urgence'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'ID accompagnant',
            hintText: 'Saisir l\'ID de l\'accompagnant',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              final id = controller.text.trim();
              if (id.isEmpty) return;
              Navigator.of(ctx).pop();
              try {
                final repo = ref.read(emergencyContactsRepositoryProvider);
                await repo.add(accompagnantId: id);
                await _load();
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Impossible d\'ajouter le contact')),
                  );
                }
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }
}
