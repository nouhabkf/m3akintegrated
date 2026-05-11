import 'package:equatable/equatable.dart';

/// Alerte SOS.
class SosAlertModel extends Equatable {
  const SosAlertModel({
    required this.id,
    required this.latitude,
    required this.longitude,
    this.statut,
    this.createdAt,
    this.reporterSummary,
    this.responderSummary,
  });

  factory SosAlertModel.fromJson(Map<String, dynamic> json) {
    String? reporterSummary;
    final u = json['userId'];
    if (u is Map<String, dynamic>) {
      final prenom = u['prenom'] as String? ?? '';
      final nom = u['nom'] as String? ?? '';
      reporterSummary = '$prenom $nom'.trim();
      if (reporterSummary.isEmpty) {
        reporterSummary = u['email'] as String?;
      }
    }
    String? responderSummary;
    final r = json['responderUserId'];
    if (r is Map<String, dynamic>) {
      final prenom = r['prenom'] as String? ?? '';
      final nom = r['nom'] as String? ?? '';
      responderSummary = '$prenom $nom'.trim();
      if (responderSummary.isEmpty) {
        responderSummary = r['email'] as String?;
      }
    }
    return SosAlertModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      statut: json['statut'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      reporterSummary: reporterSummary,
      responderSummary: responderSummary,
    );
  }

  final String id;
  final double latitude;
  final double longitude;
  final String? statut;
  final DateTime? createdAt;
  final String? reporterSummary;
  final String? responderSummary;

  bool get isEnRoute =>
      statut == 'EN_ROUTE' || statut == 'SECOURS_PROCHES';

  @override
  List<Object?> get props =>
      [id, latitude, longitude, statut, reporterSummary, responderSummary];
}
