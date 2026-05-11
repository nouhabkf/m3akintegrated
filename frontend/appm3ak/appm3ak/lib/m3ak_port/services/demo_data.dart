import 'package:appm3ak/m3ak_port/models/exercise_response.dart';
import 'package:appm3ak/m3ak_port/models/predict_response.dart';

class DemoData {
  /// `false` : appels réels vers Nest `API_BASE_URL/m3ak` (next_exercise, predict, update_profile).
  /// `true` : données locales uniquement, sans backend.
  static const bool useDemoMode = false;

  static final List<ExerciseResponse> exercises = [
    ExerciseResponse(
      exerciseId: 1,
      question: "Quel est ce caractère Braille ?",
      braillePattern: "⠁",
      difficulty: 1,
      exerciseType: "lecture",
      correctAnswer: "a",
      hints: ["C'est la première lettre"],
    ),
    ExerciseResponse(
      exerciseId: 2,
      question: "Quel est ce caractère Braille ?",
      braillePattern: "⠃",
      difficulty: 1,
      exerciseType: "lecture",
      correctAnswer: "b",
      hints: ["C'est la deuxième lettre"],
    ),
    ExerciseResponse(
      exerciseId: 3,
      question: "Quel est ce caractère Braille ?",
      braillePattern: "⠉",
      difficulty: 1,
      exerciseType: "lecture",
      correctAnswer: "c",
      hints: ["C'est la troisième lettre"],
    ),
    ExerciseResponse(
      exerciseId: 4,
      question: "Quel est ce mot Braille ?",
      braillePattern: "⠃⠕⠝⠚⠕⠥⠗",
      difficulty: 2,
      exerciseType: "mot",
      correctAnswer: "bonjour",
      hints: ["C'est une salutation"],
    ),
  ];

  // ✅ Prédiction par défaut
  static PredictResponse getDefaultPrediction() {
    return PredictResponse(
      recommendedDifficulty: 1,
      feedback: "👌 Continue !",
      performanceScore: 50.0,
      nextExerciseId: 2,
    );
  }

  // ✅ Prédiction pour une réponse correcte
  static PredictResponse getCorrectPrediction() {
    return PredictResponse(
      recommendedDifficulty: 2,
      feedback: "🎉 Excellent ! Tu progresses bien !",
      performanceScore: 85.0,
      nextExerciseId: 3,
    );
  }

  // ✅ Prédiction pour une réponse incorrecte
  static PredictResponse getIncorrectPrediction() {
    return PredictResponse(
      recommendedDifficulty: 1,
      feedback: "💪 Réessaie, tu vas y arriver !",
      performanceScore: 30.0,
      nextExerciseId: 1,
    );
  }

  // ✅ Prédiction basée sur le score
  static PredictResponse getPredictionForScore(double score) {
    if (score >= 80.0) {
      return getCorrectPrediction();
    } else if (score >= 50.0) {
      return getDefaultPrediction();
    } else {
      return getIncorrectPrediction();
    }
  }

  // ✅ Exercice aléatoire
  static ExerciseResponse getRandomExercise() {
    final randomIndex = DateTime.now().millisecondsSinceEpoch % exercises.length;
    return exercises[randomIndex];
  }

  // ✅ Exercice par ID
  static ExerciseResponse? getExerciseById(int id) {
    try {
      return exercises.firstWhere((ex) => ex.exerciseId == id);
    } catch (e) {
      return exercises.first;
    }
  }

  // ✅ Prochain exercice basé sur l'ID actuel
  static ExerciseResponse getNextExercise(int currentId) {
    final nextId = currentId + 1;
    final exercise = getExerciseById(nextId);
    return exercise ?? exercises.first;
  }
}