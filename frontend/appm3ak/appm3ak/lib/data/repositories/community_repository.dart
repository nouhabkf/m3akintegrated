import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../api/api_client.dart';
import '../api/endpoints.dart';
import '../../core/config/app_config.dart';
import '../models/comment_model.dart';
import '../models/community_action_plan_result.dart';
import '../models/flash_summary_model.dart';
import '../models/create_help_request_input.dart';
import '../models/create_post_input.dart';
import '../models/help_request_model.dart';
import '../models/post_model.dart';

/// Repository pour gérer les posts et demandes d'aide de la communauté.
class CommunityRepository {
  CommunityRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;


  /// URL d’une image stockée côté API (`uploads/post-….jpg`).
  /// Normalise les séparateurs (évite les 404 si le chemin contient des `\` côté serveur).
  static String uploadUrl(String path) {
    if (path.isEmpty) return '';
    final base = AppConfig.uploadsBaseUrl.replaceAll(RegExp(r'/$'), '');

    var clean = path
        .replaceFirst(RegExp(r'^/'), '')
        .replaceAll(r'\', '/')
        .trim();

    final baseHasUploads = RegExp(r'/uploads$').hasMatch(base);

    // Si le backend renvoie "community/post-..." (sans "uploads/"),
    // on force le préfixe attendu par le serveur (/uploads).
    if (!baseHasUploads && !clean.startsWith('uploads/')) {
      clean = 'uploads/$clean';
    }

    // Si la config base inclut déjà "/uploads", on évite "double uploads".
    if (baseHasUploads && clean.startsWith('uploads/')) {
      clean = clean.substring('uploads/'.length);
    }

    return '$base/$clean';
  }

  static Map<String, dynamic> _normalizeHelpRequestJson(
    Map<String, dynamic> json,
  ) {
    final m = Map<String, dynamic>.from(json);
    if (m['id'] == null && m['_id'] != null) {
      m['id'] = m['_id'].toString();
    }
    return m;
  }

  static Map<String, dynamic> _normalizePostJson(Map<String, dynamic> json) {
    final m = Map<String, dynamic>.from(json);
    if (m['id'] == null && m['_id'] != null) {
      m['id'] = m['_id'].toString();
    }
    return m;
  }

  // ========== POSTS ==========

  /// IA: pré-remplir un plan d'action communauté (post ou demande d'aide).
  Future<CommunityActionPlanResult> getCommunityActionPlan({
    required String text,
    String? contextHint,
    String? inputModeHint,
    bool? isForAnotherPersonHint,
  }) async {
    final response = await _api.dio.post(
      Endpoints.communityAiActionPlan,
      data: {
        'text': text,
        if (contextHint != null && contextHint.trim().isNotEmpty)
          'contextHint': contextHint.trim(),
        if (inputModeHint != null && inputModeHint.trim().isNotEmpty)
          'inputModeHint': inputModeHint.trim(),
        ...?isForAnotherPersonHint == null
            ? null
            : {'isForAnotherPersonHint': isForAnotherPersonHint},
      },
    );
    return CommunityActionPlanResult.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// Crée un nouveau post (multipart : champs hérités + inclusifs optionnels).
  Future<PostModel> createPost(CreatePostInput input) async {
    final formData = FormData();
    formData.fields.add(MapEntry('contenu', input.contenu));
    formData.fields.add(MapEntry('type', input.type));
    if (input.latitude != null) {
      formData.fields.add(MapEntry('latitude', '${input.latitude}'));
    }
    if (input.longitude != null) {
      formData.fields.add(MapEntry('longitude', '${input.longitude}'));
    }
    if (input.dangerLevel != null && input.dangerLevel!.isNotEmpty) {
      formData.fields.add(MapEntry('dangerLevel', input.dangerLevel!));
    }

    void putIfNonNull(String key, Object? v) {
      if (v == null) return;
      if (v is bool) {
        formData.fields.add(MapEntry(key, v ? 'true' : 'false'));
      } else {
        formData.fields.add(MapEntry(key, '$v'));
      }
    }

    putIfNonNull('postNature', input.postNature);
    putIfNonNull('targetAudience', input.targetAudience);
    putIfNonNull('inputMode', input.inputMode);
    putIfNonNull('isForAnotherPerson', input.isForAnotherPerson);
    putIfNonNull('needsAudioGuidance', input.needsAudioGuidance);
    putIfNonNull('needsVisualSupport', input.needsVisualSupport);
    putIfNonNull('needsPhysicalAssistance', input.needsPhysicalAssistance);
    putIfNonNull('needsSimpleLanguage', input.needsSimpleLanguage);
    putIfNonNull('locationSharingMode', input.locationSharingMode);

    final images = input.images;
    if (images != null) {
      for (final x in images) {
        if (kIsWeb) {
          final bytes = await x.readAsBytes();
          final name = x.name.isNotEmpty ? x.name : 'image.jpg';
          formData.files.add(
            MapEntry(
              'images',
              MultipartFile.fromBytes(bytes, filename: name),
            ),
          );
        } else {
          formData.files.add(
            MapEntry(
              'images',
              await MultipartFile.fromFile(
                x.path,
                filename: x.name.isNotEmpty ? x.name : null,
              ),
            ),
          );
        }
      }
    }

    final response = await _api.dio.post(
      Endpoints.communityPosts,
      data: formData,
    );
    return PostModel.fromJson(
      _normalizePostJson(response.data as Map<String, dynamic>),
    );
  }

  /// Vote communautaire : obstacle toujours présent (`confirm: true`) ou non.
  Future<void> validatePostObstacle({
    required String postId,
    required bool confirm,
  }) async {
    await _api.dio.post(
      Endpoints.communityPostValidateObstacle(postId),
      data: {'confirm': confirm},
    );
  }

  /// Récupère la liste des posts (avec pagination, filtre optionnel `type`).
  Future<({List<PostModel> posts, int total, int page, int totalPages})> getPosts({
    int page = 1,
    int limit = 20,
    String? type,
  }) async {
    final response = await _api.dio.get(
      Endpoints.communityPosts,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (type != null && type.isNotEmpty) 'type': type,
      },
    );
    final data = response.data as Map<String, dynamic>;
    final postsList = data['data'] as List;
    final posts = postsList
        .map((json) => PostModel.fromJson(
              _normalizePostJson(json as Map<String, dynamic>),
            ))
        .toList();
    return (
      posts: posts,
      total: data['total'] as int? ?? 0,
      page: data['page'] as int? ?? page,
      totalPages: data['totalPages'] as int? ?? 1,
    );
  }

  /// Liste filtrée selon le profil (HANDICAPE + typeHandicap) — smart filter backend.
  Future<
      ({
        List<PostModel> posts,
        int total,
        int page,
        int totalPages,
        List<String> matchedTypes,
      })> getPostsForMe({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _api.dio.get(
      Endpoints.communityPostsForMe,
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );
    final data = response.data as Map<String, dynamic>;
    final postsList = data['data'] as List;
    final posts = postsList
        .map((json) => PostModel.fromJson(
              _normalizePostJson(json as Map<String, dynamic>),
            ))
        .toList();
    final rawTypes = data['matchedTypes'];
    final matchedTypes = rawTypes is List
        ? rawTypes.map((e) => e.toString()).toList()
        : <String>[];
    return (
      posts: posts,
      total: data['total'] as int? ?? 0,
      page: data['page'] as int? ?? page,
      totalPages: data['totalPages'] as int? ?? 1,
      matchedTypes: matchedTypes,
    );
  }

  /// Récupère un post par son ID.
  Future<PostModel> getPostById(String id) async {
    final response = await _api.dio.get(Endpoints.communityPostById(id));
    return PostModel.fromJson(
      _normalizePostJson(response.data as Map<String, dynamic>),
    );
  }

  // ========== COMMENTS ==========

  /// Ajoute un commentaire à un post.
  Future<CommentModel> createComment({
    required String postId,
    required String contenu,
  }) async {
    final response = await _api.dio.post(
      Endpoints.communityPostComments(postId),
      data: {'contenu': contenu},
    );
    return CommentModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Récupère les commentaires d'un post.
  Future<List<CommentModel>> getPostComments(String postId) async {
    final response = await _api.dio.get(Endpoints.communityPostComments(postId));
    final list = response.data as List;
    return list
        .map((json) => CommentModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Récupère le résumé flash (accessibilité) des commentaires d'un post.
  Future<FlashSummaryModel> getPostCommentsFlashSummary(String postId) async {
    final response = await _api.dio.get(
      Endpoints.communityPostCommentsFlashSummary(postId),
    );
    return FlashSummaryModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ========== HELP REQUESTS ==========

  /// Crée une nouvelle demande d'aide (champs inclusifs optionnels, alignés backend).
  Future<HelpRequestModel> createHelpRequest(CreateHelpRequestInput input) async {
    final data = <String, dynamic>{
      'latitude': input.latitude,
      'longitude': input.longitude,
    };
    final d = input.description?.trim();
    if (d != null && d.isNotEmpty) {
      data['description'] = d;
    }
    void putIfNonNull(String key, Object? v) {
      if (v != null) data[key] = v;
    }

    putIfNonNull('helpType', input.helpType);
    putIfNonNull('inputMode', input.inputMode);
    putIfNonNull('requesterProfile', input.requesterProfile);
    putIfNonNull('needsAudioGuidance', input.needsAudioGuidance);
    putIfNonNull('needsVisualSupport', input.needsVisualSupport);
    putIfNonNull('needsPhysicalAssistance', input.needsPhysicalAssistance);
    putIfNonNull('needsSimpleLanguage', input.needsSimpleLanguage);
    putIfNonNull('isForAnotherPerson', input.isForAnotherPerson);
    putIfNonNull('presetMessageKey', input.presetMessageKey);

    final response = await _api.dio.post(
      Endpoints.communityHelpRequests,
      data: data,
    );
    return HelpRequestModel.fromJson(
      _normalizeHelpRequestJson(response.data as Map<String, dynamic>),
    );
  }

  /// Récupère la liste des demandes d'aide (avec pagination).
  Future<({
    List<HelpRequestModel> requests,
    int total,
    int page,
    int totalPages,
  })> getHelpRequests({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _api.dio.get(
      Endpoints.communityHelpRequests,
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );
    final data = response.data as Map<String, dynamic>;
    final requestsList = data['data'] as List;
    final requests = requestsList
        .map(
          (json) => HelpRequestModel.fromJson(
            _normalizeHelpRequestJson(json as Map<String, dynamic>),
          ),
        )
        .toList();
    return (
      requests: requests,
      total: data['total'] as int? ?? 0,
      page: data['page'] as int? ?? page,
      totalPages: data['totalPages'] as int? ?? 1,
    );
  }

  /// Met à jour le statut d'une demande d'aide.
  Future<HelpRequestModel> updateHelpRequestStatus({
    required String id,
    required String statut,
  }) async {
    final response = await _api.dio.post(
      Endpoints.communityHelpRequestStatut(id),
      data: {'statut': statut},
    );
    return HelpRequestModel.fromJson(
      _normalizeHelpRequestJson(response.data as Map<String, dynamic>),
    );
  }

  /// Accepte une demande d'aide (Matching).
  Future<HelpRequestModel> acceptHelpRequest({
    required String id,
  }) async {
    final response = await _api.dio.patch(
      Endpoints.communityHelpRequestAccept(id),
      data: {},
    );
    return HelpRequestModel.fromJson(
      _normalizeHelpRequestJson(response.data as Map<String, dynamic>),
    );
  }

  // ========== MERCI / MODÉRATION ==========

  /// État « Merci » pour l’utilisateur connecté.
  Future<({bool thankReceivedFromMe, int merciCount})> getPostMerciState(
    String postId,
  ) async {
    final response = await _api.dio.get(
      Endpoints.communityPostMerciState(postId),
    );
    final data = response.data as Map<String, dynamic>;
    return (
      thankReceivedFromMe: data['thankReceivedFromMe'] as bool? ?? false,
      merciCount: (data['merciCount'] as num?)?.toInt() ?? 0,
    );
  }

  /// Toggle « Merci » (remerciement communautaire).
  Future<
      ({
        bool thankReceivedFromMe,
        int merciCount,
        PostModel post,
      })> togglePostMerci(String postId) async {
    final response = await _api.dio.post(Endpoints.communityPostMerci(postId));
    final data = response.data as Map<String, dynamic>;
    final rawPost = data['post'];
    final postMap = rawPost is Map<String, dynamic>
        ? rawPost
        : <String, dynamic>{};
    return (
      thankReceivedFromMe: data['thankReceivedFromMe'] as bool? ?? false,
      merciCount: (data['merciCount'] as num?)?.toInt() ?? 0,
      post: PostModel.fromJson(_normalizePostJson(postMap)),
    );
  }

  /// Supprime un post (auteur du post ou admin).
  Future<void> deletePost(String postId) async {
    await _api.dio.delete(Endpoints.communityPostById(postId));
  }

  /// Compat legacy: conservé pour appels existants.
  Future<void> deletePostAdmin(String postId) => deletePost(postId);

  /// Supprime un commentaire d'un post (auteur commentaire, auteur post, admin).
  Future<void> deleteComment({
    required String postId,
    required String commentId,
  }) async {
    await _api.dio.delete(Endpoints.communityPostCommentById(postId, commentId));
  }
}

