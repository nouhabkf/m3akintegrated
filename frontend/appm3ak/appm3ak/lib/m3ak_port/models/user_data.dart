import 'package:json_annotation/json_annotation.dart';

// Commentez ou supprimez cette ligne si vous ne voulez pas générer le code
// part 'user_data.g.dart';

@JsonSerializable()
class UserData {
  @JsonKey(name: 'user_id')
  final int userId;

  @JsonKey(name: 'response_time')
  final int responseTime;

  @JsonKey(name: 'errors_count')
  final int errorsCount;

  final double score;

  @JsonKey(name: 'previous_successes')
  final int previousSuccesses;

  @JsonKey(name: 'exercise_id')
  final int exerciseId;

  @JsonKey(name: 'user_answer')
  final String userAnswer;

  @JsonKey(name: 'success_streak')
  final int successStreak;

  @JsonKey(name: 'avg_last_5_scores')
  final double avgLast5Scores;

  @JsonKey(name: 'total_sessions')
  final int totalSessions;

  @JsonKey(name: 'error_rate')
  final double errorRate;

  @JsonKey(name: 'avg_response_time')
  final int avgResponseTime;

  UserData({
    required this.userId,
    required this.responseTime,
    required this.errorsCount,
    required this.score,
    required this.previousSuccesses,
    required this.exerciseId,
    required this.userAnswer,
    required this.successStreak,
    required this.avgLast5Scores,
    required this.totalSessions,
    required this.errorRate,
    required this.avgResponseTime,
  });

  // Factory constructor MANUEL pour fromJson
  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      userId: json['user_id'] as int,
      responseTime: json['response_time'] as int,
      errorsCount: json['errors_count'] as int,
      score: (json['score'] as num).toDouble(),
      previousSuccesses: json['previous_successes'] as int,
      exerciseId: json['exercise_id'] as int,
      userAnswer: json['user_answer'] as String,
      successStreak: json['success_streak'] as int,
      avgLast5Scores: (json['avg_last_5_scores'] as num).toDouble(),
      totalSessions: json['total_sessions'] as int,
      errorRate: (json['error_rate'] as num).toDouble(),
      avgResponseTime: json['avg_response_time'] as int,
    );
  }

  // Méthode MANUELLE pour toJson
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'response_time': responseTime,
      'errors_count': errorsCount,
      'score': score,
      'previous_successes': previousSuccesses,
      'exercise_id': exerciseId,
      'user_answer': userAnswer,
      'success_streak': successStreak,
      'avg_last_5_scores': avgLast5Scores,
      'total_sessions': totalSessions,
      'error_rate': errorRate,
      'avg_response_time': avgResponseTime,
    };
  }

  // Méthode utilitaire pour créer une copie avec des champs modifiés
  UserData copyWith({
    int? userId,
    int? responseTime,
    int? errorsCount,
    double? score,
    int? previousSuccesses,
    int? exerciseId,
    String? userAnswer,
    int? successStreak,
    double? avgLast5Scores,
    int? totalSessions,
    double? errorRate,
    int? avgResponseTime,
  }) {
    return UserData(
      userId: userId ?? this.userId,
      responseTime: responseTime ?? this.responseTime,
      errorsCount: errorsCount ?? this.errorsCount,
      score: score ?? this.score,
      previousSuccesses: previousSuccesses ?? this.previousSuccesses,
      exerciseId: exerciseId ?? this.exerciseId,
      userAnswer: userAnswer ?? this.userAnswer,
      successStreak: successStreak ?? this.successStreak,
      avgLast5Scores: avgLast5Scores ?? this.avgLast5Scores,
      totalSessions: totalSessions ?? this.totalSessions,
      errorRate: errorRate ?? this.errorRate,
      avgResponseTime: avgResponseTime ?? this.avgResponseTime,
    );
  }

  @override
  String toString() {
    return 'UserData{userId: $userId, exerciseId: $exerciseId, score: $score}';
  }
}