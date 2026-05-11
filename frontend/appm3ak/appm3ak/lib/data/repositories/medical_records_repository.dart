import '../api/api_client.dart';
import '../api/endpoints.dart';
import '../models/medical_record_model.dart';

class MedicalRecordsRepository {
  MedicalRecordsRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  /// Mon dossier médical.
  Future<MedicalRecordModel?> getMe() async {
    try {
      final response = await _api.dio.get(Endpoints.medicalRecordsMe);
      return MedicalRecordModel.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Créer mon dossier médical.
  Future<MedicalRecordModel> create({
    String? groupeSanguin,
    String? allergies,
    String? maladiesChroniques,
    String? medicaments,
    String? medecinTraitant,
    String? contactUrgence,
  }) async {
    final body = <String, dynamic>{};
    if (groupeSanguin != null) body['groupeSanguin'] = groupeSanguin;
    if (allergies != null) body['allergies'] = allergies;
    if (maladiesChroniques != null) body['maladiesChroniques'] = maladiesChroniques;
    if (medicaments != null) body['medicaments'] = medicaments;
    if (medecinTraitant != null) body['medecinTraitant'] = medecinTraitant;
    if (contactUrgence != null) body['contactUrgence'] = contactUrgence;

    final response = await _api.dio.post(Endpoints.medicalRecords, data: body);
    return MedicalRecordModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Mettre à jour mon dossier médical.
  Future<MedicalRecordModel> updateMe({
    String? groupeSanguin,
    String? allergies,
    String? maladiesChroniques,
    String? medicaments,
    String? medecinTraitant,
    String? contactUrgence,
  }) async {
    final body = <String, dynamic>{};
    if (groupeSanguin != null) body['groupeSanguin'] = groupeSanguin;
    if (allergies != null) body['allergies'] = allergies;
    if (maladiesChroniques != null) body['maladiesChroniques'] = maladiesChroniques;
    if (medicaments != null) body['medicaments'] = medicaments;
    if (medecinTraitant != null) body['medecinTraitant'] = medecinTraitant;
    if (contactUrgence != null) body['contactUrgence'] = contactUrgence;

    final response = await _api.dio.patch(Endpoints.medicalRecordsMe, data: body);
    return MedicalRecordModel.fromJson(response.data as Map<String, dynamic>);
  }
}
