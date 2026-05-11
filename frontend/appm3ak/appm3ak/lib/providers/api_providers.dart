import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/token_storage_service.dart';
import '../data/api/api_client.dart';
import '../data/repositories/emergency_contacts_repository.dart';
import '../data/repositories/medical_records_repository.dart';
import '../data/repositories/sos_repository.dart';
import '../data/repositories/transport_repository.dart';

final tokenStorageProvider = Provider<TokenStorageService>((ref) {
  return TokenStorageService();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  return ApiClient(getAccessToken: storage.getToken);
});

final emergencyContactsRepositoryProvider =
    Provider<EmergencyContactsRepository>((ref) {
  return EmergencyContactsRepository(apiClient: ref.watch(apiClientProvider));
});

final medicalRecordsRepositoryProvider =
    Provider<MedicalRecordsRepository>((ref) {
  return MedicalRecordsRepository(apiClient: ref.watch(apiClientProvider));
});

final sosRepositoryProvider = Provider<SosRepository>((ref) {
  return SosRepository(apiClient: ref.watch(apiClientProvider));
});

final transportRepositoryProvider = Provider<TransportRepository>((ref) {
  return TransportRepository(apiClient: ref.watch(apiClientProvider));
});
