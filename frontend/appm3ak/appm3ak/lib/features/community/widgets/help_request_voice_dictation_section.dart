import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../logic/help_request_voice_dictation_controller.dart';

/// Bloc dictée : gros bouton micro + états accessibles + texte d’aide.
class HelpRequestVoiceDictationSection extends StatelessWidget {
  const HelpRequestVoiceDictationSection({
    super.key,
    required this.controller,
    required this.strings,
  });

  final HelpRequestVoiceDictationController controller;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final phase = controller.phase;
        final listening = controller.isListening;

        final statusText = _statusLabel(strings, phase, controller.errorCode);
        final semanticMic = listening
            ? strings.helpVoiceMicSemanticsStop
            : strings.helpVoiceMicSemanticsStart;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (kIsWeb)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  strings.helpVoiceWebHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            Center(
              child: Semantics(
                button: true,
                label: semanticMic,
                hint: statusText,
                child: Material(
                  color: phase == HelpRequestVoicePhase.error
                      ? cs.errorContainer
                      : (listening
                          ? cs.primaryContainer
                          : cs.surfaceContainerHighest),
                  shape: const CircleBorder(),
                  elevation: listening ? 6 : 0,
                  shadowColor: listening ? cs.primary.withValues(alpha: 0.35) : null,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: phase == HelpRequestVoicePhase.uninitialized
                        ? null
                        : () => controller.toggleListen(),
                    child: SizedBox(
                      width: 88,
                      height: 88,
                      child: Icon(
                        phase == HelpRequestVoicePhase.error
                            ? Icons.mic_off_rounded
                            : (listening
                                ? Icons.mic_rounded
                                : Icons.mic_none_rounded),
                        size: 44,
                        color: phase == HelpRequestVoicePhase.error
                            ? cs.onErrorContainer
                            : (listening
                                ? cs.onPrimaryContainer
                                : cs.primary),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              label: statusText,
              child: Text(
                statusText,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: phase == HelpRequestVoicePhase.error
                      ? cs.error
                      : cs.onSurface,
                ),
              ),
            ),
            if (phase == HelpRequestVoicePhase.error) ...[
              const SizedBox(height: 8),
              Semantics(
                button: true,
                label: strings.helpVoiceRetry,
                child: OutlinedButton.icon(
                  onPressed: () => controller.retry(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(strings.helpVoiceRetry),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ),
            ],
            if (phase == HelpRequestVoicePhase.recognized) ...[
              const SizedBox(height: 4),
              Text(
                strings.helpVoiceShortOkHint,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  String _statusLabel(
    AppStrings strings,
    HelpRequestVoicePhase phase,
    String? errorCode,
  ) {
    switch (phase) {
      case HelpRequestVoicePhase.uninitialized:
        return strings.helpVoiceStateUninitialized;
      case HelpRequestVoicePhase.ready:
        return strings.helpVoiceStateReady;
      case HelpRequestVoicePhase.listening:
        return strings.helpVoiceStateListening;
      case HelpRequestVoicePhase.recognized:
        return strings.helpVoiceStateRecognized;
      case HelpRequestVoicePhase.error:
        return strings.helpVoiceErrorMessage(errorCode);
    }
  }
}
