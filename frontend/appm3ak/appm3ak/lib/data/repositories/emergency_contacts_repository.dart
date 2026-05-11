import '../api/api_client.dart';
import '../api/endpoints.dart';
import '../models/emergency_contact_model.dart';

class EmergencyContactsRepository {
  EmergencyContactsRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  /// Liste des contacts d'urgence (avec accompagnant peuplé).
  Future<List<EmergencyContactModel>> getMyContacts() async {
    final response = await _api.dio.get(Endpoints.emergencyContactsMe);
    final list = response.data as List<dynamic>? ?? [];
    return list
        .map((e) => EmergencyContactModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Ajouter un contact d'urgence.
  Future<EmergencyContactModel> add({
    required String accompagnantId,
    int ordrePriorite = 0,
  }) async {
    final response = await _api.dio.post(
      Endpoints.emergencyContacts,
      data: {
        'accompagnantId': accompagnantId,
        'ordrePriorite': ordrePriorite,
      },
    );
    return EmergencyContactModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Supprimer un contact d'urgence.
  Future<void> delete(String id) async {
    await _api.dio.delete(Endpoints.emergencyContactId(id));
  }
}
