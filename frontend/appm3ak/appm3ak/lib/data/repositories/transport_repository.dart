import '../api/api_client.dart';
import '../api/endpoints.dart';
import '../models/transport_model.dart';

class TransportRepository {
  TransportRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  /// Demandes en attente (pour accompagnants).
  Future<List<TransportModel>> getAvailable() async {
    final response = await _api.dio.get(Endpoints.transportAvailable);
    final list = response.data as List<dynamic>? ?? [];
    return list
        .map((e) => TransportModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Mes demandes (asDemandeur, asAccompagnant).
  Future<Map<String, List<TransportModel>>> getMe() async {
    final response = await _api.dio.get(Endpoints.transportMe);
    final data = response.data as Map<String, dynamic>? ?? {};
    final asDemandeur = (data['asDemandeur'] as List<dynamic>? ?? [])
        .map((e) => TransportModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final asAccompagnant = (data['asAccompagnant'] as List<dynamic>? ?? [])
        .map((e) => TransportModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return {'asDemandeur': asDemandeur, 'asAccompagnant': asAccompagnant};
  }

  /// Créer une demande.
  Future<TransportModel> create({
    required String typeTransport,
    String? depart,
    String? destination,
    double? latitudeDepart,
    double? longitudeDepart,
    double? latitudeArrivee,
    double? longitudeArrivee,
    DateTime? dateHeure,
  }) async {
    final body = <String, dynamic>{
      'typeTransport': typeTransport,
      'depart': ?depart,
      'destination': ?destination,
      'latitudeDepart': ?latitudeDepart,
      'longitudeDepart': ?longitudeDepart,
      'latitudeArrivee': ?latitudeArrivee,
      'longitudeArrivee': ?longitudeArrivee,
      if (dateHeure != null) 'dateHeure': dateHeure.toIso8601String(),
    };
    final response = await _api.dio.post(Endpoints.transport, data: body);
    return TransportModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Accepter une demande (accompagnant).
  Future<void> accept(String id, {double? scoreMatching}) async {
    await _api.dio.post(
      Endpoints.transportAccept(id),
      data: scoreMatching != null ? {'scoreMatching': scoreMatching} : null,
    );
  }

  /// Annuler une demande.
  Future<void> cancel(String id) async {
    await _api.dio.post(Endpoints.transportCancel(id));
  }
}
