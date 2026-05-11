import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../data/models/emergency_contact_model.dart';
import '../../../providers/api_providers.dart';
import '../../../providers/auth_providers.dart';

class CommunityProchesScreen extends ConsumerStatefulWidget {
  const CommunityProchesScreen({super.key});

  @override
  ConsumerState<CommunityProchesScreen> createState() =>
      _CommunityProchesScreenState();
}

class _CommunityProchesScreenState extends ConsumerState<CommunityProchesScreen> {
  List<EmergencyContactModel> _all = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(emergencyContactsRepositoryProvider);
      final list = await repo.getMyContacts();
      if (!mounted) return;
      setState(() => _all = list);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = AppStrings.fr().errorGeneric;
        _all = const [];
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copié')),
    );
  }

  Future<void> _addByIdDialog(AppStrings strings) async {
    final controller = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    final res = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.communityAddCloseOne),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'ID accompagnant',
            hintText: 'Collez l’ID utilisateur (ex: 69d66a... )',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(strings.addAccompagnant),
          ),
        ],
      ),
    );
    if (!mounted) return;
    final value = res?.trim() ?? '';
    if (value.isEmpty) return;
    try {
      final repo = ref.read(emergencyContactsRepositoryProvider);
      await repo.add(accompagnantId: value);
      await _load();
      messenger.showSnackBar(const SnackBar(content: Text('Ajouté.')));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(strings.errorGeneric)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final strings =
        AppStrings.fromPreferredLanguage(user?.preferredLanguage?.name);
    final theme = Theme.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: Text(strings.retry),
              ),
            ],
          ),
        ),
      );
    }

    final list = _all;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  strings.communityCircleOfTrust,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: strings.addAccompagnant,
                onPressed: () => _addByIdDialog(strings),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 32),
              child: Column(
                children: [
                  const Icon(Icons.group_outlined, size: 64),
                  const SizedBox(height: 10),
                  Text(
                    strings.communityNoCloseOne,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _addByIdDialog(strings),
                    icon: const Icon(Icons.add),
                    label: Text(strings.communityAddCloseOne),
                  ),
                ],
              ),
            )
          else
            ...list.map((c) {
              final u = c.accompagnant;
              final name = u?.displayName ?? 'Contact';
              final contact = u?.contact ?? c.accompagnantId;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.10),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          child: const Icon(Icons.person),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                contact,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Supprimer',
                          onPressed: () async {
                            try {
                              await ref
                                  .read(emergencyContactsRepositoryProvider)
                                  .delete(c.id);
                              await _load();
                            } catch (_) {}
                          },
                          icon: const Icon(Icons.delete_outline),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _copy(contact),
                            icon: const Icon(Icons.message_outlined, size: 18),
                            label: Text(strings.message),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _copy(contact),
                            icon: const Icon(Icons.phone, size: 18),
                            label: Text(strings.call),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 60),
        ],
      ),
    );
  }
}

