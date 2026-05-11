enum CourseLevel { beginner, intermediate, advanced }

class SignLanguageCourse {
  final int id;
  final String title;
  final String description;
  final CourseLevel level;
  final String? videoUrl;
  final String? imageUrl;
  final List<SignLanguageLesson> lessons;
  final bool isTunisian;

  SignLanguageCourse({
    required this.id,
    required this.title,
    required this.description,
    required this.level,
    this.videoUrl,
    this.imageUrl,
    required this.lessons,
    this.isTunisian = false,
  });
}

class SignLanguageLesson {
  final int id;
  final String title;
  final String sign;
  final String description;
  final String? videoUrl;
  final List<AnimationStep> animationSteps;
  final List<String> practiceWords;

  SignLanguageLesson({
    required this.id,
    required this.title,
    required this.sign,
    required this.description,
    this.videoUrl,
    required this.animationSteps,
    required this.practiceWords,
  });
}

class AnimationStep {
  final int stepNumber;
  final String instruction;
  final String? imageUrl;
  final int duration; // en millisecondes

  AnimationStep({
    required this.stepNumber,
    required this.instruction,
    this.imageUrl,
    this.duration = 2000,
  });
}

class SignLanguageCourseManager {
  static List<SignLanguageCourse> getCoursesByLevel(CourseLevel level) {
    switch (level) {
      case CourseLevel.beginner:
        return _getBeginnerCourses();
      case CourseLevel.intermediate:
        return _getIntermediateCourses();
      case CourseLevel.advanced:
        return _getAdvancedCourses();
    }
  }

  static List<SignLanguageCourse> _getBeginnerCourses() {
    return [
      SignLanguageCourse(
        id: 1,
        title: 'Alphabet en Langue des Signes',
        description: 'Apprenez l\'alphabet complet en langue des signes',
        level: CourseLevel.beginner,
        lessons: [
          SignLanguageLesson(
            id: 1,
            title: 'Lettres A-E',
            sign: 'A, B, C, D, E',
            description: 'Les 5 premières lettres de l\'alphabet',
            animationSteps: [
              AnimationStep(
                stepNumber: 1,
                instruction: 'Positionnez votre main droite',
              ),
              AnimationStep(
                stepNumber: 2,
                instruction: 'Formez la lettre A avec votre poing',
              ),
              AnimationStep(
                stepNumber: 3,
                instruction: 'Formez la lettre B avec vos doigts étendus',
              ),
            ],
            practiceWords: ['A', 'B', 'C', 'D', 'E'],
          ),
        ],
        isTunisian: true,
      ),
      SignLanguageCourse(
        id: 2,
        title: 'Mots de Base',
        description: 'Mots essentiels pour la communication quotidienne',
        level: CourseLevel.beginner,
        lessons: [
          SignLanguageLesson(
            id: 2,
            title: 'Salutations',
            sign: 'Bonjour, Au revoir, Merci',
            description: 'Apprenez à saluer en langue des signes',
            animationSteps: [
              AnimationStep(
                stepNumber: 1,
                instruction: 'Levez votre main droite',
              ),
              AnimationStep(
                stepNumber: 2,
                instruction: 'Faites un mouvement de salutation',
              ),
            ],
            practiceWords: ['Bonjour', 'Au revoir', 'Merci'],
          ),
        ],
        isTunisian: true,
      ),
    ];
  }

  static List<SignLanguageCourse> _getIntermediateCourses() {
    return [
      SignLanguageCourse(
        id: 3,
        title: 'Conversation Quotidienne',
        description: 'Phrases et expressions pour la conversation',
        level: CourseLevel.intermediate,
        lessons: [],
        isTunisian: true,
      ),
    ];
  }

  static List<SignLanguageCourse> _getAdvancedCourses() {
    return [
      SignLanguageCourse(
        id: 4,
        title: 'Langue des Signes Avancée',
        description: 'Expressions complexes et nuances',
        level: CourseLevel.advanced,
        lessons: [],
        isTunisian: true,
      ),
    ];
  }
}