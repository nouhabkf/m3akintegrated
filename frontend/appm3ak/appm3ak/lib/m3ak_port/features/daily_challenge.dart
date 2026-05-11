import 'package:shared_preferences/shared_preferences.dart';

class DailyChallenge {
  static const String _keyLastChallengeDate = 'last_challenge_date';
  static const String _keyChallengesCompleted = 'challenges_completed';
  static const String _keyCurrentStreak = 'current_streak';

  final SharedPreferences _prefs;

  DailyChallenge._(this._prefs);

  static Future<DailyChallenge> create() async {
    final prefs = await SharedPreferences.getInstance();
    return DailyChallenge._(prefs);
  }

  bool isNewChallengeAvailable() {
    final lastDate = _prefs.getString(_keyLastChallengeDate);
    final today = _getTodayDateString();
    return lastDate != today;
  }

  DailyChallengeData? getTodayChallenge() {
    if (!isNewChallengeAvailable()) {
      return null;
    }

    final challengeId = _getTodayDateString().hashCode;
    return DailyChallengeData(
      id: challengeId,
      date: _getTodayDateString(),
      exercisesCount: 5,
      difficulty: _calculateDailyDifficulty(),
      completed: false,
    );
  }

  Future<void> completeTodayChallenge() async {
    final today = _getTodayDateString();
    final previousDate = _prefs.getString(_keyLastChallengeDate);

    // Evite les doubles enregistrements le meme jour.
    if (previousDate == today) {
      return;
    }

    await _prefs.setString(_keyLastChallengeDate, today);

    final completed = _prefs.getInt(_keyChallengesCompleted) ?? 0;
    await _prefs.setInt(_keyChallengesCompleted, completed + 1);

    final yesterday = _getYesterdayDateString();
    final currentStreak = _prefs.getInt(_keyCurrentStreak) ?? 0;

    final newStreak = (previousDate == yesterday) ? currentStreak + 1 : 1;
    await _prefs.setInt(_keyCurrentStreak, newStreak);
  }

  int getChallengesCompleted() {
    return _prefs.getInt(_keyChallengesCompleted) ?? 0;
  }

  int getCurrentStreak() {
    return _prefs.getInt(_keyCurrentStreak) ?? 0;
  }

  Future<void> resetForDemo() async {
    await _prefs.remove(_keyLastChallengeDate);
    await _prefs.remove(_keyChallengesCompleted);
    await _prefs.remove(_keyCurrentStreak);
  }

  int _calculateDailyDifficulty() {
    final streak = getCurrentStreak();
    if (streak < 4) return 1;
    if (streak < 8) return 2;
    return 3;
  }

  String _getTodayDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  String _getYesterdayDateString() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return '${yesterday.year}-${yesterday.month}-${yesterday.day}';
  }
}

class DailyChallengeData {
  final int id;
  final String date;
  final int exercisesCount;
  final int difficulty;
  final bool completed;

  DailyChallengeData({
    required this.id,
    required this.date,
    required this.exercisesCount,
    required this.difficulty,
    required this.completed,
  });
}