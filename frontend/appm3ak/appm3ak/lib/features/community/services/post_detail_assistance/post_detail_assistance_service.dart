import '../../../../data/models/comment_model.dart';
import '../../../../data/models/flash_summary_model.dart';
import '../../../../data/models/post_model.dart';
import 'post_detail_assistance_models.dart';

/// Contrat pour les aides « IA-ready » sur l’écran détail post.
///
/// Les implémentations peuvent combiner des appels HTTP futurs (`/ai/community/*`)
/// et des [AssistanceSource.local] heuristiques sans casser l’UI.
abstract class PostDetailAssistanceService {
  /// Résumé court du post (aperçu accessibilité).
  Future<PostSummaryResult> summarizePost(PostModel post);

  /// Résumé des commentaires (texte concaténé tronqué en local ; JSON serveur plus tard).
  Future<CommentsSummaryResult> summarizeComments(
    PostModel post,
    List<CommentModel> comments,
  );

  /// Préremplissage pour l’écran [CreateHelpRequestScreen] (position saisie sur place).
  HelpRequestFromPostPrefill buildHelpRequestFromPost(PostModel post);

  /// Texte optimisé pour synthèse vocale (phrases courtes, intro auteur).
  String buildTtsReadablePost(PostModel post);

  /// Texte vocal pour le résumé rapide (flash summary).
  String buildTtsReadableFlashSummary(PostModel post, FlashSummaryModel flash);

  /// Texte vocal pour la liste des commentaires (tronqué si très long).
  String buildTtsReadableComments(PostModel post, List<CommentModel> comments);
}
