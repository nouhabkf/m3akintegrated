import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/comment_model.dart';
import '../data/models/community_action_plan_result.dart';
import '../data/models/create_help_request_input.dart';
import '../data/models/create_post_input.dart';
import '../data/models/flash_summary_model.dart';
import '../data/models/help_request_model.dart';
import '../data/models/location_model.dart';
import '../data/models/post_model.dart';
import '../data/repositories/community_repository.dart';
import '../data/repositories/location_repository.dart';
import 'api_providers.dart';
import 'auth_providers.dart';

// ========== LOCATION PROVIDERS ==========

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return LocationRepository(apiClient: ref.watch(apiClientProvider));
});

final locationsProvider = FutureProvider<List<LocationModel>>((ref) async {
  final repository = ref.watch(locationRepositoryProvider);
  return repository.getAllLocations();
});

final locationByIdProvider =
    FutureProvider.family<LocationModel, String>((ref, locationId) async {
  final repository = ref.watch(locationRepositoryProvider);
  return repository.getLocationById(locationId);
});

final nearbyLocationsProvider =
    FutureProvider.family<List<LocationModel>, ({double lat, double lng, double? maxDistance})>(
  (ref, params) async {
    final repository = ref.watch(locationRepositoryProvider);
    return repository.getNearbyLocations(
      latitude: params.lat,
      longitude: params.lng,
      maxDistance: params.maxDistance,
    );
  },
);

final submitLocationProvider = FutureProvider.family<void, ({
  String nom,
  String categorie,
  String adresse,
  String ville,
  double latitude,
  double longitude,
  String? description,
  String? telephone,
  String? horaires,
  List<String>? amenities,
  List<File>? images,
})>((ref, params) async {
  final repository = ref.watch(locationRepositoryProvider);
  await repository.submitLocation(
    nom: params.nom,
    categorie: params.categorie,
    adresse: params.adresse,
    ville: params.ville,
    latitude: params.latitude,
    longitude: params.longitude,
    description: params.description,
    telephone: params.telephone,
    horaires: params.horaires,
    amenities: params.amenities,
    images: params.images,
  );
  ref.invalidate(locationsProvider);
});

// ========== COMMUNITY REPOSITORY PROVIDER ==========

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return CommunityRepository(apiClient: ref.watch(apiClientProvider));
});

// ========== POSTS PROVIDERS ==========

final postsProvider = FutureProvider.family<
    ({List<PostModel> posts, int total, int page, int totalPages}),
    ({int page, int limit})>((ref, params) async {
  final repository = ref.watch(communityRepositoryProvider);
  return repository.getPosts(page: params.page, limit: params.limit);
});

/// Filtre global ou smart (`for-me` backend) — un seul flux pour l’écran liste.
final communityFeedProvider = FutureProvider.family<
    ({
      List<PostModel> posts,
      int total,
      int page,
      int totalPages,
      List<String> matchedTypes,
    }),
    ({
      int page,
      int limit,
      bool smart,
    })>((ref, params) async {
  final repository = ref.watch(communityRepositoryProvider);
  if (params.smart) {
    final r = await repository.getPostsForMe(
      page: params.page,
      limit: params.limit,
    );
    return (
      posts: r.posts,
      total: r.total,
      page: r.page,
      totalPages: r.totalPages,
      matchedTypes: r.matchedTypes,
    );
  }
  final r = await repository.getPosts(
    page: params.page,
    limit: params.limit,
  );
  return (
    posts: r.posts,
    total: r.total,
    page: r.page,
    totalPages: r.totalPages,
    matchedTypes: <String>[],
  );
});

final postByIdProvider =
    FutureProvider.family<PostModel, String>((ref, postId) async {
  final repository = ref.watch(communityRepositoryProvider);
  return repository.getPostById(postId);
});

/// État Merci (connecté) ou décompte seul (invité).
final postMerciStateProvider = FutureProvider.family<
    ({bool thankReceivedFromMe, int merciCount}),
    String>((ref, postId) async {
  final repository = ref.watch(communityRepositoryProvider);
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) {
    final post = await ref.read(postByIdProvider(postId).future);
    return (thankReceivedFromMe: false, merciCount: post.merciCount);
  }
  try {
    return await repository.getPostMerciState(postId);
  } catch (_) {
    final post = await ref.read(postByIdProvider(postId).future);
    return (thankReceivedFromMe: false, merciCount: post.merciCount);
  }
});

final createPostProvider = FutureProvider.family<PostModel, CreatePostInput>((ref, input) async {
  final repository = ref.watch(communityRepositoryProvider);
  final post = await repository.createPost(input);
  ref.invalidate(postsProvider((page: 1, limit: 20)));
  ref.invalidate(communityFeedProvider((
    page: 1,
    limit: 20,
    smart: false,
  )));
  ref.invalidate(communityFeedProvider((
    page: 1,
    limit: 20,
    smart: true,
  )));
  return post;
});

final communityActionPlanProvider = FutureProvider.family<
    CommunityActionPlanResult,
    ({
      String text,
      String? contextHint,
      String? inputModeHint,
      bool? isForAnotherPersonHint,
    })>((ref, params) async {
  final repository = ref.watch(communityRepositoryProvider);
  return repository.getCommunityActionPlan(
    text: params.text,
    contextHint: params.contextHint,
    inputModeHint: params.inputModeHint,
    isForAnotherPersonHint: params.isForAnotherPersonHint,
  );
});

// ========== COMMENTS PROVIDERS ==========

final postCommentsProvider =
    FutureProvider.family<List<CommentModel>, String>((ref, postId) async {
  final repository = ref.watch(communityRepositoryProvider);
  return repository.getPostComments(postId);
});

final postCommentsFlashSummaryProvider =
    FutureProvider.family<FlashSummaryModel, String>((ref, postId) async {
  final repository = ref.watch(communityRepositoryProvider);
  return repository.getPostCommentsFlashSummary(postId);
});

final createCommentProvider = FutureProvider.family<CommentModel, ({
  String postId,
  String contenu,
})>((ref, params) async {
  final repository = ref.watch(communityRepositoryProvider);
  final comment = await repository.createComment(
    postId: params.postId,
    contenu: params.contenu,
  );
  ref.invalidate(postCommentsProvider(params.postId));
  return comment;
});

// ========== HELP REQUESTS PROVIDERS ==========

final helpRequestsProvider = FutureProvider.family<
    ({List<HelpRequestModel> requests, int total, int page, int totalPages}),
    ({int page, int limit})>((ref, params) async {
  final repository = ref.watch(communityRepositoryProvider);
  return repository.getHelpRequests(page: params.page, limit: params.limit);
});

final createHelpRequestProvider =
    FutureProvider.family<HelpRequestModel, CreateHelpRequestInput>((ref, input) async {
  final repository = ref.watch(communityRepositoryProvider);
  final request = await repository.createHelpRequest(input);
  invalidateHelpRequestListCaches(ref);
  return request;
});

/// Invalide les listes paginées [helpRequestsProvider] (pages 1–10, limite 20).
///
/// Accepte [Ref] (providers) et [WidgetRef] (widgets) — les deux exposent [invalidate].
void invalidateHelpRequestListCaches(dynamic ref) {
  const limit = 20;
  for (var page = 1; page <= 10; page++) {
    ref.invalidate(helpRequestsProvider((page: page, limit: limit)));
  }
}

final updateHelpRequestStatusProvider = FutureProvider.family<HelpRequestModel, ({
  String id,
  String statut,
})>((ref, params) async {
  final repository = ref.watch(communityRepositoryProvider);
  final request = await repository.updateHelpRequestStatus(
    id: params.id,
    statut: params.statut,
  );
  invalidateHelpRequestListCaches(ref);
  return request;
});

// ========== MESSAGES (MVP local state) ==========

class CommunityMessageThreadPreview {
  const CommunityMessageThreadPreview({
    required this.otherUserId,
    required this.otherUserName,
    required this.lastMessage,
    required this.lastAt,
  });

  final String otherUserId;
  final String otherUserName;
  final String lastMessage;
  final DateTime lastAt;
}

class CommunityChatMessage {
  const CommunityChatMessage({
    required this.id,
    required this.otherUserId,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String otherUserId;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime createdAt;
}

class CommunityMessagesNotifier extends StateNotifier<List<CommunityChatMessage>> {
  CommunityMessagesNotifier() : super(const []);

  List<CommunityChatMessage> messagesWith(String otherUserId) {
    final items = state.where((m) => m.otherUserId == otherUserId).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return items;
  }

  void sendMessage({
    required String currentUserId,
    required String otherUserId,
    required String text,
  }) {
    final clean = text.trim();
    if (clean.isEmpty) return;
    final now = DateTime.now();
    state = [
      ...state,
      CommunityChatMessage(
        id: '${now.microsecondsSinceEpoch}_$currentUserId',
        otherUserId: otherUserId,
        senderId: currentUserId,
        receiverId: otherUserId,
        text: clean,
        createdAt: now,
      ),
    ];
  }

  void receiveMockMessage({
    required String currentUserId,
    required String otherUserId,
    required String text,
  }) {
    final clean = text.trim();
    if (clean.isEmpty) return;
    final now = DateTime.now();
    state = [
      ...state,
      CommunityChatMessage(
        id: '${now.microsecondsSinceEpoch}_$otherUserId',
        otherUserId: otherUserId,
        senderId: otherUserId,
        receiverId: currentUserId,
        text: clean,
        createdAt: now,
      ),
    ];
  }

  List<CommunityMessageThreadPreview> threadPreviews({
    required String currentUserId,
    Map<String, String>? names,
  }) {
    final byUser = <String, CommunityChatMessage>{};
    for (final m in state) {
      final prev = byUser[m.otherUserId];
      if (prev == null || m.createdAt.isAfter(prev.createdAt)) {
        byUser[m.otherUserId] = m;
      }
    }
    final previews = byUser.entries.map((e) {
      final uid = e.key;
      final msg = e.value;
      return CommunityMessageThreadPreview(
        otherUserId: uid,
        otherUserName: names?[uid] ?? 'Utilisateur',
        lastMessage: msg.text,
        lastAt: msg.createdAt,
      );
    }).toList()
      ..sort((a, b) => b.lastAt.compareTo(a.lastAt));
    return previews;
  }
}

final communityMessagesProvider =
    StateNotifierProvider<CommunityMessagesNotifier, List<CommunityChatMessage>>(
  (ref) => CommunityMessagesNotifier(),
);
