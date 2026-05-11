import 'package:equatable/equatable.dart';

import 'user_model.dart';

bool? _parseBool(dynamic v) {
  if (v == null) return null;
  if (v is bool) return v;
  if (v is num) return v != 0;
  final s = v.toString().toLowerCase().trim();
  if (s == 'true' || s == '1') return true;
  if (s == 'false' || s == '0') return false;
  return null;
}

/// Type de post dans la communauté.
enum PostType {
  general,
  handicapMoteur,
  handicapVisuel,
  handicapAuditif,
  handicapCognitif,
  conseil,
  temoignage,
  autre;

  String get displayName {
    switch (this) {
      case PostType.general:
        return 'Général';
      case PostType.handicapMoteur:
        return 'Handicap moteur';
      case PostType.handicapVisuel:
        return 'Handicap visuel';
      case PostType.handicapAuditif:
        return 'Handicap auditif';
      case PostType.handicapCognitif:
        return 'Handicap cognitif';
      case PostType.conseil:
        return 'Conseil';
      case PostType.temoignage:
        return 'Témoignage';
      case PostType.autre:
        return 'Autre';
    }
  }

  static PostType? fromString(String? value) {
    if (value == null) return null;
    // Le backend peut renvoyer des valeurs en camelCase (ex: handicapMoteur).
    // On compare donc sans sensibilité à la casse.
    final v = value.toLowerCase();
    for (final type in PostType.values) {
      if (type.toApiString().toLowerCase() == v) return type;
    }
    return null;
  }

  String toApiString() => name;
}

enum CommunityPostStreamType {
  post,
  live,
  replay;

  static CommunityPostStreamType fromString(String? value) {
    final v = value?.toLowerCase().trim();
    switch (v) {
      case 'live':
        return CommunityPostStreamType.live;
      case 'replay':
        return CommunityPostStreamType.replay;
      default:
        return CommunityPostStreamType.post;
    }
  }

  String toApiString() => name;
}

enum LiveStatus {
  active,
  ended;

  static LiveStatus fromString(String? value) {
    return value?.toLowerCase().trim() == 'active'
        ? LiveStatus.active
        : LiveStatus.ended;
  }

  String toApiString() => name;
}

/// Modèle représentant un post de la communauté.
class PostModel extends Equatable {
  const PostModel({
    required this.id,
    required this.userId,
    required this.contenu,
    required this.type,
    this.user,
    this.commentsCount,
    this.images,
    this.createdAt,
    this.updatedAt,
    this.merciCount = 0,
    this.hasPlace = false,
    this.obstaclePresent = false,
    this.validationYes = 0,
    this.validationNo = 0,
    this.postNature,
    this.targetAudience,
    this.inputMode,
    this.isForAnotherPerson,
    this.needsAudioGuidance,
    this.needsVisualSupport,
    this.needsPhysicalAssistance,
    this.needsSimpleLanguage,
    this.locationSharingMode,
    this.streamType = CommunityPostStreamType.post,
    this.isLive = false,
    this.liveStatus = LiveStatus.ended,
    this.viewersCount = 0,
    this.liveVideoUrl,
    this.dangerLevel,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    // Gérer le cas où userId est un objet (populated) ou un string
    String userIdStr;
    UserModel? user;
    
    if (json['userId'] is Map) {
      user = UserModel.fromJson(json['userId'] as Map<String, dynamic>);
      userIdStr = user.id;
    } else {
      userIdStr = json['userId']?.toString() ?? json['userId']?['_id']?.toString() ?? '';
    }

    List<String>? images;
    final rawImages = json['images'];
    if (rawImages is List) {
      images = rawImages.map((e) => e.toString()).toList();
    }

    return PostModel(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      userId: userIdStr,
      contenu: json['contenu'] as String? ?? '',
      type: PostType.fromString(json['type']?.toString()) ?? PostType.general,
      user: user,
      commentsCount: json['commentsCount'] as int?,
      images: images,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      merciCount: (json['merciCount'] as num?)?.toInt() ?? 0,
      hasPlace: json['hasPlace'] as bool? ?? false,
      obstaclePresent: json['obstaclePresent'] as bool? ?? false,
      validationYes: (json['validationYes'] as num?)?.toInt() ?? 0,
      validationNo: (json['validationNo'] as num?)?.toInt() ?? 0,
      postNature: json['postNature']?.toString(),
      targetAudience: json['targetAudience']?.toString(),
      inputMode: json['inputMode']?.toString(),
      isForAnotherPerson: _parseBool(json['isForAnotherPerson']),
      needsAudioGuidance: _parseBool(json['needsAudioGuidance']),
      needsVisualSupport: _parseBool(json['needsVisualSupport']),
      needsPhysicalAssistance: _parseBool(json['needsPhysicalAssistance']),
      needsSimpleLanguage: _parseBool(json['needsSimpleLanguage']),
      locationSharingMode: json['locationSharingMode']?.toString(),
      streamType: CommunityPostStreamType.fromString(
        json['postStreamType']?.toString() ??
            json['postType']?.toString() ??
            json['postNature']?.toString() ??
            (json['type']?.toString() == 'live' ||
                    json['type']?.toString() == 'replay' ||
                    json['type']?.toString() == 'post'
                ? json['type']?.toString()
                : null),
      ),
      isLive: _parseBool(json['isLive']) ??
          (CommunityPostStreamType.fromString(
                json['postStreamType']?.toString() ?? json['postType']?.toString(),
              ) ==
              CommunityPostStreamType.live),
      liveStatus: LiveStatus.fromString(json['liveStatus']?.toString()),
      viewersCount: (json['viewersCount'] as num?)?.toInt() ?? 0,
      liveVideoUrl: json['liveVideoUrl']?.toString(),
      dangerLevel: json['dangerLevel']?.toString(),
    );
  }

  final String id;
  final String userId;
  final String contenu;
  final PostType type;
  final UserModel? user; // Utilisateur qui a créé le post (si populated)
  final int? commentsCount; // Nombre de commentaires (si calculé)
  final List<String>? images;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  /// Nombre de « Merci » (remerciements).
  final int merciCount;
  final bool hasPlace;
  final bool obstaclePresent;
  final int validationYes;
  final int validationNo;

  final String? postNature;
  final String? targetAudience;
  final String? inputMode;
  final bool? isForAnotherPerson;
  final bool? needsAudioGuidance;
  final bool? needsVisualSupport;
  final bool? needsPhysicalAssistance;
  final bool? needsSimpleLanguage;
  final String? locationSharingMode;
  final CommunityPostStreamType streamType;
  final bool isLive;
  final LiveStatus liveStatus;
  final int viewersCount;
  final String? liveVideoUrl;
  /// Niveau de danger du signalement (`none`, `low`, `high`, `critical`, …).
  final String? dangerLevel;

  /// Afficher la carte de validation obstacle (lieu / obstacle signalé).
  bool get showsObstacleValidation =>
      hasPlace || obstaclePresent || (validationYes + validationNo) > 0;

  bool get isActiveLive =>
      streamType == CommunityPostStreamType.live &&
      isLive &&
      liveStatus == LiveStatus.active;

  /// Nom de l'utilisateur (si disponible).
  String get userName => user?.displayName ?? 'Utilisateur';

  /// Extrait du contenu pour l'affichage (premiers caractères).
  String get preview {
    if (contenu.length <= 100) return contenu;
    return '${contenu.substring(0, 100)}...';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'contenu': contenu,
        'type': type.toApiString(),
        'images': images,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'postNature': postNature,
        'targetAudience': targetAudience,
        'inputMode': inputMode,
        'isForAnotherPerson': isForAnotherPerson,
        'needsAudioGuidance': needsAudioGuidance,
        'needsVisualSupport': needsVisualSupport,
        'needsPhysicalAssistance': needsPhysicalAssistance,
        'needsSimpleLanguage': needsSimpleLanguage,
        'locationSharingMode': locationSharingMode,
        'postStreamType': streamType.toApiString(),
        'isLive': isLive,
        'liveStatus': liveStatus.toApiString(),
        'viewersCount': viewersCount,
        'liveVideoUrl': liveVideoUrl,
        'dangerLevel': dangerLevel,
      };

  PostModel copyWith({
    String? id,
    String? userId,
    String? contenu,
    PostType? type,
    UserModel? user,
    int? commentsCount,
    List<String>? images,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? merciCount,
    bool? hasPlace,
    bool? obstaclePresent,
    int? validationYes,
    int? validationNo,
    String? postNature,
    String? targetAudience,
    String? inputMode,
    bool? isForAnotherPerson,
    bool? needsAudioGuidance,
    bool? needsVisualSupport,
    bool? needsPhysicalAssistance,
    bool? needsSimpleLanguage,
    String? locationSharingMode,
    CommunityPostStreamType? streamType,
    bool? isLive,
    LiveStatus? liveStatus,
    int? viewersCount,
    String? liveVideoUrl,
    String? dangerLevel,
  }) =>
      PostModel(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        contenu: contenu ?? this.contenu,
        type: type ?? this.type,
        user: user ?? this.user,
        commentsCount: commentsCount ?? this.commentsCount,
        images: images ?? this.images,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        merciCount: merciCount ?? this.merciCount,
        hasPlace: hasPlace ?? this.hasPlace,
        obstaclePresent: obstaclePresent ?? this.obstaclePresent,
        validationYes: validationYes ?? this.validationYes,
        validationNo: validationNo ?? this.validationNo,
        postNature: postNature ?? this.postNature,
        targetAudience: targetAudience ?? this.targetAudience,
        inputMode: inputMode ?? this.inputMode,
        isForAnotherPerson: isForAnotherPerson ?? this.isForAnotherPerson,
        needsAudioGuidance: needsAudioGuidance ?? this.needsAudioGuidance,
        needsVisualSupport: needsVisualSupport ?? this.needsVisualSupport,
        needsPhysicalAssistance:
            needsPhysicalAssistance ?? this.needsPhysicalAssistance,
        needsSimpleLanguage: needsSimpleLanguage ?? this.needsSimpleLanguage,
        locationSharingMode: locationSharingMode ?? this.locationSharingMode,
        streamType: streamType ?? this.streamType,
        isLive: isLive ?? this.isLive,
        liveStatus: liveStatus ?? this.liveStatus,
        viewersCount: viewersCount ?? this.viewersCount,
        liveVideoUrl: liveVideoUrl ?? this.liveVideoUrl,
        dangerLevel: dangerLevel ?? this.dangerLevel,
      );

  @override
  List<Object?> get props => [
        id,
        userId,
        contenu,
        type,
        images,
        merciCount,
        validationYes,
        validationNo,
        postNature,
        targetAudience,
        inputMode,
        isForAnotherPerson,
        needsAudioGuidance,
        needsVisualSupport,
        needsPhysicalAssistance,
        needsSimpleLanguage,
        locationSharingMode,
        streamType,
        isLive,
        liveStatus,
        viewersCount,
        liveVideoUrl,
        dangerLevel,
      ];
}

