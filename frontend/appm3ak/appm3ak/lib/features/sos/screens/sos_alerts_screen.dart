import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/location/current_position.dart';
import '../../../data/models/sos_alert_model.dart';
import '../../../providers/api_providers.dart';
import '../../../providers/auth_providers.dart';

/// Alertes SOS : envoi rapide, mes alertes, et alertes à proximité avec « M'y rendre ».
class SosAlertsScreen extends ConsumerStatefulWidget {
  const SosAlertsScreen({super.key});

  @override
  ConsumerState<SosAlertsScreen> createState() => _SosAlertsScreenState();
}

class _SosAlertsScreenState extends ConsumerState<SosAlertsScreen> {
  List<SosAlertModel> _alerts = [];
  List<SosAlertModel> _nearby = [];
  bool _loading = true;
  bool _loadingNearby = false;
  bool _sending = false;
  final Set<String> _respondingIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(sosRepositoryProvider);
      final list = await repo.getMyAlerts();
      if (mounted) setState(() => _alerts = list);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
    if (!kIsWeb) await _loadNearby();
  }

  Future<void> _loadNearby() async {
    setState(() => _loadingNearby = true);
    try {
      final pos = await getCurrentPositionOrNull();
      if (pos == null) {
        if (mounted) setState(() => _nearby = []);
        return;
      }
      final repo = ref.read(sosRepositoryProvider);
      final list = await repo.getNearby(
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
      if (mounted) setState(() => _nearby = list);
    } catch (_) {
      if (mounted) setState(() => _nearby = []);
    } finally {
      if (mounted) setState(() => _loadingNearby = false);
    }
  }

  Future<void> _sendSos() async {
    setState(() => _sending = true);
    try {
      final repo = ref.read(sosRepositoryProvider);
      await repo.create(latitude: 36.8065, longitude: 10.1815);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alerte SOS envoyée')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'envoi')),
        );
      }
    }
    if (mounted) setState(() => _sending = false);
  }

  Future<void> _respond(SosAlertModel a, AppStrings strings) async {
    if (_respondingIds.contains(a.id)) return;
    setState(() => _respondingIds.add(a.id));
    try {
      await ref.read(sosRepositoryProvider).respond(alertId: a.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings.sosMyWayOk),
          backgroundColor: Colors.green,
        ),
      );
      await _loadNearby();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _respondingIds.remove(a.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final strings =
        AppStrings.fromPreferredLanguage(user?.preferredLanguage?.name);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Alertes SOS')),
      body: Stack(
        children: [
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else
            RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 8),
                  Center(
                    child: Material(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(28),
                      elevation: 4,
                      child: InkWell(
                        onTap: _sending ? null : _sendSos,
                        borderRadius: BorderRadius.circular(28),
                        child: const SizedBox(
                          width: 56,
                          height: 56,
                          child: Icon(Icons.star, color: Colors.white, size: 28),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Envoyer une alerte SOS',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (!kIsWeb) ...[
                    const SizedBox(height: 28),
                    Text(
                      strings.helpHubNearbyTitle,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      strings.helpHubNearbySubtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_loadingNearby)
                      const Center(child: CircularProgressIndicator())
                    else if (_nearby.isEmpty)
                      Text(
                        strings.helpHubNearbyEmpty,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      )
                    else
                      ..._nearby.map(
                        (a) => Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.emergency,
                                    color: Colors.red),
                                title: Text(
                                  a.reporterSummary ?? 'SOS',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  '${a.latitude.toStringAsFixed(4)}, ${a.longitude.toStringAsFixed(4)}',
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                                child: FilledButton.icon(
                                  onPressed: _respondingIds.contains(a.id)
                                      ? null
                                      : () => _respond(a, strings),
                                  icon: _respondingIds.contains(a.id)
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.directions_run),
                                  label: Text(strings.sosMyWayButton),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                  const SizedBox(height: 28),
                  Text(
                    'Mes alertes',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_alerts.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Aucune alerte envoyée',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  else
                    ..._alerts.map((a) => Card(
                          child: ListTile(
                            leading: const Icon(Icons.emergency, color: Colors.red),
                            title: Text(
                              '${a.latitude.toStringAsFixed(4)}, ${a.longitude.toStringAsFixed(4)}',
                            ),
                            subtitle: Text(
                              [
                                if (a.statut != null) 'Statut : ${a.statut}',
                                if (a.isEnRoute &&
                                    (a.responderSummary ?? '').isNotEmpty)
                                  'En route : ${a.responderSummary}',
                                if (a.createdAt != null)
                                  a.createdAt!.toIso8601String(),
                              ].where((s) => s.isNotEmpty).join('\n'),
                            ),
                          ),
                        )),
                ],
              ),
            ),
          if (_sending)
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
