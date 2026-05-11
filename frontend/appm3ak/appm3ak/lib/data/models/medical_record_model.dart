import 'package:equatable/equatable.dart';

/// Dossier médical (HANDICAPE).
class MedicalRecordModel extends Equatable {
  const MedicalRecordModel({
    required this.id,
    this.groupeSanguin,
    this.allergies,
    this.maladiesChroniques,
    this.medicaments,
    this.medecinTraitant,
    this.contactUrgence,
    this.createdAt,
    this.updatedAt,
  });

  factory MedicalRecordModel.fromJson(Map<String, dynamic> json) {
    return MedicalRecordModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      groupeSanguin: json['groupeSanguin'] as String?,
      allergies: json['allergies'] as String?,
      maladiesChroniques: json['maladiesChroniques'] as String?,
      medicaments: json['medicaments'] as String?,
      medecinTraitant: json['medecinTraitant'] as String?,
      contactUrgence: json['contactUrgence'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  final String id;
  final String? groupeSanguin;
  final String? allergies;
  final String? maladiesChroniques;
  final String? medicaments;
  final String? medecinTraitant;
  final String? contactUrgence;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => {
        'groupeSanguin': groupeSanguin,
        'allergies': allergies,
        'maladiesChroniques': maladiesChroniques,
        'medicaments': medicaments,
        'medecinTraitant': medecinTraitant,
        'contactUrgence': contactUrgence,
      };

  @override
  List<Object?> get props => [id];
}
