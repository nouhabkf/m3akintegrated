import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class UserHistoryManager {
  final int userId;
  late SharedPreferences _prefs;
  static const String _keyExerciseHistory = 'exercise_history';
  static const String _keyTotalSessions = 'total_sessions';
  static const String _keySuccessStreak = 'success_streak';

  UserHistoryManager({required this.userId}) {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> recordExercise({
    required double score,
    required int responseTime,
    required int errorsCount,
  }) async {
    await _init();

    final history = await getExerciseHistory();
    final exerciseRecord = ExerciseRecord(
      score: score,
      responseTime: responseTime,
      errorsCount: errorsCount,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    history.add(exerciseRecord);
    if (history.length > 50) {
      history.removeAt(0);
    }

    await _prefs.setString(
      '${_keyExerciseHistory}_$userId',
      jsonEncode(history.map((e) => e.toJson()).toList()),
    );

    final totalSessions = _prefs.getInt('${_keyTotalSessions}_$userId') ?? 0;
    await _prefs.setInt('${_keyTotalSessions}_$userId', totalSessions + 1);

    final currentStreak = _prefs.getInt('${_keySuccessStreak}_$userId') ?? 0;
    final newStreak = score >= 0.8 ? currentStreak + 1 : 0;
    await _prefs.setInt('${_keySuccessStreak}_$userId', newStreak);
  }

  Future<List<ExerciseRecord>> getExerciseHistory() async {
    await _init();
    final historyJson = _prefs.getString('${_keyExerciseHistory}_$userId');
    if (historyJson != null) {
      final List<dynamic> jsonList = jsonDecode(historyJson);
      return jsonList.map((json) => ExerciseRecord.fromJson(json)).toList();
    }
    return [];
  }

  Future<double> getAvgLast5Scores() async {
    final history = await getExerciseHistory();
    if (history.isEmpty) return 0.0;

    final last5 = history.length >= 5
        ? history.sublist(history.length - 5)
        : history;

    return last5.map((e) => e.score).reduce((a, b) => a + b) / last5.length;
  }

  Future<double> getErrorRate() async {
    final history = await getExerciseHistory();
    if (history.isEmpty) return 0.0;

    final totalErrors = history.fold(0, (sum, e) => sum + e.errorsCount);
    return (totalErrors / (history.length * 3.0)).clamp(0.0, 1.0);
  }

  Future<int> getAvgResponseTime() async {
    final history = await getExerciseHistory();
    if (history.isEmpty) return 0;

    final total = history.fold(0, (sum, e) => sum + e.responseTime);
    return (total / history.length).round();
  }

  Future<int> getTotalSessions() async {
    await _init();
    return _prefs.getInt('${_keyTotalSessions}_$userId') ?? 0;
  }

  Future<int> getSuccessStreak() async {
    await _init();
    return _prefs.getInt('${_keySuccessStreak}_$userId') ?? 0;
  }
}

class ExerciseRecord {
  final double score;
  final int responseTime;
  final int errorsCount;
  final int timestamp;

  ExerciseRecord({
    required this.score,
    required this.responseTime,
    required this.errorsCount,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'score': score,
    'responseTime': responseTime,
    'errorsCount': errorsCount,
    'timestamp': timestamp,
  };

  factory ExerciseRecord.fromJson(Map<String, dynamic> json) => ExerciseRecord(
    score: json['score'].toDouble(),
    responseTime: json['responseTime'],
    errorsCount: json['errorsCount'],
    timestamp: json['timestamp'],
  );
}