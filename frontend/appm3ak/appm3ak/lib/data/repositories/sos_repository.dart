import '../api/api_client.dart';
import '../api/endpoints.dart';
import '../models/sos_alert_model.dart';

class SosRepository {
  SosRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  /// Créer une alerte SOS.
  Future<SosAlertModel> create({required double latitude, required double longitude}) async {
    final response = await _api.dio.post(
      Endpoints.sosAlerts,
      data: {'latitude': latitude, 'longitude': longitude},
    );
    return SosAlertModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Mes alertes SOS.
  Future<List<SosAlertModel>> getMyAlerts() async {
    final response = await _api.dio.get(Endpoints.sosAlertsMe);
    final list = response.data as List<dynamic>? ?? [];
    return list
        .map((e) => SosAlertModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Alertes à proximité.
  Future<List<SosAlertModel>> getNearby({
    required double latitude,
    required double longitude,
  }) async {
    final response = await _api.dio.get(
      Endpoints.sosAlertsNearby(latitude, longitude),
    );
    final list = response.data as List<dynamic>? ?? [];
    return list
        .map((e) => SosAlertModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Répondre à une alerte (« M'y rendre ») — passe le statut à EN_ROUTE.
  Future<SosAlertModel> respond({required String alertId}) async {
    final response = await _api.dio.post(Endpoints.sosAlertRespond(alertId));
    return SosAlertModel.fromJson(response.data as Map<String, dynamic>);
  }
}
