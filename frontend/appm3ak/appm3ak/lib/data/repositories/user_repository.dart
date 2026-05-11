import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

import '../api/api_client.dart';
import '../api/endpoints.dart';
import '../models/user_model.dart';
import '../../core/config/app_config.dart';

class UserRepository {
  UserRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  /// Inscription (CreateUserDto) : nom, prenom, email, password, telephone, role + optionnels.
  Future<UserModel> register({
    required String nom,
    required String prenom,
    required String email,
    required String password,
    required String telephone,
    required String role,
    String? typeHandicap,
    String? besoinSpecifique,
    bool animalAssistance = false,
    String? typeAccompagnant,
    String? specialisation,
    String? langue,
  }) async {
    // Le backend attend 'telephone' (pas 'contact')
    final body = <String, dynamic>{
      'nom': nom,
      'prenom': prenom,
      'email': email.trim().toLowerCase(),
      'password': password,
      'telephone': telephone,
      'role': role,
    };
    if (typeHandicap != null && typeHandicap.isNotEmpty) body['typeHandicap'] = typeHandicap;
    if (besoinSpecifique != null && besoinSpecifique.isNotEmpty) body['besoinSpecifique'] = besoinSpecifique;
    body['animalAssistance'] = animalAssistance;
    if (typeAccompagnant != null && typeAccompagnant.isNotEmpty) body['typeAccompagnant'] = typeAccompagnant;
    if (specialisation != null && specialisation.isNotEmpty) body['specialisation'] = specialisation;
    if (langue != null && langue.isNotEmpty) body['langue'] = langue;

    try {
      print('🔵 [UserRepository] Envoi de la requête d\'inscription:');
      print('   URL: ${_api.dio.options.baseUrl}${Endpoints.userRegister}');
      print('   Body: $body');
      
      final response = await _api.dio.post(Endpoints.userRegister, data: body);
      
      print('✅ [UserRepository] Inscription réussie');
      print('   Response: ${response.data}');
      
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      print('❌ [UserRepository] Erreur lors de l\'inscription:');
      print('   Type: ${e.runtimeType}');
      print('   Message: $e');
      if (e is DioException) {
        print('   Status Code: ${e.response?.statusCode}');
        print('   Response Data: ${e.response?.data}');
        print('   Request URL: ${e.requestOptions.uri}');
      }
      rethrow;
    }
  }

  /// Profil de l'utilisateur connecté.
  Future<UserModel> getMe() async {
    final response = await _api.dio.get(Endpoints.userMe);
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Mise à jour du profil.
  Future<UserModel> updateMe({
    String? nom,
    String? prenom,
    String? telephone,
    String? typeHandicap,
    String? besoinSpecifique,
    bool? animalAssistance,
    String? typeAccompagnant,
    String? specialisation,
    bool? disponible,
    String? langue,
  }) async {
    final body = <String, dynamic>{};
    if (nom != null) body['nom'] = nom;
    if (prenom != null) body['prenom'] = prenom;
    if (telephone != null) body['telephone'] = telephone;
    if (typeHandicap != null) body['typeHandicap'] = typeHandicap;
    if (besoinSpecifique != null) body['besoinSpecifique'] = besoinSpecifique;
    if (animalAssistance != null) body['animalAssistance'] = animalAssistance;
    if (typeAccompagnant != null) body['typeAccompagnant'] = typeAccompagnant;
    if (specialisation != null) body['specialisation'] = specialisation;
    if (disponible != null) body['disponible'] = disponible;
    if (langue != null) body['langue'] = langue;

    final response = await _api.dio.patch(Endpoints.userMe, data: body);
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Suppression du compte.
  Future<void> deleteMe() async {
    await _api.dio.delete(Endpoints.userMe);
  }

  /// Upload photo de profil (PATCH /user/me/photo).
  /// Le backend Nest utilise `FileInterceptor('image')` → le champ multipart doit s'appeler **image**.
  /// Ne pas fixer Content-Type à la main : Dio doit ajouter le boundary automatiquement.
  Future<UserModel> updateProfilePhoto(XFile image) async {
    final MultipartFile file;
    if (kIsWeb) {
      final bytes = await image.readAsBytes();
      final name =
          image.name.isNotEmpty ? image.name : 'profile.jpg';
      file = MultipartFile.fromBytes(bytes, filename: name);
    } else {
      file = await MultipartFile.fromFile(
        image.path,
        filename: image.name.isNotEmpty ? image.name : null,
      );
    }

    final formData = FormData.fromMap({'image': file});

    final response = await _api.dio.patch(
      Endpoints.userMePhoto,
      data: formData,
    );
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// URL complète d'une photo de profil (photoProfil).
  static String photoUrl(String? filename) {
    if (filename == null || filename.isEmpty) return '';
    final base = AppConfig.uploadsBaseUrl.replaceAll(RegExp(r'/$'), '');
    final n = filename.replaceAll(r'\', '/');
    final path = n.startsWith('/') ? n : '/uploads/$n';
    return '$base$path';
  }
}
