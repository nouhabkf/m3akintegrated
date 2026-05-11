import 'package:json_annotation/json_annotation.dart';

// Commentez ou supprimez cette ligne si vous ne voulez pas générer le code
// part 'predict_response.g.dart';

@JsonSerializable()
class PredictResponse {
  @JsonKey(name: 'recommended_difficulty')
  final int recommendedDifficulty;

  final String feedback;

  @JsonKey(name: 'performance_score')
  final double performanceScore;

  @JsonKey(name: 'next_exercise_id')
  final int? nextExerciseId;

  PredictResponse({
    required this.recommendedDifficulty,
    required this.feedback,
    required this.performanceScore,
    this.nextExerciseId,
  });

  // Factory constructor MANUEL pour fromJson
  factory PredictResponse.fromJson(Map<String, dynamic> json) {
    return PredictResponse(
      recommendedDifficulty: json['recommended_difficulty'] as int,
      feedback: json['feedback'] as String,
      performanceScore: (json['performance_score'] as num).toDouble(),
      nextExerciseId: json['next_exercise_id'] as int?,
    );
  }

  // Méthode MANUELLE pour toJson
  Map<String, dynamic> toJson() {
    return {
      'recommended_difficulty': recommendedDifficulty,
      'feedback': feedback,
      'performance_score': performanceScore,
      'next_exercise_id': nextExerciseId,
    };
  }

  // Méthode utilitaire pour créer une copie
  PredictResponse copyWith({
    int? recommendedDifficulty,
    String? feedback,
    double? performanceScore,
    int? nextExerciseId,
  }) {
    return PredictResponse(
      recommendedDifficulty: recommendedDifficulty ?? this.recommendedDifficulty,
      feedback: feedback ?? this.feedback,
      performanceScore: performanceScore ?? this.performanceScore,
      nextExerciseId: nextExerciseId ?? this.nextExerciseId,
    );
  }

  @override
  String toString() {
    return 'PredictResponse{recommendedDifficulty: $recommendedDifficulty, performanceScore: $performanceScore}';
  }
}