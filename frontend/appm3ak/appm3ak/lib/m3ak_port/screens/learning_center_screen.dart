import 'package:flutter/material.dart';
import 'package:appm3ak/m3ak_port/services/api_service.dart';
import 'package:appm3ak/m3ak_port/services/user_history_manager.dart';
import 'package:appm3ak/m3ak_port/models/exercise_response.dart';
import 'package:appm3ak/m3ak_port/models/user_data.dart';
import 'package:appm3ak/m3ak_port/models/user_profile.dart';
import 'package:appm3ak/m3ak_port/models/ai_coach_insight.dart';
import 'package:appm3ak/m3ak_port/screens/widgets/learning_center_header.dart';
import 'package:appm3ak/m3ak_port/screens/widgets/global_progress_card.dart';
import 'package:appm3ak/m3ak_port/screens/widgets/braille_learning_section.dart';
import 'package:appm3ak/m3ak_port/screens/widgets/ai_coach_card.dart';
import 'package:appm3ak/m3ak_port/services/vibration_manager.dart';
import 'package:appm3ak/m3ak_port/services/ai_coach_service.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

// ── IMPORTS ABSOLUS — évite toute confusion avec lib/features/ ──
import 'package:appm3ak/m3ak_port/screens/sign_language_screen.dart';
import 'package:appm3ak/m3ak_port/screens/practical_scenarios_screen.dart';
import 'package:appm3ak/m3ak_port/screens/daily_challenge_screen.dart';   // ← screens/, PAS features/
import 'package:appm3ak/m3ak_port/screens/converter_screen.dart';

class LearningCenterScreen extends StatefulWidget {
  const LearningCenterScreen({super.key});

  @override
  State<LearningCenterScreen> createState() => _LearningCenterScreenState();
}

class _LearningCenterScreenState extends State<LearningCenterScreen> {
  final int _userId = 1;
  final ApiService _apiService = ApiClient.service;
  final VibrationManager _vibrationManager = VibrationManager();
  final AiCoachService _aiCoachService = const AiCoachService();

  ExerciseResponse? _currentExercise;
  bool _isLoading = false;
  String? _feedback;
  double _globalProgress = 0.0;
  int _lessonsCompleted = 0;
  int _currentLevel = 1;

  DateTime _exerciseStartTime = DateTime.now();
  int _errorCount = 0;
  int _consecutiveSuccesses = 0;
  bool _showBrailleSection = false;
  AiCoachInsight? _aiCoachInsight;

  final Map<int, List<ExerciseResponse>> _exercisesByLevel = {
    1: [
      ExerciseResponse(exerciseId: 1, question: "Quel est ce caractère Braille ?", braillePattern: "⠁", difficulty: 1, exerciseType: "alphabet", correctAnswer: "a", hints: ["C'est la première lettre de l'alphabet"]),
      ExerciseResponse(exerciseId: 2, question: "Reconnaissez ce caractère Braille", braillePattern: "⠃", difficulty: 1, exerciseType: "alphabet", correctAnswer: "b", hints: ["C'est la deuxième lettre"]),
      ExerciseResponse(exerciseId: 3, question: "Quel est ce caractère Braille ?", braillePattern: "⠉", difficulty: 1, exerciseType: "alphabet", correctAnswer: "c", hints: ["C'est la troisième lettre"]),
      ExerciseResponse(exerciseId: 4, question: "Reconnaissez ce caractère Braille", braillePattern: "⠙", difficulty: 1, exerciseType: "alphabet", correctAnswer: "d", hints: ["C'est la quatrième lettre"]),
      ExerciseResponse(exerciseId: 5, question: "Quel est ce caractère Braille ?", braillePattern: "⠑", difficulty: 1, exerciseType: "alphabet", correctAnswer: "e", hints: ["C'est la cinquième lettre"]),
      ExerciseResponse(exerciseId: 6, question: "Reconnaissez ce caractère Braille", braillePattern: "⠋", difficulty: 1, exerciseType: "alphabet", correctAnswer: "f", hints: ["C'est la sixième lettre"]),
      ExerciseResponse(exerciseId: 7, question: "Quel est ce caractère Braille ?", braillePattern: "⠛", difficulty: 1, exerciseType: "alphabet", correctAnswer: "g", hints: ["C'est la septième lettre"]),
      ExerciseResponse(exerciseId: 8, question: "Reconnaissez ce caractère Braille", braillePattern: "⠓", difficulty: 1, exerciseType: "alphabet", correctAnswer: "h", hints: ["C'est la huitième lettre"]),
      ExerciseResponse(exerciseId: 9, question: "Quel est ce caractère Braille ?", braillePattern: "⠊", difficulty: 1, exerciseType: "alphabet", correctAnswer: "i", hints: ["C'est la neuvième lettre"]),
      ExerciseResponse(exerciseId: 10, question: "Reconnaissez ce caractère Braille", braillePattern: "⠚", difficulty: 1, exerciseType: "alphabet", correctAnswer: "j", hints: ["C'est la dixième lettre"]),
      ExerciseResponse(exerciseId: 11, question: "Quel est ce caractère Braille ?", braillePattern: "⠅", difficulty: 1, exerciseType: "alphabet", correctAnswer: "k", hints: ["C'est la onzième lettre"]),
      ExerciseResponse(exerciseId: 12, question: "Reconnaissez ce caractère Braille", braillePattern: "⠇", difficulty: 1, exerciseType: "alphabet", correctAnswer: "l", hints: ["C'est la douzième lettre"]),
      ExerciseResponse(exerciseId: 13, question: "Quel est ce caractère Braille ?", braillePattern: "⠍", difficulty: 1, exerciseType: "alphabet", correctAnswer: "m", hints: ["C'est la treizième lettre"]),
      ExerciseResponse(exerciseId: 14, question: "Reconnaissez ce caractère Braille", braillePattern: "⠝", difficulty: 1, exerciseType: "alphabet", correctAnswer: "n", hints: ["C'est la quatorzième lettre"]),
      ExerciseResponse(exerciseId: 15, question: "Quel est ce caractère Braille ?", braillePattern: "⠕", difficulty: 1, exerciseType: "alphabet", correctAnswer: "o", hints: ["C'est la quinzième lettre"]),
      ExerciseResponse(exerciseId: 16, question: "Reconnaissez ce caractère Braille", braillePattern: "⠏", difficulty: 1, exerciseType: "alphabet", correctAnswer: "p", hints: ["C'est la seizième lettre"]),
      ExerciseResponse(exerciseId: 17, question: "Quel est ce caractère Braille ?", braillePattern: "⠟", difficulty: 1, exerciseType: "alphabet", correctAnswer: "q", hints: ["C'est la dix-septième lettre"]),
      ExerciseResponse(exerciseId: 18, question: "Reconnaissez ce caractère Braille", braillePattern: "⠗", difficulty: 1, exerciseType: "alphabet", correctAnswer: "r", hints: ["C'est la dix-huitième lettre"]),
      ExerciseResponse(exerciseId: 19, question: "Quel est ce caractère Braille ?", braillePattern: "⠎", difficulty: 1, exerciseType: "alphabet", correctAnswer: "s", hints: ["C'est la dix-neuvième lettre"]),
      ExerciseResponse(exerciseId: 20, question: "Reconnaissez ce caractère Braille", braillePattern: "⠞", difficulty: 1, exerciseType: "alphabet", correctAnswer: "t", hints: ["C'est la vingtième lettre"]),
      ExerciseResponse(exerciseId: 21, question: "Quel est ce caractère Braille ?", braillePattern: "⠥", difficulty: 1, exerciseType: "alphabet", correctAnswer: "u", hints: ["C'est la vingt-et-unième lettre"]),
      ExerciseResponse(exerciseId: 22, question: "Reconnaissez ce caractère Braille", braillePattern: "⠧", difficulty: 1, exerciseType: "alphabet", correctAnswer: "v", hints: ["C'est la vingt-deuxième lettre"]),
      ExerciseResponse(exerciseId: 23, question: "Quel est ce caractère Braille ?", braillePattern: "⠺", difficulty: 1, exerciseType: "alphabet", correctAnswer: "w", hints: ["C'est la vingt-troisième lettre"]),
      ExerciseResponse(exerciseId: 24, question: "Reconnaissez ce caractère Braille", braillePattern: "⠭", difficulty: 1, exerciseType: "alphabet", correctAnswer: "x", hints: ["C'est la vingt-quatrième lettre"]),
      ExerciseResponse(exerciseId: 25, question: "Quel est ce caractère Braille ?", braillePattern: "⠽", difficulty: 1, exerciseType: "alphabet", correctAnswer: "y", hints: ["C'est la vingt-cinquième lettre"]),
      ExerciseResponse(exerciseId: 26, question: "Reconnaissez ce caractère Braille", braillePattern: "⠵", difficulty: 1, exerciseType: "alphabet", correctAnswer: "z", hints: ["C'est la vingt-sixième lettre"]),
    ],
    2: [
      ExerciseResponse(exerciseId: 27, question: "Quel est ce mot en Braille ?", braillePattern: "⠃⠕⠝⠚⠕⠥⠗", difficulty: 2, exerciseType: "mots", correctAnswer: "bonjour", hints: ["C'est une salutation"]),
      ExerciseResponse(exerciseId: 28, question: "Déchiffrez ce mot", braillePattern: "⠍⠑⠗⠉⠊", difficulty: 2, exerciseType: "mots", correctAnswer: "merci", hints: ["Pour remercier"]),
      ExerciseResponse(exerciseId: 29, question: "Quel est ce mot ?", braillePattern: "⠎⠊⠇⠧⠕⠥⠏⠇⠁⠊⠞", difficulty: 2, exerciseType: "mots", correctAnswer: "s'il vous plaît", hints: ["Pour être poli"]),
      ExerciseResponse(exerciseId: 30, question: "Reconnaissez ce mot", braillePattern: "⠕⠊", difficulty: 2, exerciseType: "mots", correctAnswer: "oui", hints: ["Réponse positive"]),
      ExerciseResponse(exerciseId: 31, question: "Quel est ce mot ?", braillePattern: "⠝⠕⠝", difficulty: 2, exerciseType: "mots", correctAnswer: "non", hints: ["Réponse négative"]),
      ExerciseResponse(exerciseId: 32, question: "Déchiffrez ce mot", braillePattern: "⠃⠊⠑⠝", difficulty: 2, exerciseType: "mots", correctAnswer: "bien", hints: ["Pour dire que tout va bien"]),
      ExerciseResponse(exerciseId: 33, question: "Quel est ce mot ?", braillePattern: "⠍⠁⠇", difficulty: 2, exerciseType: "mots", correctAnswer: "mal", hints: ["Quand on a une douleur"]),
      ExerciseResponse(exerciseId: 34, question: "Reconnaissez ce mot", braillePattern: "⠁⠥⠗⠑⠧⠕⠊⠗", difficulty: 2, exerciseType: "mots", correctAnswer: "au revoir", hints: ["Pour dire adieu"]),
    ],
    3: [
      ExerciseResponse(exerciseId: 35, question: "Traduisez cette phrase", braillePattern: "⠚⠑⠍⠁⠏⠑⠇⠇⠑", difficulty: 3, exerciseType: "phrases", correctAnswer: "je m'appelle", hints: ["Pour se présenter"]),
      ExerciseResponse(exerciseId: 36, question: "Que signifie cette phrase ?", braillePattern: "⠉⠕⠍⠍⠑⠝⠞⠁⠇⠇⠑⠵⠧⠕⠥⠎", difficulty: 3, exerciseType: "phrases", correctAnswer: "comment allez-vous", hints: ["Pour demander des nouvelles"]),
      ExerciseResponse(exerciseId: 37, question: "Traduisez cette phrase", braillePattern: "⠚⠑⠧⠕⠥⠎⠁⠊⠍⠑", difficulty: 3, exerciseType: "phrases", correctAnswer: "je vous aime", hints: ["Déclaration d'amour"]),
      ExerciseResponse(exerciseId: 38, question: "Que signifie cette phrase ?", braillePattern: "⠟⠑⠇⠇⠑⠓⠑⠥⠗⠑⠑⠎⠞⠊⠇", difficulty: 3, exerciseType: "phrases", correctAnswer: "quelle heure est-il", hints: ["Pour demander l'heure"]),
      ExerciseResponse(exerciseId: 39, question: "Traduisez cette phrase", braillePattern: "⠕⠥⠑⠎⠞⠇⠁⠎⠁⠇⠇⠑⠙⠑⠃⠁⠊⠝", difficulty: 3, exerciseType: "phrases", correctAnswer: "où est la salle de bain", hints: ["Question utile"]),
      ExerciseResponse(exerciseId: 40, question: "Que signifie cette phrase ?", braillePattern: "⠉⠕⠍⠃⠊⠑⠝⠉⠁⠉⠕⠥⠞⠑", difficulty: 3, exerciseType: "phrases", correctAnswer: "combien ça coûte", hints: ["Pour demander le prix"]),
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadNextExercise();
    _refreshAiCoachInsight();
  }

  Future<void> _refreshAiCoachInsight() async {
    final historyManager = Provider.of<UserHistoryManager>(context, listen: false);
    final avgLast5 = await historyManager.getAvgLast5Scores();
    final errorRate = await historyManager.getErrorRate();
    final avgResponseTime = await historyManager.getAvgResponseTime();
    final successStreak = await historyManager.getSuccessStreak();

    if (!mounted) return;
    setState(() {
      _aiCoachInsight = _aiCoachService.buildInsight(
        currentLevel: _currentLevel,
        lessonsCompleted: _lessonsCompleted,
        successStreak: successStreak,
        avgLast5Scores: avgLast5,
        errorRate: errorRate,
        avgResponseTimeMs: avgResponseTime,
      );
    });
  }

  Future<void> _loadNextExercise() async {
    setState(() { _isLoading = true; });
    try {
      final levelExercises = _exercisesByLevel[_currentLevel] ?? [];
      if (levelExercises.isEmpty) {
        if (_currentLevel < 3) {
          setState(() { _currentLevel++; });
          _loadNextExercise();
          return;
        } else {
          setState(() { _currentExercise = null; _isLoading = false; });
          return;
        }
      }
      final randomIndex = DateTime.now().millisecondsSinceEpoch % levelExercises.length;
      setState(() {
        _currentExercise = levelExercises[randomIndex];
        _exerciseStartTime = DateTime.now();
        _errorCount = 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _submitAnswer(String userAnswer) async {
    if (_currentExercise == null) return;
    setState(() { _isLoading = true; });
    try {
      final responseTime = DateTime.now().difference(_exerciseStartTime).inMilliseconds;
      final isCorrect = userAnswer.trim().toLowerCase() == _currentExercise!.correctAnswer.toLowerCase();
      if (isCorrect) {
        _consecutiveSuccesses++;
        _globalProgress = (_globalProgress + 0.02).clamp(0.0, 1.0);
        _lessonsCompleted++;
        await _vibrationManager.vibrateSuccess();
      } else {
        _consecutiveSuccesses = 0;
        _errorCount++;
        await _vibrationManager.vibrateError();
      }
      final historyManager = Provider.of<UserHistoryManager>(context, listen: false);
      await historyManager.recordExercise(score: isCorrect ? 1.0 : 0.0, responseTime: responseTime, errorsCount: _errorCount);
      final userData = UserData(
        userId: _userId, responseTime: responseTime, errorsCount: _errorCount,
        score: isCorrect ? 1.0 : 0.0, previousSuccesses: _lessonsCompleted,
        exerciseId: _currentExercise!.exerciseId, userAnswer: userAnswer,
        successStreak: await historyManager.getSuccessStreak(),
        avgLast5Scores: await historyManager.getAvgLast5Scores(),
        totalSessions: await historyManager.getTotalSessions(),
        errorRate: await historyManager.getErrorRate(),
        avgResponseTime: await historyManager.getAvgResponseTime(),
      );
      final prediction = await _apiService.predictNextDifficulty(userData);
      setState(() { _currentLevel = prediction.recommendedDifficulty; _feedback = prediction.feedback; _isLoading = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_feedback!),
          backgroundColor: isCorrect ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 2),
        ));
      }
      await _updateUserProfile();
      await _refreshAiCoachInsight();
      await Future.delayed(const Duration(seconds: 2));
      setState(() { _feedback = null; });
      await _loadNextExercise();
    } catch (e) {
      setState(() { _feedback = "Erreur de connexion au serveur"; _isLoading = false; });
    }
  }

  Future<void> _updateUserProfile() async {
    try {
      await _apiService.updateUserProfile(_userId, UserProfile(
        userId: _userId, totalExercisesCompleted: _lessonsCompleted,
        currentLevel: _currentLevel, progressPercentage: _globalProgress,
        lessonsCompletedThisWeek: _lessonsCompleted,
      ));
    } catch (e) { debugPrint('❌ Erreur mise à jour profil: $e'); }
  }

  Future<void> _testServerConnection() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🔄 Test de connexion en cours...'), duration: Duration(seconds: 1)),
    );
    try {
      final exercise = await _apiService.getNextExercise(_userId);
      final prediction = await _apiService.predictNextDifficulty(UserData(
        userId: _userId, responseTime: 5000, errorsCount: 0, score: 1.0,
        previousSuccesses: 5, exerciseId: exercise.exerciseId, userAnswer: "test",
        successStreak: 3, avgLast5Scores: 0.9, totalSessions: 10,
        errorRate: 0.1, avgResponseTime: 4500,
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ Serveur OK! Difficulté: ${prediction.recommendedDifficulty}'),
          backgroundColor: Colors.green, duration: const Duration(seconds: 4),
        ));
      }
    } on DioException catch (e) {
      String msg = '❌ ';
      if (e.type == DioExceptionType.connectionTimeout) {
        msg += 'Timeout';
      } else if (e.type == DioExceptionType.connectionError) msg += 'Impossible de se connecter';
      else if (e.response != null) msg += 'Status ${e.response?.statusCode}';
      else msg += e.message ?? 'Erreur inconnue';
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LearningCenterHeader(),
              const SizedBox(height: 12),

              // Test serveur
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: ElevatedButton.icon(
                    onPressed: _testServerConnection,
                    icon: const Icon(Icons.wifi_tethering, size: 18),
                    label: const Text('🔍 Tester connexion serveur'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue, foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 46),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              GlobalProgressCard(progress: _globalProgress, lessonsCompleted: _lessonsCompleted),
              const SizedBox(height: 20),
              if (_aiCoachInsight != null) ...[
                AiCoachCard(insight: _aiCoachInsight!),
                const SizedBox(height: 18),
              ],

              const Text('Modules d\'apprentissage',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
              const SizedBox(height: 12),

              // ── 1. Braille ──
              _ModuleCard(
                title: 'Apprentissage Braille',
                description: 'Exercices adaptés par IA · Niveau $_currentLevel/3',
                icon: Icons.menu_book,
                iconBg: const Color(0xFFE3F2FD),
                iconColor: const Color(0xFF1976D2),
                titleColor: const Color(0xFF1976D2),
                badge: _lessonsCompleted > 0 ? '$_lessonsCompleted ✓' : null,
                badgeColor: const Color(0xFF1976D2),
                onTap: () => setState(() => _showBrailleSection = !_showBrailleSection),
              ),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                crossFadeState: _showBrailleSection ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                firstChild: Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 4),
                  child: BrailleLearningSection(
                    currentExercise: _currentExercise,
                    isLoading: _isLoading,
                    feedback: _feedback,
                    onExerciseSubmit: _submitAnswer,
                  ),
                ),
                secondChild: const SizedBox(height: 8),
              ),

              // ── 2. Langue des signes ──
              _ModuleCard(
                title: 'Langue des signes',
                description: 'Cours interactifs avec reconnaissance gestuelle',
                icon: Icons.sign_language,
                iconBg: const Color(0xFFE8F5E9),
                iconColor: const Color(0xFF4CAF50),
                titleColor: const Color(0xFF4CAF50),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SignLanguageScreen())),
              ),
              const SizedBox(height: 10),

              // ── 3. Scénarios pratiques ──
              _ModuleCard(
                title: 'Scénarios pratiques',
                description: 'Simulations réelles (hôpital, transport, urgence)',
                icon: Icons.emergency,
                iconBg: const Color(0xFFFFF3E0),
                iconColor: const Color(0xFFFF6F00),
                titleColor: const Color(0xFFFF6F00),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const PracticalScenariosScreen())),
              ),
              const SizedBox(height: 10),

              // ── 4. Challenge quotidien ── NAVIGUE VERS daily_challenge_screen.dart
              _ModuleCard(
                title: 'Challenge quotidien',
                description: 'Questions adaptées par modèle IA · Niveau $_currentLevel',
                icon: Icons.emoji_events,
                iconBg: const Color(0xFFF3E5F5),
                iconColor: const Color(0xFF7B2D8B),
                titleColor: const Color(0xFF7B2D8B),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DailyChallengeScreen(
                      userId: _userId.toString(),
                      initialLevel: _currentLevel,
                      apiService: _apiService,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // ── 5. Convertisseur ──
              _ModuleCard(
                title: 'Convertisseur Braille',
                description: 'Traduisez instantanément texte ↔ Braille',
                icon: Icons.swap_horiz,
                iconBg: const Color(0xFFE0F7FA),
                iconColor: const Color(0xFF00838F),
                titleColor: const Color(0xFF00838F),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ConverterScreen())),
              ),

              const SizedBox(height: 28),
              const Center(child: Text('🇹🇳  Pour une Tunisie inclusive  🇹🇳',
                  style: TextStyle(color: Colors.grey, fontSize: 12))),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final Color titleColor;
  final VoidCallback onTap;
  final String? badge;
  final Color? badgeColor;

  const _ModuleCard({
    required this.title, required this.description, required this.icon,
    required this.iconBg, required this.iconColor, required this.titleColor,
    required this.onTap, this.badge, this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Flexible(child: Text(title, style: TextStyle(color: titleColor, fontWeight: FontWeight.bold, fontSize: 15))),
                    if (badge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                            color: (badgeColor ?? titleColor).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(badge!, style: TextStyle(color: badgeColor ?? titleColor, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 4),
                  Text(description, style: TextStyle(color: Colors.grey[600], fontSize: 12, height: 1.3)),
                ]),
              ),
              Icon(Icons.arrow_forward_ios, color: titleColor.withOpacity(0.6), size: 14),
            ]),
          ),
        ),
      ),
    );
  }
}