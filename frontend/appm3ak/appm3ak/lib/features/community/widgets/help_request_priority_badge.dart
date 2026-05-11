import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';

/// Badge de priorité d’une demande d’aide : libellé explicite + bordure + icône (pas seulement la couleur).
class HelpRequestPriorityBadge extends StatelessWidget {
  const HelpRequestPriorityBadge({
    super.key,
    required this.priorityRaw,
    required this.strings,
    this.compact = false,
  });

  final String? priorityRaw;
  final AppStrings strings;
  /// Liste : légèrement plus compact ; détail : plus grand.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final label = strings.helpRequestPriorityLabel(priorityRaw);
    if (label.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final style = _styleFor(priorityRaw, theme);
    final icon = _iconFor(priorityRaw);
    final semantic =
        '${strings.helpRequestPrioritySemanticLabel}: $label';

    final pad = compact
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
        : const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
    final fontSize = compact ? 14.0 : 16.0;
    final iconSize = compact ? 20.0 : 24.0;

    return Semantics(
      label: semantic,
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: style.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: style.border, width: 2),
          ),
          child: Padding(
            padding: pad,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: iconSize, color: style.foreground),
                SizedBox(width: compact ? 8 : 10),
                Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: style.foreground,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _BadgeVisual _styleFor(String? raw, ThemeData theme) {
    final cs = theme.colorScheme;
    switch (raw?.toLowerCase()) {
      case 'critical':
        return _BadgeVisual(
          background: cs.errorContainer,
          border: cs.error,
          foreground: cs.onErrorContainer,
        );
      case 'high':
        return _BadgeVisual(
          background: cs.errorContainer.withValues(alpha: 0.65),
          border: cs.error,
          foreground: cs.onErrorContainer,
        );
      case 'medium':
        return _BadgeVisual(
          background: cs.tertiaryContainer,
          border: cs.tertiary,
          foreground: cs.onTertiaryContainer,
        );
      case 'low':
        return _BadgeVisual(
          background: cs.surfaceContainerHighest,
          border: cs.outline,
          foreground: cs.onSurface,
        );
      default:
        return _BadgeVisual(
          background: cs.surfaceContainerHighest,
          border: cs.outline,
          foreground: cs.onSurfaceVariant,
        );
    }
  }

  IconData _iconFor(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'critical':
        return Icons.emergency_rounded;
      case 'high':
        return Icons.priority_high_rounded;
      case 'medium':
        return Icons.flag_rounded;
      case 'low':
        return Icons.horizontal_rule_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }
}

class _BadgeVisual {
  const _BadgeVisual({
    required this.background,
    required this.border,
    required this.foreground,
  });

  final Color background;
  final Color border;
  final Color foreground;
}
