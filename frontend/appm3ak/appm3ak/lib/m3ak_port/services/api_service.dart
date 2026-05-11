// ✅ LES IMPORTS DOIVENT ÊTRE TOUT EN HAUT
import 'package:flutter/widgets.dart';
import 'package:dio/dio.dart';
import 'package:appm3ak/core/config/app_config.dart';
import 'package:appm3ak/m3ak_port/models/exercise_response.dart';
import 'package:appm3ak/m3ak_port/models/predict_response.dart';
import 'package:appm3ak/m3ak_port/models/user_data.dart';
import 'package:appm3ak/m3ak_port/models/user_profile.dart';
import 'package:appm3ak/m3ak_port/services/demo_data.dart';

class ApiService {
  final Dio _dio;

  ApiService(this._dio);

  // GET: Récupérer le prochain exercice
  Future<ExerciseResponse> getNextExercise(int userId) async {
    // ✅ Mode démo
    if (DemoData.useDemoMode) {
      print('🎮 Mode démo - Chargement exercice $userId');
      await Future.delayed(const Duration(milliseconds: 500));

      // Rotation simple des exercices
      final index = userId % DemoData.exercises.length;
      return DemoData.exercises[index];
    }

    try {
      print('📤 Chargement de l\'exercice pour l\'utilisateur $userId');
      final response = await _dio.get('/next_exercise/$userId');
      return ExerciseResponse.fromJson(response.data);
    } catch (e) {
      print('❌ Erreur: $e');
      print('⚠️ Fallback vers mode démo');
      await Future.delayed(const Duration(milliseconds: 500));
      return DemoData.exercises[0];
    }
  }

  // POST: Prédire la prochaine difficulté
  Future<PredictResponse> predictNextDifficulty(UserData userData) async {
    // ✅ Mode démo
    if (DemoData.useDemoMode) {
      print('🎮 Mode démo - Prédiction pour score: ${userData.score}');
      await Future.delayed(const Duration(milliseconds: 300));

      // ✅ Utilisation de la nouvelle méthode utilitaire
      return DemoData.getPredictionForScore(userData.score);
    }

    try {
      print('📤 Envoi des données au modèle IA');
      final response = await _dio.post(
        '/predict',
        data: userData.toJson(),
      );
      return PredictResponse.fromJson(response.data);
    } catch (e) {
      print('❌ Erreur: $e');
      print('⚠️ Fallback vers mode démo');
      return DemoData.getDefaultPrediction();
    }
  }

  // POST: Mettre à jour le profil utilisateur
  Future<void> updateUserProfile(int userId, UserProfile profile) async {
    if (DemoData.useDemoMode) {
      print('🎮 Mode démo - Mise à jour profil utilisateur $userId');
      await Future.delayed(const Duration(milliseconds: 200));
      return;
    }

    try {
      await _dio.post(
        '/update_profile/$userId',
        data: profile.toJson(),
      );
      print('✅ Profil mis à jour');
    } catch (e) {
      print('❌ Erreur: $e');
      if (!DemoData.useDemoMode) rethrow;
    }
  }
}

// Client API avec pattern Singleton
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late final ApiService apiService;

  factory ApiClient() {
    return _instance;
  }

  ApiClient._internal() {
    final dio = Dio();

    dio.options = BaseOptions(
      baseUrl: '${AppConfig.apiBaseUrl}/m3ak',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    );

    // Intercepteur pour les logs
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        print('🚀 ${options.method} ${options.path}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print('✅ ${response.statusCode}');
        return handler.next(response);
      },
      onError: (DioException error, handler) {
        print('❌ ${error.message}');
        return handler.next(error);
      },
    ));

    apiService = ApiService(dio);
  }

  static ApiService get service => _instance.apiService;
}

// Extension pour faciliter l'utilisation
extension ApiServiceExtension on BuildContext {
  ApiService get apiService => ApiClient.service;
}