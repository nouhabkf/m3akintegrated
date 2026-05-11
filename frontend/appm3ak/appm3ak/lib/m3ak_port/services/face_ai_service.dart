import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:appm3ak/core/config/app_config.dart';
import 'package:appm3ak/m3ak_port/models/face_detection_result.dart';
import 'package:appm3ak/m3ak_port/services/face_tflite_service.dart';

/// Détection / encodage visage : **TFLite local** ([FaceTfliteService]) si le modèle
/// est présent, sinon repli sur Nest `API_BASE_URL/m3ak/face/*`.
class FaceAiService {
  FaceAiService({Dio? dio, FaceTfliteService? tflite})
      : _dio = dio ?? Dio(BaseOptions(baseUrl: _resolveBaseUrl())),
        _tflite = tflite ?? FaceTfliteService();

  final Dio _dio;
  final FaceTfliteService _tflite;
  bool _tfliteInitDone = false;

  String get baseUrl => _dio.options.baseUrl;

  static String _resolveBaseUrl() => '${AppConfig.apiBaseUrl}/m3ak';

  Future<void> _ensureTflite() async {
    if (_tfliteInitDone) return;
    _tfliteInitDone = true;
    await _tflite.initialize();
  }

  /// Détecte un visage dans l'image
  Future<FaceDetectionResult> detectFace(Uint8List imageBytes) async {
    await _ensureTflite();
    if (_tflite.isReady) {
      return _tflite.detectFace(imageBytes);
    }
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          imageBytes,
          filename: 'face.jpg',
        ),
      });

      final response = await _dio.post(
        '/face/detect',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      return FaceDetectionResult.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      return FaceDetectionResult(faceDetected: false);
    }
  }

  /// Génère l'embedding (vecteur) du visage
  Future<FaceEncodingResult> encodeFace(Uint8List imageBytes) async {
    await _ensureTflite();
    if (_tflite.isReady) {
      return _tflite.encodeFace(imageBytes);
    }
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          imageBytes,
          filename: 'face.jpg',
        ),
      });

      final response = await _dio.post(
        '/face/encode',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      return FaceEncodingResult.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      return FaceEncodingResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Détecte l'émotion du visage (serveur uniquement ; pas de modèle émotion en local)
  Future<EmotionResult> detectEmotion(Uint8List imageBytes) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          imageBytes,
          filename: 'face.jpg',
        ),
      });

      final response = await _dio.post(
        '/face/emotion',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      return EmotionResult.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      return EmotionResult(emotion: 'neutral', confidence: 0.0);
    }
  }

  /// Vérifie si le serveur est disponible
  Future<bool> pingServer() async {
    try {
      final response = await _dio.get('/');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
