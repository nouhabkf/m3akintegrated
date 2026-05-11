import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:appm3ak/core/config/app_config.dart';
import 'package:appm3ak/m3ak_port/models/sign_explain_response.dart';

class SignAiService {
  SignAiService({Dio? dio}) : _dio = dio ?? Dio(BaseOptions(baseUrl: _resolveBaseUrl()));

  final Dio _dio;
  String get baseUrl => _dio.options.baseUrl;

  /// Même API Ma3ak que [ApiService] Braille : `API_BASE_URL` + `/m3ak`.
  static String _resolveBaseUrl() => '${AppConfig.apiBaseUrl}/m3ak';

  Future<SignExplainResponse> explainSignBytes(Uint8List bytes) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: 'frame.jpg',
      ),
    });

    final response = await _dio.post(
      '/sign/explain',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return SignExplainResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<bool> pingServer() async {
    try {
      final response = await _dio.get('/');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

