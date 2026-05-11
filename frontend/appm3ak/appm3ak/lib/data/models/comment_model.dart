import 'package:equatable/equatable.dart';

import 'user_model.dart';

/// Modèle représentant un commentaire sur un post.
class CommentModel extends Equatable {
  const CommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.contenu,
    this.user,
    this.createdAt,
    this.updatedAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    // Gérer le cas où userId est un objet (populated) ou un string
    String userIdStr;
    UserModel? user;
    
    if (json['userId'] is Map) {
      user = UserModel.fromJson(json['userId'] as Map<String, dynamic>);
      userIdStr = user.id;
    } else {
      userIdStr = json['userId']?.toString() ?? json['userId']?['_id']?.toString() ?? '';
    }

    return CommentModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      postId: json['postId']?.toString() ?? json['postId']?['_id']?.toString() ?? '',
      userId: userIdStr,
      contenu: json['contenu'] as String? ?? '',
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
  final String postId;
  final String userId;
  final String contenu;
  final UserModel? user; // Utilisateur qui a créé le commentaire (si populated)
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Nom de l'utilisateur (si disponible).
  String get userName => user?.displayName ?? 'Utilisateur';

  Map<String, dynamic> toJson() => {
        'id': id,
        'postId': postId,
        'userId': userId,
        'contenu': contenu,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  CommentModel copyWith({
    String? id,
    String? postId,
    String? userId,
    String? contenu,
    UserModel? user,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      CommentModel(
        id: id ?? this.id,
        postId: postId ?? this.postId,
        userId: userId ?? this.userId,
        contenu: contenu ?? this.contenu,
        user: user ?? this.user,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  List<Object?> get props => [id, postId, userId, contenu];
}

