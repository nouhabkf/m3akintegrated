import { Injectable, Logger } from '@nestjs/common';
import { M3akPredictDto } from './dto/m3ak-predict.dto';
import { M3akUpdateProfileDto } from './dto/m3ak-update-profile.dto';

/** Exercice Braille — même contrat JSON que l’app Flutter / l’ancien FastAPI. */
type ExercisePayload = {
  exercise_id: number;
  question: string;
  braille_pattern: string;
  difficulty: number;
  exercise_type: string;
  correct_answer: string;
  hints: string[];
};

const EXERCISES: ExercisePayload[] = [
  {
    exercise_id: 1,
    question: 'Quel est ce caractère Braille ?',
    braille_pattern: '⠁',
    difficulty: 1,
    exercise_type: 'lecture',
    correct_answer: 'a',
    hints: ["C'est la première lettre"],
  },
  {
    exercise_id: 2,
    question: 'Quel est ce caractère Braille ?',
    braille_pattern: '⠃',
    difficulty: 1,
    exercise_type: 'lecture',
    correct_answer: 'b',
    hints: ["C'est la deuxième lettre"],
  },
  {
    exercise_id: 3,
    question: 'Quel est ce caractère Braille ?',
    braille_pattern: '⠉',
    difficulty: 1,
    exercise_type: 'lecture',
    correct_answer: 'c',
    hints: ["C'est la troisième lettre"],
  },
  {
    exercise_id: 4,
    question: 'Quel est ce mot Braille ?',
    braille_pattern: '⠃⠕⠝⠚⠕⠥⠗',
    difficulty: 2,
    exercise_type: 'mot',
    correct_answer: 'bonjour',
    hints: ["C'est une salutation"],
  },
];

@Injectable()
export class M3akLearningService {
  private readonly logger = new Logger(M3akLearningService.name);

  getNextExercise(userId: number): ExercisePayload {
    const index = Math.abs(userId) % EXERCISES.length;
    const ex = EXERCISES[index];
    this.logger.log(`GET next_exercise userId=${userId} → exercise_id=${ex.exercise_id}`);
    return { ...ex };
  }

  /**
   * Remplace le modèle sklearn du FastAPI : heuristique sur scores / erreurs / série.
   * Sortie alignée sur PredictResponse côté Flutter.
   */
  predict(userData: M3akPredictDto) {
    const { avg_last_5_scores, errors_count, success_streak, exercise_id } =
      userData;

    let recommended = 1;
    if (avg_last_5_scores >= 0.85 && errors_count <= 1 && success_streak >= 3) {
      recommended = 3;
    } else if (avg_last_5_scores >= 0.55) {
      recommended = 2;
    } else {
      recommended = 1;
    }

    const feedbacks: Record<number, string> = {
      1: "👌 Continue à t'entraîner !",
      2: '👍 Bon progrès !',
      3: '🌟 Excellent niveau !',
    };

    this.logger.log(
      `POST predict user_id=${userData.user_id} recommended=${recommended}`,
    );

    return {
      recommended_difficulty: recommended,
      feedback: feedbacks[recommended] ?? feedbacks[1],
      performance_score: avg_last_5_scores * 100,
      next_exercise_id: exercise_id + 1,
    };
  }

  updateProfile(userId: number, profile: M3akUpdateProfileDto) {
    this.logger.log(
      `POST update_profile userId=${userId} level=${profile.current_level} progress=${profile.progress_percentage}`,
    );
    // Persistance Mongo possible plus tard (education / profil étendu).
    return { status: 'success' as const };
  }
}
