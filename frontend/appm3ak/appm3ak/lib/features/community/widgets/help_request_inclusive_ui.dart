import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../data/models/help_request_model.dart';

/// Ligne compacte : icône + texte (pas seulement la couleur).
class HelpRequestMetaRow extends StatelessWidget {
  const HelpRequestMetaRow({
    super.key,
    required this.icon,
    required this.label,
    required this.semanticLabel,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final String semanticLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Semantics(
      label: semanticLabel,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: compact ? 18 : 20, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: compact
                  ? theme.textTheme.bodySmall
                  : theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge « accompagnant » : bordure + icône + texte.
class HelpRequestCaregiverChip extends StatelessWidget {
  const HelpRequestCaregiverChip({
    super.key,
    required this.strings,
    this.compact = false,
  });

  final AppStrings strings;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Semantics(
      label: strings.helpRequestCaregiverSemantic,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cs.secondaryContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.outline, width: 1.5),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12,
            vertical: compact ? 6 : 8,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.family_restroom_rounded,
                size: compact ? 18 : 20,
                color: cs.onSecondaryContainer,
              ),
              SizedBox(width: compact ? 6 : 8),
              Text(
                strings.helpRequestCaregiverBadge,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSecondaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String helpRequestListSummary(HelpRequestModel r, AppStrings strings) {
  final t = r.description.trim();
  if (t.isEmpty) {
    return strings.helpRequestSummaryFallback;
  }
  const maxChars = 160;
  if (t.length <= maxChars) return t;
  return '${t.substring(0, maxChars - 1)}…';
}

/// Section signaux (debug) — texte brut, repliable.
class HelpRequestPrioritySignalsDebugPanel extends StatelessWidget {
  const HelpRequestPrioritySignalsDebugPanel({
    super.key,
    required this.signals,
    required this.strings,
  });

  final List<String>? signals;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    if (signals == null || signals!.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return ExpansionTile(
      title: Text(
        strings.helpRequestDeveloperSignalsTitle,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        strings.helpRequestDeveloperSignalsSubtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SelectableText(
            signals!.join('\n'),
            style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
          ),
        ),
      ],
    );
  }
}
