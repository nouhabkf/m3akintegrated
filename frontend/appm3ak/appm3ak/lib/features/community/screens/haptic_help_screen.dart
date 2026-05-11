import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:vibration/vibration.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/location/current_position.dart';
import '../../../data/models/sos_alert_model.dart';
import '../../../providers/api_providers.dart';
import '../../../providers/auth_providers.dart';

/// Hub M3AK Secours : SOS tactile, attente réelle d’un « M’y rendre » (API), alertes `findNearby`.
enum _HubPanel { send, network }

enum _SosPhase { idle, sending, sent, confirmed }

class HapticHelpScreen extends ConsumerStatefulWidget {
  const HapticHelpScreen({super.key});

  @override
  ConsumerState<HapticHelpScreen> createState() => _HapticHelpScreenState();
}

class _HapticHelpScreenState extends ConsumerState<HapticHelpScreen> {
  final FlutterTts _tts = FlutterTts();

  _HubPanel _panel = _HubPanel.send;
  _SosPhase _sosPhase = _SosPhase.idle;

  int _tapCount = 0;
  DateTime? _lastTapAt;
  Timer? _pollTimer;
  String? _pendingAlertId;
  DateTime? _pollStartedAt;
  String _responderDisplayName = '';
  final Set<String> _respondingIds = {};

  List<SosAlertModel> _nearbyAlerts = [];
  bool _nearbyLoading = false;
  String? _nearbyError;

  static const Duration _tapResetAfter = Duration(seconds: 2);
  static const Duration _pollInterval = Duration(seconds: 2);
  static const Duration _pollMaxWait = Duration(minutes: 10);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _entrySignature());
  }

  @override
  void dispose() {
    _stopPolling();
    _tts.stop();
    super.dispose();
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _pendingAlertId = null;
    _pollStartedAt = null;
  }

  void _startPollingForResponder(AppStrings strings) {
    _stopPolling();
    final id = _pendingAlertId;
    if (id == null || id.isEmpty) return;
    _pollStartedAt = DateTime.now();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _pollResponderOnce(strings));
  }

  Future<void> _pollResponderOnce(AppStrings strings) async {
    if (!mounted) return;
    if (_pendingAlertId == null || _pollStartedAt == null) return;
    if (DateTime.now().difference(_pollStartedAt!) > _pollMaxWait) {
      _stopPolling();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.helpHubPollTimeout)),
        );
        setState(() => _sosPhase = _SosPhase.idle);
      }
      return;
    }
    try {
      final list = await ref.read(sosRepositoryProvider).getMyAlerts();
      if (!mounted) return;
      SosAlertModel? match;
      for (final a in list) {
        if (a.id == _pendingAlertId) {
          match = a;
          break;
        }
      }
      if (match != null && match.isEnRoute) {
        _stopPolling();
        final name = match.responderSummary ?? '';
        setState(() {
          _sosPhase = _SosPhase.confirmed;
          _responderDisplayName = name;
        });
        await _vibrateHappy();
        try {
          await _tts.speak(strings.helpHubResponderOnWay(name));
        } catch (_) {}
      }
    } catch (_) {}
  }

  Future<void> _entrySignature() async {
    if (!kIsWeb) {
      try {
        final has = await Vibration.hasVibrator();
        if (has == true) {
          await Vibration.vibrate(pattern: [0, 200, 100, 200]);
        }
      } catch (_) {}
    }
    final user = ref.read(authStateProvider).valueOrNull;
    final strings =
        AppStrings.fromPreferredLanguage(user?.preferredLanguage?.name);
    try {
      await _tts.setLanguage('fr-FR');
      await _tts.speak(strings.hapticHelpTtsEntry);
    } catch (_) {}
  }

  Future<void> _smallTapFeedback() async {
    HapticFeedback.lightImpact();
    if (kIsWeb) return;
    try {
      if (await Vibration.hasVibrator() == true) {
        await Vibration.vibrate(duration: 60);
      }
    } catch (_) {}
  }

  Future<void> _vibrateSosPattern() async {
    if (kIsWeb) return;
    try {
      if (await Vibration.hasVibrator() != true) return;
      for (var i = 0; i < 3; i++) {
        await Vibration.vibrate(duration: 100);
        await Future<void>.delayed(const Duration(milliseconds: 130));
      }
      await Future<void>.delayed(const Duration(milliseconds: 220));
      for (var i = 0; i < 3; i++) {
        await Vibration.vibrate(duration: 320);
        await Future<void>.delayed(const Duration(milliseconds: 150));
      }
      await Future<void>.delayed(const Duration(milliseconds: 220));
      for (var i = 0; i < 3; i++) {
        await Vibration.vibrate(duration: 100);
        await Future<void>.delayed(const Duration(milliseconds: 130));
      }
    } catch (_) {}
  }

  Future<void> _vibrateHappy() async {
    if (kIsWeb) return;
    try {
      if (await Vibration.hasVibrator() != true) return;
      for (var i = 0; i < 3; i++) {
        await Vibration.vibrate(duration: 100);
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    } catch (_) {}
  }

  void _resetSosFlow() {
    _stopPolling();
    setState(() {
      _sosPhase = _SosPhase.idle;
      _tapCount = 0;
      _lastTapAt = null;
      _responderDisplayName = '';
    });
  }

  Future<void> _onZoneTap() async {
    if (_sosPhase != _SosPhase.idle) return;
    final now = DateTime.now();
    if (_lastTapAt != null && now.difference(_lastTapAt!) > _tapResetAfter) {
      _tapCount = 0;
    }
    _lastTapAt = now;
    _tapCount++;
    setState(() {});
    unawaited(_smallTapFeedback());

    if (_tapCount < 3) return;
    _tapCount = 0;
    await _triggerEmergency();
  }

  Future<void> _triggerEmergency() async {
    if (_sosPhase != _SosPhase.idle) return;
    setState(() {
      _sosPhase = _SosPhase.sending;
    });

    final user = ref.read(authStateProvider).valueOrNull;
    final strings =
        AppStrings.fromPreferredLanguage(user?.preferredLanguage?.name);

    await _vibrateSosPattern();
    try {
      await _tts.speak(strings.helpHubTtsSearchVoluntary);
    } catch (_) {}

    if (kIsWeb) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.hapticHelpWebNotice)),
        );
        setState(() {
          _sosPhase = _SosPhase.sent;
          _responderDisplayName = '';
        });
      }
      return;
    }

    final pos = await getCurrentPositionOrNull();
    if (!mounted) return;
    if (pos == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings.locationUnavailable),
          backgroundColor: Colors.orange,
        ),
      );
      setState(() => _sosPhase = _SosPhase.idle);
      return;
    }

    try {
      final created = await ref.read(sosRepositoryProvider).create(
            latitude: pos.latitude,
            longitude: pos.longitude,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings.hapticHelpSosApiOk),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {
        _sosPhase = _SosPhase.sent;
        _pendingAlertId = created.id;
        _responderDisplayName = '';
      });
      _startPollingForResponder(strings);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _sosPhase = _SosPhase.idle);
    }
  }

  Future<void> _loadNearby() async {
    final user = ref.read(authStateProvider).valueOrNull;
    final strings =
        AppStrings.fromPreferredLanguage(user?.preferredLanguage?.name);
    setState(() {
      _nearbyLoading = true;
      _nearbyError = null;
    });
    if (kIsWeb) {
      setState(() {
        _nearbyLoading = false;
        _nearbyAlerts = [];
      });
      return;
    }
    final pos = await getCurrentPositionOrNull();
    if (!mounted) return;
    if (pos == null) {
      setState(() {
        _nearbyLoading = false;
        _nearbyError = strings.locationUnavailable;
        _nearbyAlerts = [];
      });
      return;
    }
    try {
      final list = await ref.read(sosRepositoryProvider).getNearby(
            latitude: pos.latitude,
            longitude: pos.longitude,
          );
      if (!mounted) return;
      setState(() {
        _nearbyAlerts = list;
        _nearbyLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _nearbyLoading = false;
        _nearbyError = strings.helpHubNearbyLoadError;
        _nearbyAlerts = [];
      });
    }
  }

  Color _sosRingColor(ThemeData theme) {
    switch (_sosPhase) {
      case _SosPhase.idle:
        return theme.colorScheme.outline.withValues(alpha: 0.35);
      case _SosPhase.sending:
      case _SosPhase.sent:
        return const Color(0xFFDC2626);
      case _SosPhase.confirmed:
        return const Color(0xFF22C55E);
    }
  }

  String _centerLabel(AppStrings strings) {
    switch (_sosPhase) {
      case _SosPhase.idle:
        return _tapCount == 0
            ? strings.helpHubSosLabel
            : strings.helpHubTapProgress(_tapCount, 3);
      case _SosPhase.sending:
        return strings.helpHubSosSending;
      case _SosPhase.sent:
        return strings.helpHubStatusWaiting;
      case _SosPhase.confirmed:
        return strings.helpHubSosOk;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final strings =
        AppStrings.fromPreferredLanguage(user?.preferredLanguage?.name);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.shield_outlined,
              color: _sosPhase == _SosPhase.sent
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(strings.helpHubTitle)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.tonal(
              onPressed: () {
                setState(() {
                  _panel = _panel == _HubPanel.send
                      ? _HubPanel.network
                      : _HubPanel.send;
                });
                if (_panel == _HubPanel.network) {
                  _loadNearby();
                }
              },
              child: Text(
                _panel == _HubPanel.send
                    ? strings.helpHubPanelNetwork
                    : strings.helpHubPanelBackSos,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _panel == _HubPanel.send
                ? _buildSendPanel(context, strings, theme)
                : _buildNetworkPanel(context, strings, theme),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            color: const Color(0xFF0F172A),
            child: Text(
              strings.helpHubFooter,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white70,
                letterSpacing: 1.2,
                fontFamily: 'monospace',
                fontSize: 9,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSendPanel(
    BuildContext context,
    AppStrings strings,
    ThemeData theme,
  ) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (_sosPhase == _SosPhase.confirmed) ...[
          Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFFDCFCE7),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.helpHubConfirmedResponder(_responderDisplayName),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF14532D),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          strings.helpHubConfirmedLine2,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF166534),
                          ),
                        ),
                        if (kIsWeb) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Chip(
                              label: Text(strings.helpHubDemoBadge),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              labelStyle: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _resetSosFlow,
            child: Text(strings.helpHubResetSos),
          ),
          const SizedBox(height: 20),
        ],
        if (kIsWeb)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              strings.hapticHelpWebNotice,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        if (_sosPhase == _SosPhase.sent && !kIsWeb)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        strings.helpHubWaitingResponder,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Center(
          child: Semantics(
            button: true,
            label: strings.hapticHelpTapIntro,
            child: Material(
              color: Colors.white,
              elevation: 8,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: (_sosPhase == _SosPhase.idle) ? _onZoneTap : null,
                child: Ink(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _sosRingColor(theme),
                      width: 10,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.fingerprint,
                        size: 88,
                        color: _sosPhase == _SosPhase.sent ||
                                _sosPhase == _SosPhase.sending
                            ? theme.colorScheme.error
                            : _sosPhase == _SosPhase.confirmed
                                ? const Color(0xFF22C55E)
                                : theme.colorScheme.outline,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _centerLabel(strings),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _StatusCard(
                icon: Icons.monitor_heart_outlined,
                label: strings.helpHubCardStatLabel,
                value: _sosPhase == _SosPhase.idle
                    ? strings.helpHubStatusReady
                    : _sosPhase == _SosPhase.confirmed
                        ? strings.helpHubStatusConfirmed
                        : strings.helpHubStatusWaiting,
                highlight: _sosPhase == _SosPhase.confirmed,
                iconColor: _sosPhase == _SosPhase.confirmed
                    ? const Color(0xFF22C55E)
                    : theme.colorScheme.error,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatusCard(
                icon: Icons.map_outlined,
                label: strings.helpHubCardNetworkLabel,
                value: strings.helpHubNetworkOk,
                highlight: false,
                iconColor: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: FilledButton.tonal(
                onPressed: () => context.push('/accompagnants'),
                child: Column(
                  children: [
                    const Icon(Icons.phone_in_talk_outlined),
                    const SizedBox(height: 6),
                    Text(
                      strings.hapticHelpCallContact,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () => context.push('/m3ak-inclusion'),
                child: Column(
                  children: [
                    const Icon(Icons.record_voice_over_outlined),
                    const SizedBox(height: 6),
                    Text(
                      strings.hapticHelpVocalGuide,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNetworkPanel(
    BuildContext context,
    AppStrings strings,
    ThemeData theme,
  ) {
    if (kIsWeb) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            strings.hapticHelpWebNotice,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadNearby,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            strings.helpHubNearbyTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            strings.helpHubNearbySubtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          if (_nearbyLoading)
            const Center(child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ))
          else if (_nearbyError != null)
            Text(
              _nearbyError!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            )
          else if (_nearbyAlerts.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 48),
              child: Text(
                strings.helpHubNearbyEmpty,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            ..._nearbyAlerts.map(
              (a) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.emergency_share,
                            color: Color(0xFFDC2626)),
                        title: Text(
                          a.reporterSummary ?? 'SOS',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '${a.latitude.toStringAsFixed(4)}, ${a.longitude.toStringAsFixed(4)}\n'
                          '${a.createdAt != null ? a.createdAt!.toLocal().toString() : ''}',
                          style: theme.textTheme.bodySmall,
                        ),
                        isThreeLine: true,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                        child: FilledButton.icon(
                          onPressed: _respondingIds.contains(a.id)
                              ? null
                              : () => _respondToAlert(a, strings),
                          icon: _respondingIds.contains(a.id)
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.directions_run, size: 20),
                          label: Text(strings.sosMyWayButton),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _respondToAlert(SosAlertModel a, AppStrings strings) async {
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
        SnackBar(
          content: Text('$e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _respondingIds.remove(a.id));
      }
    }
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.highlight,
    required this.iconColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool highlight;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 1,
      borderRadius: BorderRadius.circular(16),
      color: highlight ? const Color(0xFFF0FDF4) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(height: 6),
            Text(
              label.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
