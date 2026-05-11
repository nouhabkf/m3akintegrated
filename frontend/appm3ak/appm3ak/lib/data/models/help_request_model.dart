import 'package:equatable/equatable.dart';

import 'user_model.dart';

/// Statut d'une demande d'aide.
enum HelpRequestStatus {
  enAttente,
  enCours,
  terminee,
  annulee;

  String get displayName {
    switch (this) {
      case HelpRequestStatus.enAttente:
        return 'En attente';
      case HelpRequestStatus.enCours:
        return 'En cours';
      case HelpRequestStatus.terminee:
        return 'Terminée';
      case HelpRequestStatus.annulee:
        return 'Annulée';
    }
  }

  static HelpRequestStatus? fromString(String? value) {
    if (value == null) return null;
    final v = value.toUpperCase();
    for (final status in HelpRequestStatus.values) {
      if (status.toApiString() == v) return status;
    }
    return null;
  }

  String toApiString() {
    switch (this) {
      case HelpRequestStatus.enAttente:
        return 'EN_ATTENTE';
      case HelpRequestStatus.enCours:
        return 'EN_COURS';
      case HelpRequestStatus.terminee:
        return 'TERMINEE';
      case HelpRequestStatus.annulee:
        return 'ANNULEE';
    }
  }
}

bool? _parseBool(dynamic v) {
  if (v == null) return null;
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    final s = v.toLowerCase().trim();
    if (s == 'true' || s == '1' || s == 'yes') return true;
    if (s == 'false' || s == '0' || s == 'no') return false;
  }
  return null;
}

List<String>? _parseStringList(dynamic v) {
  if (v == null) return null;
  if (v is List) {
    return v.map((e) => e.toString()).toList();
  }
  return null;
}

/// Modèle représentant une demande d'aide.
class HelpRequestModel extends Equatable {
  const HelpRequestModel({
    required this.id,
    required this.userId,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.statut = HelpRequestStatus.enAttente,
    this.urgencyScore,
    this.priority,
    this.priorityScore,
    this.priorityReason,
    this.prioritySignals,
    this.helpType,
    this.inputMode,
    this.requesterProfile,
    this.needsAudioGuidance,
    this.needsVisualSupport,
    this.needsPhysicalAssistance,
    this.needsSimpleLanguage,
    this.isForAnotherPerson,
    this.presetMessageKey,
    this.acceptedBy,
    this.helperName,
    this.user,
    this.createdAt,
    this.updatedAt,
  });

  factory HelpRequestModel.fromJson(Map<String, dynamic> json) {
    // Gérer le cas où userId est un objet (populated) ou un string
    String userIdStr;
    UserModel? user;
    
    if (json['userId'] is Map) {
      user = UserModel.fromJson(json['userId'] as Map<String, dynamic>);
      userIdStr = user.id;
    } else {
      userIdStr = json['userId']?.toString() ?? json['userId']?['_id']?.toString() ?? '';
    }

    return HelpRequestModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      userId: userIdStr,
      description: json['description']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      statut: HelpRequestStatus.fromString(json['statut']?.toString()) ??
          HelpRequestStatus.enAttente,
      urgencyScore: (json['urgencyScore'] as num?)?.toInt(),
      priority: json['priority']?.toString(),
      priorityScore: (json['priorityScore'] as num?)?.toDouble(),
      priorityReason: json['priorityReason']?.toString(),
      prioritySignals: _parseStringList(json['prioritySignals']),
      helpType: json['helpType']?.toString(),
      inputMode: json['inputMode']?.toString(),
      requesterProfile: json['requesterProfile']?.toString(),
      needsAudioGuidance: _parseBool(json['needsAudioGuidance']),
      needsVisualSupport: _parseBool(json['needsVisualSupport']),
      needsPhysicalAssistance: _parseBool(json['needsPhysicalAssistance']),
      needsSimpleLanguage: _parseBool(json['needsSimpleLanguage']),
      isForAnotherPerson: _parseBool(json['isForAnotherPerson']),
      presetMessageKey: json['presetMessageKey']?.toString(),
      acceptedBy: (json['acceptedBy'] as String?) ??
          json['acceptedBy']?['_id']?.toString(),
      helperName: json['helperName'] as String?,
      user: user,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  final String id;
  final String userId;
  final String description;
  final double latitude;
  final double longitude;
  final HelpRequestStatus statut;
  final int? urgencyScore;
  /// low | medium | high | critical (calculé côté serveur).
  final String? priority;
  final double? priorityScore;
  final String? priorityReason;
  final List<String>? prioritySignals;
  final String? helpType;
  final String? inputMode;
  final String? requesterProfile;
  final bool? needsAudioGuidance;
  final bool? needsVisualSupport;
  final bool? needsPhysicalAssistance;
  final bool? needsSimpleLanguage;
  final bool? isForAnotherPerson;
  final String? presetMessageKey;
  final String? acceptedBy;
  final String? helperName;
  final UserModel? user; // Utilisateur qui a créé la demande (si populated)
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Vérifie si la demande est ouverte (peut être acceptée).
  bool get isOpen => statut == HelpRequestStatus.enAttente;

  /// Demande pour une tierce personne ou profil accompagnant (affichage liste/détail).
  bool get isCaregiverRequest =>
      isForAnotherPerson == true ||
      (requesterProfile?.toLowerCase().trim() == 'caregiver');

  /// Nom de l'utilisateur (si disponible).
  String get userName => user?.displayName ?? 'Utilisateur';

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'statut': statut.toApiString(),
        'urgencyScore': urgencyScore,
        'priority': priority,
        'priorityScore': priorityScore,
        'priorityReason': priorityReason,
        'prioritySignals': prioritySignals,
        'helpType': helpType,
        'inputMode': inputMode,
        'requesterProfile': requesterProfile,
        'needsAudioGuidance': needsAudioGuidance,
        'needsVisualSupport': needsVisualSupport,
        'needsPhysicalAssistance': needsPhysicalAssistance,
        'needsSimpleLanguage': needsSimpleLanguage,
        'isForAnotherPerson': isForAnotherPerson,
        'presetMessageKey': presetMessageKey,
        'acceptedBy': acceptedBy,
        'helperName': helperName,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  HelpRequestModel copyWith({
    String? id,
    String? userId,
    String? description,
    double? latitude,
    double? longitude,
    HelpRequestStatus? statut,
    int? urgencyScore,
    String? priority,
    double? priorityScore,
    String? priorityReason,
    List<String>? prioritySignals,
    String? helpType,
    String? inputMode,
    String? requesterProfile,
    bool? needsAudioGuidance,
    bool? needsVisualSupport,
    bool? needsPhysicalAssistance,
    bool? needsSimpleLanguage,
    bool? isForAnotherPerson,
    String? presetMessageKey,
    String? acceptedBy,
    String? helperName,
    UserModel? user,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      HelpRequestModel(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        description: description ?? this.description,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        statut: statut ?? this.statut,
        urgencyScore: urgencyScore ?? this.urgencyScore,
        priority: priority ?? this.priority,
        priorityScore: priorityScore ?? this.priorityScore,
        priorityReason: priorityReason ?? this.priorityReason,
        prioritySignals: prioritySignals ?? this.prioritySignals,
        helpType: helpType ?? this.helpType,
        inputMode: inputMode ?? this.inputMode,
        requesterProfile: requesterProfile ?? this.requesterProfile,
        needsAudioGuidance: needsAudioGuidance ?? this.needsAudioGuidance,
        needsVisualSupport: needsVisualSupport ?? this.needsVisualSupport,
        needsPhysicalAssistance:
            needsPhysicalAssistance ?? this.needsPhysicalAssistance,
        needsSimpleLanguage: needsSimpleLanguage ?? this.needsSimpleLanguage,
        isForAnotherPerson: isForAnotherPerson ?? this.isForAnotherPerson,
        presetMessageKey: presetMessageKey ?? this.presetMessageKey,
        acceptedBy: acceptedBy ?? this.acceptedBy,
        helperName: helperName ?? this.helperName,
        user: user ?? this.user,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  List<Object?> get props => [
        id,
        userId,
        description,
        latitude,
        longitude,
        statut,
        urgencyScore,
        priority,
        priorityScore,
        priorityReason,
        prioritySignals,
        helpType,
        inputMode,
        requesterProfile,
        needsAudioGuidance,
        needsVisualSupport,
        needsPhysicalAssistance,
        needsSimpleLanguage,
        isForAnotherPerson,
        presetMessageKey,
        acceptedBy,
        helperName,
        user,
        createdAt,
        updatedAt,
      ];
}

