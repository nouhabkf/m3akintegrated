import 'package:json_annotation/json_annotation.dart';

// Supprimez ou commentez la ligne 'part' car nous n'utilisons pas de génération
// part 'exercise_response.g.dart';

class ExerciseResponse {
  @JsonKey(name: 'exercise_id')
  final int exerciseId;

  final String question;

  @JsonKey(name: 'braille_pattern')
  final String braillePattern;

  final int difficulty;

  @JsonKey(name: 'exercise_type')
  final String exerciseType;

  @JsonKey(name: 'correct_answer')
  final String correctAnswer;

  final List<String>? hints;

  ExerciseResponse({
    required this.exerciseId,
    required this.question,
    required this.braillePattern,
    required this.difficulty,
    required this.exerciseType,
    required this.correctAnswer,
    this.hints,
  });

  // Factory constructor manuel pour fromJson
  factory ExerciseResponse.fromJson(Map<String, dynamic> json) {
    return ExerciseResponse(
      exerciseId: json['exercise_id'] as int,
      question: json['question'] as String,
      braillePattern: json['braille_pattern'] as String,
      difficulty: json['difficulty'] as int,
      exerciseType: json['exercise_type'] as String,
      correctAnswer: json['correct_answer'] as String,
      hints: json['hints'] != null
          ? List<String>.from(json['hints'] as List)
          : null,
    );
  }

  // Méthode manuelle pour toJson
  Map<String, dynamic> toJson() {
    return {
      'exercise_id': exerciseId,
      'question': question,
      'braille_pattern': braillePattern,
      'difficulty': difficulty,
      'exercise_type': exerciseType,
      'correct_answer': correctAnswer,
      'hints': hints,
    };
  }

  // Méthode utilitaire pour créer une copie avec des champs modifiés
  ExerciseResponse copyWith({
    int? exerciseId,
    String? question,
    String? braillePattern,
    int? difficulty,
    String? exerciseType,
    String? correctAnswer,
    List<String>? hints,
  }) {
    return ExerciseResponse(
      exerciseId: exerciseId ?? this.exerciseId,
      question: question ?? this.question,
      braillePattern: braillePattern ?? this.braillePattern,
      difficulty: difficulty ?? this.difficulty,
      exerciseType: exerciseType ?? this.exerciseType,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      hints: hints ?? this.hints,
    );
  }

  @override
  String toString() {
    return 'ExerciseResponse{exerciseId: $exerciseId, question: $question, exerciseType: $exerciseType}';
  }
}