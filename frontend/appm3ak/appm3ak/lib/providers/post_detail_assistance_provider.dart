import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/community/services/post_detail_assistance/default_post_detail_assistance_service.dart';
import '../features/community/services/post_detail_assistance/post_detail_assistance_models.dart';
import '../features/community/services/post_detail_assistance/post_detail_assistance_service.dart';
import '../features/community/services/post_detail_assistance/remote_ai_community_client.dart';
import 'api_providers.dart';
import 'community_providers.dart';

/// Service unique (local + remote optionnel) pour le détail post.
final postDetailAssistanceProvider = Provider<PostDetailAssistanceService>((ref) {
  final dio = ref.watch(apiClientProvider).dio;
  return DefaultPostDetailAssistanceService(
    remote: RemoteAiCommunityClient(dio),
  );
});

/// Résumé « assistance » du post (cache par [postId]).
final postDetailAssistancePostSummaryProvider =
    FutureProvider.family<PostSummaryResult, String>((ref, postId) async {
  final post = await ref.watch(postByIdProvider(postId).future);
  return ref.read(postDetailAssistanceProvider).summarizePost(post);
});

/// Résumé des commentaires via la même couche (se met à jour si la liste commentaires change).
final postDetailAssistanceCommentsSummaryProvider =
    FutureProvider.family<CommentsSummaryResult, String>((ref, postId) async {
  final post = await ref.watch(postByIdProvider(postId).future);
  final comments = await ref.watch(postCommentsProvider(postId).future);
  return ref
      .read(postDetailAssistanceProvider)
      .summarizeComments(post, comments);
});
