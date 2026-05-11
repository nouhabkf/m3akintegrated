import 'dart:math';

class QuizGame {
  final List<QuizQuestion> _questions = [];
  int _currentQuestionIndex = 0;
  int _score = 0;

  List<QuizQuestion> get questions => List.unmodifiable(_questions);
  int get currentQuestionIndex => _currentQuestionIndex;
  int get score => _score;
  bool get hasNextQuestion => _currentQuestionIndex < _questions.length - 1;
  QuizQuestion? get currentQuestion =>
      _questions.isNotEmpty ? _questions[_currentQuestionIndex] : null;

  void initializeQuiz({int numberOfQuestions = 10}) {
    _questions.clear();
    _currentQuestionIndex = 0;
    _score = 0;

    for (int i = 0; i < numberOfQuestions; i++) {
      _questions.add(_generateRandomQuestion());
    }
  }

  bool submitAnswer(String answer) {
    if (currentQuestion == null) return false;

    final isCorrect =
        currentQuestion!.correctAnswer.toLowerCase() == answer.toLowerCase();
    if (isCorrect) {
      _score++;
    }
    return isCorrect;
  }

  void nextQuestion() {
    if (hasNextQuestion) {
      _currentQuestionIndex++;
    }
  }

  QuizSummary getSummary() {
    return QuizSummary(
      totalQuestions: _questions.length,
      correctAnswers: _score,
      wrongAnswers: _questions.length - _score,
      scorePercentage: (_score / _questions.length) * 100,
    );
  }

  QuizQuestion _generateRandomQuestion() {
    final random = Random();
    final letters = List.generate(26, (index) => String.fromCharCode(97 + index));
    final correctLetter = letters[random.nextInt(letters.length)];

    // Générer des options incorrectes
    final options = <String>{correctLetter};
    while (options.length < 4) {
      options.add(letters[random.nextInt(letters.length)]);
    }

    return QuizQuestion(
      id: random.nextInt(1000),
      question: 'Quel est ce caractère Braille ?',
      braillePattern: _getBraillePatternForLetter(correctLetter),
      options: options.toList()..shuffle(),
      correctAnswer: correctLetter,
      explanation: 'Le caractère Braille pour "${correctLetter.toUpperCase()}" '
          'est représenté par ce motif de points.',
    );
  }

  String _getBraillePatternForLetter(String letter) {
    // Simuler un motif Braille
    final patterns = {
      'a': '⠁', 'b': '⠃', 'c': '⠉', 'd': '⠙', 'e': '⠑',
      'f': '⠋', 'g': '⠛', 'h': '⠓', 'i': '⠊', 'j': '⠚',
      'k': '⠅', 'l': '⠇', 'm': '⠍', 'n': '⠝', 'o': '⠕',
      'p': '⠏', 'q': '⠟', 'r': '⠗', 's': '⠎', 't': '⠞',
      'u': '⠥', 'v': '⠧', 'w': '⠺', 'x': '⠭', 'y': '⠽', 'z': '⠵',
    };
    return patterns[letter] ?? '⠿';
  }

  void reset() {
    _questions.clear();
    _currentQuestionIndex = 0;
    _score = 0;
  }
}

class QuizQuestion {
  final int id;
  final String question;
  final String braillePattern;
  final List<String> options;
  final String correctAnswer;
  final String explanation;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.braillePattern,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
  });
}

class QuizSummary {
  final int totalQuestions;
  final int correctAnswers;
  final int wrongAnswers;
  final double scorePercentage;

  QuizSummary({
    required this.totalQuestions,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.scorePercentage,
  });
}