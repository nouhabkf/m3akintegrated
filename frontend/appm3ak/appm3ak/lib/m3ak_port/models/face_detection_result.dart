class FaceDetectionResult {
  final bool faceDetected;
  final double? confidence;
  final List<int>? boundingBox; // [x, y, width, height]

  FaceDetectionResult({
    required this.faceDetected,
    this.confidence,
    this.boundingBox,
  });

  factory FaceDetectionResult.fromJson(Map<String, dynamic> json) {
    return FaceDetectionResult(
      faceDetected: json['face_detected'] as bool,
      confidence: json['confidence'] != null
          ? (json['confidence'] as num).toDouble()
          : null,
      boundingBox: json['bounding_box'] != null
          ? (json['bounding_box'] as List).map((e) => e as int).toList()
          : null,
    );
  }
}

class FaceEncodingResult {
  final bool success;
  final List<double>? embedding; // Vecteur 128D ou 512D
  final String? error;

  FaceEncodingResult({
    required this.success,
    this.embedding,
    this.error,
  });

  factory FaceEncodingResult.fromJson(Map<String, dynamic> json) {
    return FaceEncodingResult(
      success: json['success'] as bool,
      embedding: json['embedding'] != null
          ? (json['embedding'] as List)
              .map((e) => (e as num).toDouble())
              .toList()
          : null,
      error: json['error'] as String?,
    );
  }
}

class FaceRecognitionResult {
  final bool recognized;
  final String? personName;
  final String? relation;
  final double? confidence;
  final String? emotion;

  FaceRecognitionResult({
    required this.recognized,
    this.personName,
    this.relation,
    this.confidence,
    this.emotion,
  });
}

class EmotionResult {
  final String emotion; // 'happy', 'sad', 'neutral', 'angry', 'surprised'
  final double confidence;

  EmotionResult({
    required this.emotion,
    required this.confidence,
  });

  factory EmotionResult.fromJson(Map<String, dynamic> json) {
    return EmotionResult(
      emotion: json['emotion'] as String,
      confidence: (json['confidence'] as num).toDouble(),
    );
  }

  String get emotionInFrench {
    switch (emotion.toLowerCase()) {
      case 'happy':
        return 'sourit';
      case 'sad':
        return 'est triste';
      case 'angry':
        return 'est en colère';
      case 'surprised':
        return 'est surpris';
      default:
        return 'a une expression neutre';
    }
  }
}

