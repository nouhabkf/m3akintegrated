class SignExplainResponse {
  final String? detectedWord;
  final String explanation;
  final List<String> raisedFingers;
  final int raisedFingersCount;
  final double confidence;
  final List<SignLandmark> landmarks;

  SignExplainResponse({
    required this.detectedWord,
    required this.explanation,
    required this.raisedFingers,
    required this.raisedFingersCount,
    required this.confidence,
    required this.landmarks,
  });

  factory SignExplainResponse.fromJson(Map<String, dynamic> json) {
    return SignExplainResponse(
      detectedWord: json['detected_word'] as String?,
      explanation: (json['explanation'] ?? '') as String,
      raisedFingers: (json['raised_fingers'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      raisedFingersCount: (json['raised_fingers_count'] ?? 0) as int,
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      landmarks: (json['landmarks'] as List<dynamic>? ?? const [])
          .map((e) => SignLandmark.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SignLandmark {
  final double x;
  final double y;
  final double z;

  SignLandmark({
    required this.x,
    required this.y,
    required this.z,
  });

  factory SignLandmark.fromJson(Map<String, dynamic> json) {
    return SignLandmark(
      x: (json['x'] ?? 0.0).toDouble(),
      y: (json['y'] ?? 0.0).toDouble(),
      z: (json['z'] ?? 0.0).toDouble(),
    );
  }
}

