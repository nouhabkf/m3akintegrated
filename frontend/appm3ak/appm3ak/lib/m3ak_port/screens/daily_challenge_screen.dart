import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:appm3ak/m3ak_port/services/api_service.dart';
import 'package:appm3ak/m3ak_port/models/user_data.dart';
import 'package:appm3ak/m3ak_port/features/daily_challenge.dart'; // ← votre classe existante

// ============================================================
// DAILY CHALLENGE SCREEN
// Intègre : DailyChallenge (streak + SharedPrefs) + modèle IA
// ============================================================

class DailyChallengeScreen extends StatefulWidget {
  final String userId;
  final int initialLevel;
  final ApiService? apiService;

  const DailyChallengeScreen({
    super.key,
    this.userId = '1',
    this.initialLevel = 1,
    this.apiService,
  });

  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen> {
  // ── DailyChallenge (streak + date) ──
  DailyChallenge? _dailyChallenge;
  DailyChallengeData? _todayData;
  bool _alreadyCompleted = false;   // challenge du jour déjà fait ?
  int _currentStreak = 0;
  int _totalCompleted = 0;

  // ── IA state ──
  bool _loading = true;
  String _difficulty = 'medium';
  String _aiFeedback = '';

  // ── Quiz state ──
  int _currentQuestion = 0;
  int _score = 0;
  int? _selectedAnswer;
  bool _answered = false;
  bool _finished = false;

  // ── QUESTIONS ─────────────────────────────────────────────
  static const Map<String, List<_Question>> _questionsByDifficulty = {
    'easy': [
      _Question(type: 'braille', question: 'Quelle lettre est ⠁ en Braille ?',            symbol: '⠁',         answers: ['A', 'B', 'C', 'D'],        correct: 0),
      _Question(type: 'braille', question: 'Quelle lettre est ⠃ en Braille ?',            symbol: '⠃',         answers: ['A', 'B', 'C', 'D'],        correct: 1),
      _Question(type: 'braille', question: 'Combien de points dans une cellule Braille ?', symbol: '⠿',         answers: ['4', '6', '8', '10'],       correct: 1),
      _Question(type: 'sign',    question: 'Quel geste signifie "Bonjour" ?',              symbol: '👋',        answers: ['Poing levé', 'Main depuis le front vers l\'avant', 'Deux doigts vers les yeux', 'Paume vers le bas'], correct: 1),
      _Question(type: 'sign',    question: 'Quel geste signifie "Merci" ?',                symbol: '🙏',        answers: ['Main sur la tête', 'Main plate des lèvres vers l\'avant', 'Poing sur la poitrine', 'Deux mains croisées'], correct: 1),
    ],
    'medium': [
      _Question(type: 'braille', question: 'Quelle lettre est ⠉ en Braille ?',            symbol: '⠉',         answers: ['A', 'B', 'C', 'D'],              correct: 2),
      _Question(type: 'braille', question: 'Quelle lettre est ⠙ en Braille ?',            symbol: '⠙',         answers: ['B', 'C', 'D', 'E'],              correct: 2),
      _Question(type: 'braille', question: 'Que signifie ⠃⠕⠝⠚⠕⠥⠗ en Braille ?',          symbol: '⠃⠕⠝⠚⠕⠥⠗', answers: ['Bonsoir', 'Bonjour', 'Au revoir', 'Merci'], correct: 1),
      _Question(type: 'sign',    question: 'Quel geste signifie "Au secours" ?',           symbol: '🆘',        answers: ['Pointer le sol', 'Deux bras levés et agités', 'Main sur la bouche', 'Croiser les bras'], correct: 1),
      _Question(type: 'sign',    question: 'Comment signer "Médecin" en LSF ?',            symbol: '👨‍⚕️',      answers: ['Pointer le ciel', 'Lettre M contre le poignet', 'Croix sur la tête', 'Main ouverte vers le bas'], correct: 1),
    ],
    'hard': [
      _Question(type: 'braille', question: 'Quelle lettre est ⠑ en Braille ?',            symbol: '⠑',         answers: ['D', 'E', 'F', 'G'],              correct: 1),
      _Question(type: 'braille', question: 'Que signifie ⠍⠑⠗⠉⠊ en Braille ?',            symbol: '⠍⠑⠗⠉⠊',    answers: ['Bonjour', 'Merci', 'Oui', 'Non'], correct: 1),
      _Question(type: 'braille', question: 'Quelle lettre est ⠋ en Braille ?',            symbol: '⠋',         answers: ['E', 'F', 'G', 'H'],              correct: 1),
      _Question(type: 'sign',    question: 'Comment signer "Ambulance" en urgence ?',      symbol: '🚑',        answers: ['Agiter une main', 'Deux doigts sur bras + main avant', 'Tourner sur soi', 'Pointer le ciel'], correct: 1),
      _Question(type: 'sign',    question: 'Comment signer "Opération chirurgicale" ?',    symbol: '🔬',        answers: ['Agiter la main', 'Index glissant le long de l\'avant-bras', 'Pointer le ventre', 'Main ouverte sur la tête'], correct: 1),
    ],
  };

  List<_Question> get _questions =>
      _questionsByDifficulty[_difficulty] ?? _questionsByDifficulty['medium']!;

  // ── INIT ──────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _initChallenge();
  }

  Future<void> _initChallenge() async {
    setState(() => _loading = true);

    // 1. Charger DailyChallenge (streak + date depuis SharedPrefs)
    _dailyChallenge = await DailyChallenge.create();
    _currentStreak  = _dailyChallenge!.getCurrentStreak();
    _totalCompleted = _dailyChallenge!.getChallengesCompleted();
    _todayData      = _dailyChallenge!.getTodayChallenge();
    _alreadyCompleted = _todayData == null; // null = déjà fait aujourd'hui

    // 2. Difficulté de base depuis le streak (logique de DailyChallenge)
    //    streak < 4 → 1(easy), < 8 → 2(medium), >= 8 → 3(hard)
    final streakLevel = _todayData?.difficulty ?? widget.initialLevel;

    // 3. Appel modèle IA pour affiner (override si disponible)
    await _loadDifficultyFromAI(streakLevel);
  }

  Future<void> _loadDifficultyFromAI(int streakLevel) async {
    try {
      if (widget.apiService != null) {
        final userData = UserData(
          userId: int.tryParse(widget.userId) ?? 1,
          responseTime: 7000,
          errorsCount: 1,
          score: 0.7,
          previousSuccesses: _totalCompleted,
          exerciseId: 1,
          userAnswer: 'challenge_init',
          successStreak: _currentStreak,
          avgLast5Scores: 0.68,
          totalSessions: _totalCompleted,
          errorRate: 0.25,
          avgResponseTime: 7500,
        );
        final prediction = await widget.apiService!.predictNextDifficulty(userData);
        final diffMap = {1: 'easy', 2: 'medium', 3: 'hard'};
        setState(() {
          _difficulty = diffMap[prediction.recommendedDifficulty] ?? 'medium';
          _aiFeedback = prediction.feedback;
          _loading = false;
        });
      } else {
        _applyStreakDifficulty(streakLevel);
      }
    } catch (_) {
      _applyStreakDifficulty(streakLevel);
    }
  }

  void _applyStreakDifficulty(int level) {
    final diffMap = {1: 'easy', 2: 'medium', 3: 'hard'};
    setState(() {
      _difficulty = diffMap[level] ?? 'medium';
      _aiFeedback = _currentStreak > 0
          ? '🔥 Streak de $_currentStreak jours !'
          : '(Mode hors-ligne)';
      _loading = false;
    });
  }

  // ── ANSWER LOGIC ──────────────────────────────────────────
  void _selectAnswer(int index) {
    if (_answered) return;
    HapticFeedback.lightImpact();
    setState(() {
      _selectedAnswer = index;
      _answered = true;
      if (index == _questions[_currentQuestion].correct) _score++;
    });
  }

  void _next() {
    if (_currentQuestion < _questions.length - 1) {
      setState(() {
        _currentQuestion++;
        _selectedAnswer = null;
        _answered = false;
      });
    } else {
      _finishChallenge();
    }
  }

  Future<void> _finishChallenge() async {
    // Marquer le challenge du jour comme complété dans SharedPrefs
    await _dailyChallenge?.completeTodayChallenge();
    final newStreak = _dailyChallenge?.getCurrentStreak() ?? _currentStreak;
    setState(() {
      _currentStreak = newStreak;
      _finished = true;
    });
  }

  void _restart() {
    setState(() {
      _currentQuestion = 0;
      _score = 0;
      _selectedAnswer = null;
      _answered = false;
      _finished = false;
    });
    _initChallenge();
  }

  // ── COLORS ────────────────────────────────────────────────
  Color get _levelColor {
    switch (_difficulty) {
      case 'easy':  return const Color(0xFF4CAF50);
      case 'hard':  return const Color(0xFFE53935);
      default:      return const Color(0xFF1976D2);
    }
  }

  String get _levelLabel {
    switch (_difficulty) {
      case 'easy':  return 'Facile 🟢';
      case 'hard':  return 'Difficile 🔴';
      default:      return 'Intermédiaire 🔵';
    }
  }

  Color get _questionColor {
    return _questions[_currentQuestion].type == 'braille'
        ? const Color(0xFF1976D2)
        : const Color(0xFF4CAF50);
  }

  // ── BUILD ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1A1A2E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Challenge quotidien',
            style: TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold, fontSize: 20)),
        actions: [
          // Streak badge
          if (_currentStreak > 0)
            Padding(
              padding: const EdgeInsets.only(right: 6, top: 10, bottom: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20)),
                child: Row(children: [
                  const Text('🔥', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 3),
                  Text('$_currentStreak',
                      style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                ]),
              ),
            ),
          // Score badge
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 10, bottom: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                  color: const Color(0xFF7B2D8B).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20)),
              child: Row(children: [
                const Icon(Icons.star, color: Color(0xFF7B2D8B), size: 15),
                const SizedBox(width: 3),
                Text('$_score pts',
                    style: const TextStyle(color: Color(0xFF7B2D8B), fontWeight: FontWeight.bold, fontSize: 13)),
              ]),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? _buildLoading()
            : _alreadyCompleted
            ? _buildAlreadyDone()
            : _finished
            ? _buildResult()
            : _buildQuiz(),
      ),
    );
  }

  // ── LOADING ───────────────────────────────────────────────
  Widget _buildLoading() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 90, height: 90,
          decoration: BoxDecoration(
              color: const Color(0xFF7B2D8B).withOpacity(0.1), shape: BoxShape.circle),
          child: const Center(
              child: CircularProgressIndicator(color: Color(0xFF7B2D8B), strokeWidth: 3)),
        ),
        const SizedBox(height: 22),
        const Text('Préparation du challenge...',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
        const SizedBox(height: 8),
        Text('Le modèle IA adapte votre niveau',
            style: TextStyle(color: Colors.grey[600], fontSize: 13)),
      ]),
    );
  }

  // ── ALREADY DONE TODAY ────────────────────────────────────
  Widget _buildAlreadyDone() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('✅', style: TextStyle(fontSize: 72)),
          const SizedBox(height: 16),
          const Text('Challenge du jour terminé !',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 10),
          Text('Revenez demain pour un nouveau challenge.\nContinuez votre streak !',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14, height: 1.5)),
          const SizedBox(height: 24),
          // Streak + stats
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12)],
            ),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _StatItem(label: 'Streak', value: '🔥 $_currentStreak', color: Colors.orange),
                _StatItem(label: 'Complétés', value: '$_totalCompleted', color: const Color(0xFF7B2D8B)),
              ]),
            ]),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await _dailyChallenge?.resetForDemo();
                if (!mounted) return;
                _restart();
              },
              icon: const Icon(Icons.restart_alt),
              label: const Text('Rejouer (mode demo)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF7B2D8B)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
              ),
              child: const Text('Retour', style: TextStyle(color: Color(0xFF7B2D8B), fontWeight: FontWeight.bold)),
            ),
          ),
        ]),
      ),
    );
  }

  // ── QUIZ ──────────────────────────────────────────────────
  Widget _buildQuiz() {
    final q = _questions[_currentQuestion];
    final color = _questionColor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(children: [
        // IA + streak banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: _levelColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _levelColor.withOpacity(0.25)),
          ),
          child: Row(children: [
            const Icon(Icons.psychology, color: Color(0xFF7B2D8B), size: 14),
            const SizedBox(width: 5),
            Text('IA : $_levelLabel',
                style: TextStyle(color: _levelColor, fontWeight: FontWeight.w600, fontSize: 11)),
            if (_aiFeedback.isNotEmpty) ...[
              const SizedBox(width: 8),
              Flexible(child: Text(_aiFeedback,
                  style: TextStyle(color: _levelColor.withOpacity(0.7), fontSize: 10),
                  overflow: TextOverflow.ellipsis)),
            ],
          ]),
        ),
        const SizedBox(height: 8),

        // Progress bar
        Row(children: List.generate(_questions.length, (i) => Expanded(
          child: Container(
            height: 6,
            margin: EdgeInsets.only(right: i < _questions.length - 1 ? 6 : 0),
            decoration: BoxDecoration(
              color: i <= _currentQuestion ? color : Colors.grey[300],
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ))),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Q${_currentQuestion + 1}/${_questions.length}',
              style: TextStyle(color: Colors.grey[600], fontSize: 11)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(q.type == 'braille' ? '⠿ Braille' : '✋ Signes',
                style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 10),

        // Question card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color, color.withOpacity(0.7)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: color.withOpacity(0.28), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(children: [
            Container(
              width: 68, height: 68,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
              child: Center(child: Text(q.symbol,
                  style: TextStyle(fontSize: q.symbol.length > 2 ? 18 : 34, color: Colors.white))),
            ),
            const SizedBox(height: 12),
            Text(q.question, textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, height: 1.4)),
            if (_answered) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                child: Text(
                  _selectedAnswer == q.correct ? '✅ Bonne réponse !' : '❌ Voir la bonne en vert',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ]),
        ),
        const SizedBox(height: 10),

        // Answers
        Expanded(
          child: ListView.builder(
            itemCount: q.answers.length,
            itemBuilder: (context, i) {
              final isCorrect = i == q.correct;
              final isSelected = i == _selectedAnswer;
              Color bg = Colors.white;
              Color borderC = Colors.grey.withOpacity(0.2);
              Color textC = const Color(0xFF1A1A2E);
              Widget? trailing;
              if (_answered) {
                if (isCorrect) {
                  bg = const Color(0xFF4CAF50); borderC = const Color(0xFF4CAF50);
                  textC = Colors.white;
                  trailing = const Icon(Icons.check_circle, color: Colors.white, size: 18);
                } else if (isSelected) {
                  bg = const Color(0xFFE53935); borderC = const Color(0xFFE53935);
                  textC = Colors.white;
                  trailing = const Icon(Icons.cancel, color: Colors.white, size: 18);
                } else {
                  textC = Colors.grey[400]!;
                }
              }
              return GestureDetector(
                onTap: () => _selectAnswer(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: bg, borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: borderC, width: 2),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 5)],
                  ),
                  child: Row(children: [
                    Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                          color: _answered ? Colors.white.withOpacity(0.2) : Colors.grey.withOpacity(0.08),
                          shape: BoxShape.circle),
                      child: Center(child: (_answered && (isCorrect || isSelected))
                          ? null
                          : Text(String.fromCharCode(65 + i),
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[600], fontSize: 12))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(q.answers[i],
                        style: TextStyle(color: textC, fontWeight: FontWeight.w500, fontSize: 14))),
                    ?trailing,
                  ]),
                ),
              );
            },
          ),
        ),

        if (_answered) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _next,
              style: ElevatedButton.styleFrom(
                backgroundColor: color, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
              ),
              child: Text(
                _currentQuestion < _questions.length - 1 ? 'Question suivante →' : 'Terminer 🎉',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ]),
    );
  }

  // ── RESULT ────────────────────────────────────────────────
  Widget _buildResult() {
    final pct = (_score / _questions.length * 100).round();
    final good = pct >= 60;
    final color = good ? const Color(0xFF4CAF50) : const Color(0xFFE53935);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(children: [
        const SizedBox(height: 8),
        Text(good ? '🏆' : '💪', style: const TextStyle(fontSize: 70)),
        const SizedBox(height: 12),
        Text(good ? 'Excellent !' : 'Continuez !',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
        const SizedBox(height: 16),

        // Score
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(22),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16)]),
          child: Column(children: [
            Text('$_score / ${_questions.length}',
                style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: color)),
            Text('$pct% de réussite', style: TextStyle(color: Colors.grey[600], fontSize: 15)),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: LinearProgressIndicator(
                value: _score / _questions.length,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _StatItem(label: '🔥 Streak', value: '$_currentStreak jours', color: Colors.orange),
              _StatItem(label: '✅ Score', value: '$pct%', color: color),
              _StatItem(label: '🏅 Total', value: '${_totalCompleted + 1}', color: const Color(0xFF7B2D8B)),
            ]),
          ]),
        ),
        const SizedBox(height: 14),

        // IA feedback
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF7B2D8B).withOpacity(0.18)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.psychology, color: Color(0xFF7B2D8B), size: 18),
              SizedBox(width: 8),
              Text('Analyse IA', style: TextStyle(color: Color(0xFF7B2D8B), fontWeight: FontWeight.bold, fontSize: 14)),
            ]),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Niveau joué', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              Text(_levelLabel, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            ]),
            if (_aiFeedback.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: const Color(0xFF7B2D8B).withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  const Icon(Icons.auto_awesome, color: Color(0xFF7B2D8B), size: 14),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_aiFeedback,
                      style: TextStyle(color: Colors.grey[700], fontSize: 12, fontStyle: FontStyle.italic))),
                ]),
              ),
            ],
          ]),
        ),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7B2D8B), foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
            ),
            child: const Text('Retour au menu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ]),
    );
  }
}

// ── WIDGETS ────────────────────────────────────────────────
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
    ]);
  }
}

class _Question {
  final String type, question, symbol;
  final List<String> answers;
  final int correct;
  const _Question({required this.type, required this.question, required this.symbol, required this.answers, required this.correct});
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _Badge({required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 11)),
      ]),
    );
  }
}