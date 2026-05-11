import '../../../../core/config/app_config.dart';
import '../../../../data/models/comment_model.dart';
import '../../../../data/models/flash_summary_model.dart';
import '../../../../data/models/post_model.dart';
import 'local_post_detail_assistance_service.dart';
import 'post_detail_assistance_models.dart';
import 'post_detail_assistance_service.dart';
import 'remote_ai_community_client.dart';

/// Chaîne **remote (optionnelle)** → **local** sans erreur utilisateur.
///
/// Activez les appels réseau avec `--dart-define=AI_COMMUNITY_REMOTE=true`
/// lorsque le backend expose `/ai/community/*`.
class DefaultPostDetailAssistanceService implements PostDetailAssistanceService {
  DefaultPostDetailAssistanceService({
    LocalPostDetailAssistanceService? local,
    RemoteAiCommunityClient? remote,
  })  : _local = local ?? LocalPostDetailAssistanceService(),
        _remote = remote;

  final LocalPostDetailAssistanceService _local;
  final RemoteAiCommunityClient? _remote;

  bool get _useRemote => AppConfig.aiCommunityRemoteEnabled && _remote != null;

  @override
  Future<PostSummaryResult> summarizePost(PostModel post) async {
    if (_useRemote) {
      final r = await _remote!.summarizePost(post);
      if (r != null) return r;
    }
    return _local.summarizePost(post);
  }

  @override
  Future<CommentsSummaryResult> summarizeComments(
    PostModel post,
    List<CommentModel> comments,
  ) async {
    if (_useRemote) {
      final r = await _remote!.summarizeComments(post, comments);
      if (r != null) return r;
    }
    return _local.summarizeComments(post, comments);
  }

  @override
  HelpRequestFromPostPrefill buildHelpRequestFromPost(PostModel post) {
    return _local.buildHelpRequestFromPost(post);
  }

  @override
  String buildTtsReadablePost(PostModel post) {
    return _local.buildTtsReadablePost(post);
  }

  @override
  String buildTtsReadableFlashSummary(PostModel post, FlashSummaryModel flash) {
    return _local.buildTtsReadableFlashSummary(post, flash);
  }

  @override
  String buildTtsReadableComments(PostModel post, List<CommentModel> comments) {
    return _local.buildTtsReadableComments(post, comments);
  }
}
