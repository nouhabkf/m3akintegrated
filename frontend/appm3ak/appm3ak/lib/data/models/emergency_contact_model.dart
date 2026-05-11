import 'package:equatable/equatable.dart';

import 'user_model.dart';

/// Contact d'urgence (accompagnant lié avec ordre de priorité).
class EmergencyContactModel extends Equatable {
  const EmergencyContactModel({
    required this.id,
    required this.accompagnantId,
    required this.ordrePriorite,
    this.accompagnant,
  });

  factory EmergencyContactModel.fromJson(Map<String, dynamic> json) {
    return EmergencyContactModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      accompagnantId: json['accompagnantId'] as String? ?? '',
      ordrePriorite: (json['ordrePriorite'] as num?)?.toInt() ?? 0,
      accompagnant: json['accompagnant'] != null
          ? UserModel.fromJson(json['accompagnant'] as Map<String, dynamic>)
          : null,
    );
  }

  final String id;
  final String accompagnantId;
  final int ordrePriorite;
  final UserModel? accompagnant;

  @override
  List<Object?> get props => [id, accompagnantId, ordrePriorite];
}
