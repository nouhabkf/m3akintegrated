import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../data/models/help_request_model.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/community_providers.dart';
import '../widgets/help_request_inclusive_ui.dart';
import '../widgets/help_request_priority_badge.dart';

/// Détail d’une demande d’aide (priorité, texte, justification optionnelle).
class HelpRequestDetailScreen extends ConsumerStatefulWidget {
  const HelpRequestDetailScreen({super.key, required this.request});

  final HelpRequestModel request;

  @override
  ConsumerState<HelpRequestDetailScreen> createState() =>
      _HelpRequestDetailScreenState();
}

class _HelpRequestDetailScreenState extends ConsumerState<HelpRequestDetailScreen> {
  bool _isAccepting = false;

  Future<void> _accept() async {
    if (_isAccepting) return;
    setState(() => _isAccepting = true);
    try {
      final repository = ref.read(communityRepositoryProvider);
      await repository.acceptHelpRequest(id: widget.request.id);
      await ref.read(authStateProvider.notifier).refreshUser();
      invalidateHelpRequestListCaches(ref);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demande acceptée.')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur acceptation: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isAccepting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final strings =
        AppStrings.fromPreferredLanguage(user?.preferredLanguage?.name);
    final theme = Theme.of(context);
    final r = widget.request;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.helpRequestDetailTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (strings.helpRequestPriorityLabel(r.priority).isNotEmpty) ...[
              HelpRequestPriorityBadge(
                priorityRaw: r.priority,
                strings: strings,
                compact: false,
              ),
              const SizedBox(height: 20),
            ],
            Text(
              r.userName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (r.createdAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _formatRelativeDate(r.createdAt!),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            HelpRequestMetaRow(
              icon: Icons.assignment_outlined,
              label: r.statut.displayName,
              semanticLabel: r.statut.displayName,
            ),
            const SizedBox(height: 12),
            HelpRequestMetaRow(
              icon: Icons.category_outlined,
              label: strings.helpRequestHelpTypeLabel(r.helpType),
              semanticLabel:
                  '${strings.helpRequestHelpTypeHeading}: ${strings.helpRequestHelpTypeLabel(r.helpType)}',
            ),
            const SizedBox(height: 8),
            HelpRequestMetaRow(
              icon: Icons.touch_app_outlined,
              label: strings.helpRequestInputModeLabel(r.inputMode),
              semanticLabel:
                  '${strings.helpRequestInputModeHeading}: ${strings.helpRequestInputModeLabel(r.inputMode)}',
            ),
            if (r.isCaregiverRequest) ...[
              const SizedBox(height: 12),
              HelpRequestCaregiverChip(strings: strings, compact: false),
            ],
            const SizedBox(height: 20),
            Text(
              strings.helpRequestDescriptionHeading,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Semantics(
              label:
                  '${strings.helpRequestDescriptionHeading}. ${r.description}',
              child: Text(
                r.description.trim().isEmpty
                    ? strings.helpRequestSummaryFallback
                    : r.description,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
              ),
            ),
            if (r.priorityReason != null && r.priorityReason!.trim().isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                strings.helpRequestPriorityReasonHeading,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Semantics(
                label:
                    '${strings.helpRequestPriorityReasonHeading}. ${r.priorityReason}',
                child: Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerHighest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      r.priorityReason!,
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
                    ),
                  ),
                ),
              ),
            ],
            HelpRequestPrioritySignalsDebugPanel(
              signals: r.prioritySignals,
              strings: strings,
            ),
            const SizedBox(height: 20),
            Text(
              strings.helpRequestAccessibilityHeading,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Semantics(
              label:
                  '${strings.helpRequestAccessibilityHeading}. ${strings.helpRequestNeedsSummary(
                audio: r.needsAudioGuidance,
                visual: r.needsVisualSupport,
                physical: r.needsPhysicalAssistance,
                simpleLang: r.needsSimpleLanguage,
              )}',
              child: Text(
                strings.helpRequestNeedsSummary(
                  audio: r.needsAudioGuidance,
                  visual: r.needsVisualSupport,
                  physical: r.needsPhysicalAssistance,
                  simpleLang: r.needsSimpleLanguage,
                ),
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
              ),
            ),
            const SizedBox(height: 20),
            HelpRequestMetaRow(
              icon: Icons.location_on_outlined,
              label:
                  '${r.latitude.toStringAsFixed(5)}, ${r.longitude.toStringAsFixed(5)}',
              semanticLabel:
                  '${strings.location}: ${r.latitude.toStringAsFixed(5)}, ${r.longitude.toStringAsFixed(5)}',
            ),
            if (r.statut == HelpRequestStatus.enAttente) ...[
              const SizedBox(height: 28),
              Semantics(
                button: true,
                label: strings.helpRequestAcceptThisLabel,
                child: FilledButton.icon(
                  onPressed: _isAccepting ? null : _accept,
                  icon: const Icon(Icons.handshake_outlined),
                  label: Text(
                    _isAccepting
                        ? strings.helpRequestAcceptingLabel
                        : strings.helpRequestAcceptThisLabel,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    }
    if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    }
    if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    }
    if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    }
    return 'À l\'instant';
  }
}
