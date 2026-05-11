import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vibration/vibration.dart';

import '../../data/models/create_help_request_input.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/location/current_position.dart';
import '../../providers/auth_providers.dart';
import '../../providers/community_providers.dart';
import 'back_tap_sensors.dart';
import 'canned_post_phrases.dart';

/// Menu par vibrations : N impulsions = option N ; confirmer par **volume+** (Android)
/// ou tap dos ; envoi d’une **demande d’aide** avec la position GPS.
class VibrationCodedPostScreen extends ConsumerStatefulWidget {
  const VibrationCodedPostScreen({super.key});

  @override
  ConsumerState<VibrationCodedPostScreen> createState() =>
      _VibrationCodedPostScreenState();
}

class _VibrationCodedPostScreenState
    extends ConsumerState<VibrationCodedPostScreen> {
  static const Duration _optionWindow = Duration(seconds: 5);

  bool _menuRunning = false;
  String _status =
      'Démarrer le menu. Après chaque série de vibrations : confirmez avec la touche volume+ '
      '(ou tap sur le dos du téléphone). Une demande d’aide part avec votre position.';

  Future<void> _vibratePulseCount(int n) async {
    final has = await Vibration.hasVibrator();
    if (has != true) return;
    for (var i = 0; i < n; i++) {
      await Vibration.vibrate(duration: 90);
      await Future<void>.delayed(const Duration(milliseconds: 240));
    }
  }

  Future<String?> _sendHelpForPhrase(int phraseIndex) async {
    final user = ref.read(authStateProvider).valueOrNull;
    final strings =
        AppStrings.fromPreferredLanguage(user?.preferredLanguage?.name);
    final pos = await getCurrentPositionOrNull();
    if (pos == null) {
      return strings.locationUnavailable;
    }
    final desc = kAccessibilityCannedPostPhrases[phraseIndex];
    await ref.read(
      createHelpRequestProvider(
        CreateHelpRequestInput(
          description: desc,
          latitude: pos.latitude,
          longitude: pos.longitude,
          inputMode: 'tap',
        ),
      ).future,
    );
    return null;
  }

  Future<void> _runMenu() async {
    if (_menuRunning) return;
    setState(() {
      _menuRunning = true;
      _status = 'Menu en cours…';
    });

    try {
      final n = kAccessibilityCannedPostPhrases.length;
      for (var i = 0; i < n; i++) {
        if (!mounted) return;
        final option = i + 1;
        setState(() {
          _status =
              'Option $option sur $n : $option vibration(s). '
              'Volume+ ou tap dos pour confirmer et envoyer l’aide avec votre position.';
        });
        await _vibratePulseCount(option);
        final picked = await waitForVolumeOrBackTap(
          window: _optionWindow,
          isListening: () => mounted && _menuRunning,
        );
        if (!picked || !mounted) continue;

        HapticFeedback.mediumImpact();
        final err = await _sendHelpForPhrase(i);
        if (!mounted) return;
        final user = ref.read(authStateProvider).valueOrNull;
        final strings =
            AppStrings.fromPreferredLanguage(user?.preferredLanguage?.name);
        if (err == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(strings.helpRequestCreatedSuccess),
              backgroundColor: Colors.green,
            ),
          );
          context.pop();
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (mounted) {
        setState(() {
          _status =
              'Aucun choix détecté. Réessayez, ou utilisez le bouton de secours.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _menuRunning = false);
      }
    }
  }

  Future<void> _pickManually(int index) async {
    HapticFeedback.lightImpact();
    setState(() => _menuRunning = true);
    final err = await _sendHelpForPhrase(index);
    if (!mounted) return;
    final user = ref.read(authStateProvider).valueOrNull;
    final strings =
        AppStrings.fromPreferredLanguage(user?.preferredLanguage?.name);
    setState(() => _menuRunning = false);
    if (err == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings.helpRequestCreatedSuccess),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final strings =
        AppStrings.fromPreferredLanguage(user?.preferredLanguage?.name);
    final theme = Theme.of(context);

    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(title: const Text('Post par vibrations')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Les capteurs de mouvement et le moteur haptique ne sont pas disponibles sur le web. Utilisez l’application sur téléphone.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post — vibrations'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _menuRunning ? null : () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Sourd-aveugle — vibration codée',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            strings.helpVolumeShortcutHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _status,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _menuRunning ? null : _runMenu,
            icon: const Icon(Icons.play_arrow),
            label: Text(_menuRunning ? 'Patience…' : 'Démarrer le menu'),
          ),
          const SizedBox(height: 24),
          Text(
            'Secours (accompagnant)',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          ...List.generate(kAccessibilityCannedPostPhrases.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton(
                onPressed: _menuRunning ? null : () => _pickManually(i),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${i + 1}. ${kAccessibilityCannedPostPhrases[i]}',
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
          Text(
            strings.vibrationPostExplainerTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            strings.vibrationPostExplainerBody,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _menuRunning
                ? null
                : () => context.push<void>('/create-post'),
            icon: const Icon(Icons.article_outlined),
            label: Text(strings.vibrationPostOpenFullForm),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _menuRunning
                ? null
                : () => context.push<void>('/create-post-head-gesture'),
            icon: const Icon(Icons.face_retouching_natural),
            label: Text(strings.postShortcutHeadTitle),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _menuRunning
                ? null
                : () => context.push<void>('/create-post-voice-vibration'),
            icon: const Icon(Icons.record_voice_over_outlined),
            label: Text(strings.postShortcutVoiceVibTitle),
          ),
        ],
      ),
    );
  }
}
