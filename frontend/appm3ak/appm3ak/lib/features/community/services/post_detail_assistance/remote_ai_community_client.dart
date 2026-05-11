import 'package:dio/dio.dart';

import '../../../../data/api/endpoints.dart';
import '../../../../data/models/comment_model.dart';
import '../../../../data/models/post_model.dart';
import 'post_detail_assistance_models.dart';

/// Appels HTTP optionnels vers `/ai/community/*` — **silencieux** si la route n’existe pas encore.
///
/// Contrats de réponse attendus (souples) :
/// - summarize-post : `{ "summary": "..." }`
/// - summarize-comments : `{ "summary": "..." }`
/// - post-to-help-request : réservé (préférer logique locale + écran dédié).
class RemoteAiCommunityClient {
  RemoteAiCommunityClient(this._dio);

  final Dio _dio;

  String? _stringField(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }

  Future<PostSummaryResult?> summarizePost(PostModel post) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        Endpoints.aiCommunitySummarizePost,
        data: <String, dynamic>{
          'postId': post.id,
          'contenu': post.contenu,
          'type': post.type.toApiString(),
        },
      );
      final d = res.data;
      if (d == null) return null;
      final s = _stringField(d, ['summary', 'text', 'aperçu', 'apercu']);
      if (s == null) return null;
      return PostSummaryResult(
        summary: s,
        source: AssistanceSource.remote,
        postId: post.id,
      );
    } on DioException catch (_) {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<CommentsSummaryResult?> summarizeComments(
    PostModel post,
    List<CommentModel> comments,
  ) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        Endpoints.aiCommunitySummarizeComments,
        data: <String, dynamic>{
          'postId': post.id,
          'comments': comments
              .map(
                (c) => <String, dynamic>{
                  'id': c.id,
                  'contenu': c.contenu,
                  'userName': c.userName,
                },
              )
              .toList(),
        },
      );
      final d = res.data;
      if (d == null) return null;
      final s = _stringField(d, ['summary', 'text']);
      if (s == null) return null;
      return CommentsSummaryResult(
        summary: s,
        source: AssistanceSource.remote,
        postId: post.id,
        commentCount: comments.length,
      );
    } on DioException catch (_) {
      return null;
    } catch (_) {
      return null;
    }
  }
}
