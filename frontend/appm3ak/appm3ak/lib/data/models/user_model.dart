import 'package:equatable/equatable.dart';

/// Rôles utilisateur (nouvelle API).
enum UserRole {
  handicape,
  accompagnant,
  admin;

  static UserRole? fromString(String? value) {
    if (value == null) return null;
    final v = value.toUpperCase();
    for (final r in UserRole.values) {
      if (r.toApiString() == v) return r;
    }
    return null;
  }

  String toApiString() => name.toUpperCase();
}

/// Langue préférée (ar, fr, etc.).
enum PreferredLanguage {
  ar,
  fr;

  static PreferredLanguage? fromString(String? value) {
    if (value == null) return null;
    if (value.toLowerCase() == 'ar') return PreferredLanguage.ar;
    if (value.toLowerCase() == 'fr') return PreferredLanguage.fr;
    return null;
  }
}

/// Modèle User aligné sur la nouvelle API Ma3ak.
class UserModel extends Equatable {
  const UserModel({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.role,
    this.telephone,
    this.typeHandicap,
    this.besoinSpecifique,
    this.animalAssistance = false,
    this.typeAccompagnant,
    this.specialisation,
    this.disponible = false,
    this.noteMoyenne = 0.0,
    this.trustPoints = 0,
    this.langue = 'fr',
    this.photoProfil,
    this.statut = 'ACTIF',
    this.partenaire = false,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      nom: json['nom'] as String? ?? '',
      prenom: json['prenom'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: UserRole.fromString(json['role']?.toString()) ?? UserRole.handicape,
      telephone: json['telephone'] as String?,
      typeHandicap: json['typeHandicap'] as String?,
      besoinSpecifique: json['besoinSpecifique'] as String?,
      animalAssistance: json['animalAssistance'] as bool? ?? false,
      typeAccompagnant: json['typeAccompagnant'] as String?,
      specialisation: json['specialisation'] as String?,
      disponible: json['disponible'] as bool? ?? false,
      noteMoyenne: (json['noteMoyenne'] as num?)?.toDouble() ?? 0.0,
      trustPoints: (json['trustPoints'] as num?)?.toInt() ?? 0,
      langue: json['langue'] as String? ?? 'fr',
      photoProfil: json['photoProfil'] as String?,
      statut: json['statut'] as String? ?? 'ACTIF',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  final String id;
  final String nom;
  final String prenom;
  final String email;
  final UserRole role;
  final String? telephone;
  final String? typeHandicap;
  final String? besoinSpecifique;
  final bool animalAssistance;
  final String? typeAccompagnant;
  final String? specialisation;
  final bool disponible;
  final double noteMoyenne;
  /// Points de confiance (aide communauté).
  final int trustPoints;
  final String langue;
  final String? photoProfil;
  final String statut;
  /// Compte institutionnel / commerçant labellisé (badge Partenaire).
  final bool partenaire;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Nom complet pour l'affichage.
  String get displayName => '$prenom $nom'.trim();
  /// Contact affiché (téléphone ou email).
  String get contact => telephone ?? email;

  /// Langue préférée pour l'UI (ar/fr).
  PreferredLanguage? get preferredLanguage => PreferredLanguage.fromString(langue);

  Map<String, dynamic> toJson() => {
        'id': id,
        'nom': nom,
        'prenom': prenom,
        'email': email,
        'role': role.toApiString(),
        'telephone': telephone,
        'typeHandicap': typeHandicap,
        'besoinSpecifique': besoinSpecifique,
        'animalAssistance': animalAssistance,
        'typeAccompagnant': typeAccompagnant,
        'specialisation': specialisation,
        'disponible': disponible,
        'noteMoyenne': noteMoyenne,
        'trustPoints': trustPoints,
        'langue': langue,
        'photoProfil': photoProfil,
        'statut': statut,
        'partenaire': partenaire,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  UserModel copyWith({
    String? id,
    String? nom,
    String? prenom,
    String? email,
    UserRole? role,
    String? telephone,
    String? typeHandicap,
    String? besoinSpecifique,
    bool? animalAssistance,
    String? typeAccompagnant,
    String? specialisation,
    bool? disponible,
    double? noteMoyenne,
    int? trustPoints,
    String? langue,
    String? photoProfil,
    String? statut,
    bool? partenaire,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      UserModel(
        id: id ?? this.id,
        nom: nom ?? this.nom,
        prenom: prenom ?? this.prenom,
        email: email ?? this.email,
        role: role ?? this.role,
        telephone: telephone ?? this.telephone,
        typeHandicap: typeHandicap ?? this.typeHandicap,
        besoinSpecifique: besoinSpecifique ?? this.besoinSpecifique,
        animalAssistance: animalAssistance ?? this.animalAssistance,
        typeAccompagnant: typeAccompagnant ?? this.typeAccompagnant,
        specialisation: specialisation ?? this.specialisation,
        disponible: disponible ?? this.disponible,
        noteMoyenne: noteMoyenne ?? this.noteMoyenne,
        trustPoints: trustPoints ?? this.trustPoints,
        langue: langue ?? this.langue,
        photoProfil: photoProfil ?? this.photoProfil,
        statut: statut ?? this.statut,
        partenaire: partenaire ?? this.partenaire,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  bool get isBeneficiary => role == UserRole.handicape;
  bool get isCompanion => role == UserRole.accompagnant;
  bool get isAdmin => role == UserRole.admin;

  @override
  List<Object?> get props =>
      [id, nom, prenom, email, role, telephone, photoProfil, langue, trustPoints, partenaire];
}
