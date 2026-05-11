import 'package:json_annotation/json_annotation.dart';

// Commentez ou supprimez cette ligne si vous ne voulez pas générer le code
// part 'user_profile.g.dart';

@JsonSerializable()
class UserProfile {
  @JsonKey(name: 'user_id')
  final int userId;

  @JsonKey(name: 'total_exercises_completed')
  final int totalExercisesCompleted;

  @JsonKey(name: 'current_level')
  final int currentLevel;

  @JsonKey(name: 'progress_percentage')
  final double progressPercentage;

  @JsonKey(name: 'lessons_completed_this_week')
  final int lessonsCompletedThisWeek;

  @JsonKey(name: 'last_exercise_date')
  final String? lastExerciseDate;

  UserProfile({
    required this.userId,
    required this.totalExercisesCompleted,
    required this.currentLevel,
    required this.progressPercentage,
    required this.lessonsCompletedThisWeek,
    this.lastExerciseDate,
  });

  // Factory constructor MANUEL pour fromJson
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['user_id'] as int,
      totalExercisesCompleted: json['total_exercises_completed'] as int,
      currentLevel: json['current_level'] as int,
      progressPercentage: (json['progress_percentage'] as num).toDouble(),
      lessonsCompletedThisWeek: json['lessons_completed_this_week'] as int,
      lastExerciseDate: json['last_exercise_date'] as String?,
    );
  }

  // Méthode MANUELLE pour toJson
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'total_exercises_completed': totalExercisesCompleted,
      'current_level': currentLevel,
      'progress_percentage': progressPercentage,
      'lessons_completed_this_week': lessonsCompletedThisWeek,
      'last_exercise_date': lastExerciseDate,
    };
  }

  // Méthode utilitaire pour créer une copie
  UserProfile copyWith({
    int? userId,
    int? totalExercisesCompleted,
    int? currentLevel,
    double? progressPercentage,
    int? lessonsCompletedThisWeek,
    String? lastExerciseDate,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      totalExercisesCompleted: totalExercisesCompleted ?? this.totalExercisesCompleted,
      currentLevel: currentLevel ?? this.currentLevel,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      lessonsCompletedThisWeek: lessonsCompletedThisWeek ?? this.lessonsCompletedThisWeek,
      lastExerciseDate: lastExerciseDate ?? this.lastExerciseDate,
    );
  }

  @override
  String toString() {
    return 'UserProfile{userId: $userId, currentLevel: $currentLevel, progress: $progressPercentage%}';
  }
}