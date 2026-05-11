import 'package:equatable/equatable.dart';

import 'user_model.dart';

/// Type de demande de transport.
enum TransportType {
  urgence,
  quotidien;

  static TransportType? fromString(String? value) {
    if (value == null) return null;
    final v = value.toUpperCase();
    if (v == 'URGENCE') return TransportType.urgence;
    if (v == 'QUOTIDIEN') return TransportType.quotidien;
    return null;
  }

  String toApiString() => name.toUpperCase();
}

/// Demande de transport.
class TransportModel extends Equatable {
  const TransportModel({
    required this.id,
    required this.typeTransport,
    this.depart,
    this.destination,
    this.latitudeDepart,
    this.longitudeDepart,
    this.latitudeArrivee,
    this.longitudeArrivee,
    this.dateHeure,
    this.statut,
    this.demandeur,
    this.accompagnant,
    this.createdAt,
  });

  factory TransportModel.fromJson(Map<String, dynamic> json) {
    return TransportModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      typeTransport: TransportType.fromString(json['typeTransport']?.toString()) ?? TransportType.quotidien,
      depart: json['depart'] as String?,
      destination: json['destination'] as String?,
      latitudeDepart: (json['latitudeDepart'] as num?)?.toDouble(),
      longitudeDepart: (json['longitudeDepart'] as num?)?.toDouble(),
      latitudeArrivee: (json['latitudeArrivee'] as num?)?.toDouble(),
      longitudeArrivee: (json['longitudeArrivee'] as num?)?.toDouble(),
      dateHeure: json['dateHeure'] != null
          ? DateTime.tryParse(json['dateHeure'].toString())
          : null,
      statut: json['statut'] as String?,
      demandeur: json['demandeur'] != null
          ? UserModel.fromJson(json['demandeur'] as Map<String, dynamic>)
          : null,
      accompagnant: json['accompagnant'] != null
          ? UserModel.fromJson(json['accompagnant'] as Map<String, dynamic>)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  final String id;
  final TransportType typeTransport;
  final String? depart;
  final String? destination;
  final double? latitudeDepart;
  final double? longitudeDepart;
  final double? latitudeArrivee;
  final double? longitudeArrivee;
  final DateTime? dateHeure;
  final String? statut;
  final UserModel? demandeur;
  final UserModel? accompagnant;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [id];
}
