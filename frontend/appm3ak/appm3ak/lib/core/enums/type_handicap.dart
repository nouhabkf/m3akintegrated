import '../../data/models/post_model.dart';

/// Aligné sur `TypeHandicap` / strings API NestJS (`user.typeHandicap`).
enum TypeHandicap {
  visuel,
  moteur,
  auditif,
  cognitif,
  autre;

  static TypeHandicap? fromApiString(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final v = value.toLowerCase();
    if (v.contains('visuel') || v.contains('visual') || v == 'vis') {
      return TypeHandicap.visuel;
    }
    if (v.contains('moteur')) return TypeHandicap.moteur;
    if (v.contains('auditif')) return TypeHandicap.auditif;
    if (v.contains('cognitif')) return TypeHandicap.cognitif;
    return TypeHandicap.autre;
  }
}

/// Types de posts à mettre en avant pour l’UI (chips) — même logique que le backend `postTypesForHandicapProfile`.
List<PostType> postTypesMatchingProfile({
  required bool isHandicape,
  required String? typeHandicapRaw,
}) {
  if (!isHandicape) return [];
  final cross = <PostType>[
    PostType.general,
    PostType.conseil,
    PostType.temoignage,
    PostType.autre,
  ];
  final th = TypeHandicap.fromApiString(typeHandicapRaw);
  switch (th) {
    case TypeHandicap.visuel:
      return [...cross, PostType.handicapVisuel];
    case TypeHandicap.moteur:
      return [...cross, PostType.handicapMoteur];
    case TypeHandicap.auditif:
      return [...cross, PostType.handicapAuditif];
    case TypeHandicap.cognitif:
      return [...cross, PostType.handicapCognitif];
    case TypeHandicap.autre:
      return cross;
    case null:
      return cross;
  }
}

bool isVisualHandicapProfile(String? typeHandicap) {
  return TypeHandicap.fromApiString(typeHandicap) == TypeHandicap.visuel;
}
