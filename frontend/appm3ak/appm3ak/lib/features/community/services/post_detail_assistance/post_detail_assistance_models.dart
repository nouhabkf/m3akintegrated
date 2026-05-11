import 'package:equatable/equatable.dart';

import '../../models/help_request_quick_preset.dart';

/// Origine du résultat : heuristique locale ou route `/ai/community/*`.
enum AssistanceSource {
  local,
  remote,
}

/// Résumé du contenu d’un post (aperçu / TTS / accessibilité).
class PostSummaryResult extends Equatable {
  const PostSummaryResult({
    required this.summary,
    required this.source,
    required this.postId,
  });

  final String summary;
  final AssistanceSource source;
  final String postId;

  @override
  List<Object?> get props => [summary, source, postId];
}

/// Résumé des commentaires d’un post.
class CommentsSummaryResult extends Equatable {
  const CommentsSummaryResult({
    required this.summary,
    required this.source,
    required this.postId,
    required this.commentCount,
  });

  final String summary;
  final AssistanceSource source;
  final String postId;
  final int commentCount;

  @override
  List<Object?> get props => [summary, source, postId, commentCount];
}

/// Brouillon pour préremplir [CreateHelpRequestScreen] depuis un post.
///
/// Passé via `GoRouterState.extra` vers `/create-help-request`.
class HelpRequestFromPostPrefill extends Equatable {
  const HelpRequestFromPostPrefill({
    required this.description,
    required this.suggestedPreset,
    this.needsAudioGuidance,
    this.needsVisualSupport,
    this.needsPhysicalAssistance,
    this.needsSimpleLanguage,
    this.isForAnotherPerson,
  });

  final String description;
  final HelpRequestQuickPreset suggestedPreset;
  final bool? needsAudioGuidance;
  final bool? needsVisualSupport;
  final bool? needsPhysicalAssistance;
  final bool? needsSimpleLanguage;
  final bool? isForAnotherPerson;

  @override
  List<Object?> get props => [
        description,
        suggestedPreset,
        needsAudioGuidance,
        needsVisualSupport,
        needsPhysicalAssistance,
        needsSimpleLanguage,
        isForAnotherPerson,
      ];
}
