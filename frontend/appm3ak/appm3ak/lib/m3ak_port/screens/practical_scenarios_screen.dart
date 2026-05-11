import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'gesture_illustrations.dart';
import 'package:video_player/video_player.dart';

class PracticalScenariosScreen extends StatelessWidget {
  const PracticalScenariosScreen({super.key});

  static final List<Map<String, dynamic>> scenarios = [
    {
      'title': 'À l\'hôpital',
      'subtitle': 'Consulter un médecin, décrire une douleur',
      'icon': Icons.local_hospital,
      'color': Color(0xFFE53935),
      'difficulty': 'Intermédiaire',
      'duration': '10 min',
      'steps': [
        {
          'title': 'Exprimer la douleur',
          'instruction': 'Montrez le geste "Douleur" : deux index pointés l\'un vers l\'autre, puis vers la zone douloureuse.',
          'emoji': '😣',
          'tip': 'Accompagnez d\'une expression du visage pour renforcer le message.',
        },
        {
          'title': 'Demander un médecin',
          'instruction': 'Geste "Médecin" : lettre M en langue des signes contre votre poignet (simuler la prise de pouls).',
          'emoji': '👨‍⚕️',
          'tip': 'Ce geste est universel dans les contextes médicaux.',
        },
        {
          'title': 'Indiquer la zone douloureuse',
          'instruction': 'Pointez directement la zone concernée, puis faites le geste de douleur (grimace + index croisés).',
          'emoji': '🩹',
          'tip': 'Soyez précis : ventre, tête, jambe... pointez clairement.',
        },
        {
          'title': 'Évaluer la douleur',
          'instruction': 'Montrez 1 à 10 doigts pour indiquer l\'intensité. 10 doigts = douleur maximale.',
          'emoji': '🔢',
          'tip': 'Les soignants comprennent universellement l\'échelle numérique des doigts.',
        },
        {
          'title': 'Demander de l\'aide',
          'instruction': 'Geste "Au secours" : les deux bras levés et agités ou poing frappé sur la paume.',
          'emoji': '🆘',
          'tip': 'En urgence, agitez les deux bras vigoureusement pour attirer l\'attention.',
        },
      ],
    },
    {
      'title': 'Dans le transport',
      'subtitle': 'Bus, métro, taxi — acheter un billet',
      'icon': Icons.directions_bus,
      'color': Color(0xFF1976D2),
      'difficulty': 'Débutant',
      'duration': '8 min',
      'steps': [
        {
          'title': 'Arrêter un taxi',
          'instruction': 'Bras tendu vers le haut, paume ouverte — geste universel pour héler un taxi.',
          'emoji': '🚕',
          'tip': 'Maintenez le bras levé jusqu\'à ce que le véhicule s\'arrête.',
        },
        {
          'title': 'Demander le bus',
          'instruction': 'Geste "Bus" : deux mains formant un volant, puis pointer vers l\'avant — "je prends le bus".',
          'emoji': '🚌',
          'tip': 'Accompagnez du geste de monter (index vers le haut) pour indiquer l\'embarquement.',
        },
        {
          'title': 'Acheter un billet',
          'instruction': 'Simulez tenir un billet entre pouce et index (ticket), puis faire le geste de donner de l\'argent.',
          'emoji': '🎫',
          'tip': 'Montrez aussi l\'argent (frotter pouce et index) pour indiquer le paiement.',
        },
        {
          'title': 'Demander l\'arrêt',
          'instruction': 'Geste "Arrêt" : paume ouverte vers l\'avant, bras à hauteur de poitrine. Puis pointer vers l\'extérieur.',
          'emoji': '🛑',
          'tip': 'Faites ce geste au chauffeur environ 2 arrêts avant votre destination.',
        },
        {
          'title': 'Demander de l\'aide',
          'instruction': 'Pointer vers vous + geste d\'incompréhension (mains ouvertes, sourcils levés) = "Pouvez-vous m\'aider ?"',
          'emoji': '🤝',
          'tip': 'L\'expression du visage interrogative est essentielle pour exprimer le besoin d\'aide.',
        },
      ],
    },
    {
      'title': 'Urgence',
      'subtitle': 'Appeler au secours, décrire la situation',
      'icon': Icons.emergency,
      'color': Color(0xFFFF6F00),
      'difficulty': 'Avancé',
      'duration': '15 min',
      'steps': [
        {
          'title': 'Signer "Au secours !"',
          'instruction': 'Les deux bras levés au-dessus de la tête, agités vigoureusement de gauche à droite.',
          'emoji': '🆘',
          'tip': 'C\'est le geste d\'urgence universel — visible de loin.',
        },
        {
          'title': 'Indiquer le type d\'urgence',
          'instruction': 'Feu = mains qui s\'agitent vers le haut. Accident = mimez un choc. Maladie = pointez votre corps.',
          'emoji': '⚠️',
          'tip': 'Exagérez les mimiques pour être compris rapidement dans une situation stressante.',
        },
        {
          'title': 'Appeler le 15 / 190',
          'instruction': 'Mimez un téléphone (pouce + auriculaire) puis montrez le chiffre 1 puis 5 avec les doigts.',
          'emoji': '📞',
          'tip': 'En Tunisie : 190 (SAMU), 197 (Police), 198 (Pompiers) — mémorisez ces chiffres.',
        },
        {
          'title': 'Donner votre localisation',
          'instruction': 'Index pointé vers le sol = "ici". Puis mimez des bâtiments ou une rue avec les deux mains.',
          'emoji': '📍',
          'tip': 'Si possible, montrez votre téléphone avec GPS activé pour partager votre position exacte.',
        },
        {
          'title': 'Interagir avec les secouristes',
          'instruction': 'Hochements de tête = Oui. Tête gauche-droite = Non. Pointer = Là-bas/Ici. Paume = Stop.',
          'emoji': '🚑',
          'tip': 'Restez calme et utilisez des gestes simples et clairs.',
        },
      ],
    },
    {
      'title': 'À la pharmacie',
      'subtitle': 'Demander un médicament, expliquer un symptôme',
      'icon': Icons.local_pharmacy,
      'color': Color(0xFF9C27B0),
      'difficulty': 'Débutant',
      'duration': '7 min',
      'steps': [
        {
          'title': 'Demander un médicament',
          'instruction': 'Geste "Médicament" : pouce et index formant un cercle (pilule), mouvement vers la bouche.',
          'emoji': '💊',
          'tip': 'Montrez l\'ordonnance si vous en avez une — c\'est le plus simple.',
        },
        {
          'title': 'Expliquer vos symptômes',
          'instruction': 'Pointez la zone du corps concernée + geste de douleur. Fièvre = main sur le front.',
          'emoji': '🤒',
          'tip': 'Combinez le geste corporel + expression du visage pour plus de clarté.',
        },
        {
          'title': 'Comprendre la posologie',
          'instruction': 'Montrez des doigts pour le nombre de prises, puis mimez manger (matin) ou dormir (soir).',
          'emoji': '⏰',
          'tip': 'Montrez 1 doigt = 1 fois par jour, 2 doigts = 2 fois... Simple et universel.',
        },
        {
          'title': 'Demander une ordonnance',
          'instruction': 'Mimez écrire sur un papier + tendre ce papier imaginaire = demander une prescription.',
          'emoji': '📋',
          'tip': 'Vous pouvez aussi montrer votre téléphone avec une photo de l\'emballage du médicament.',
        },
        {
          'title': 'Payer et remercier',
          'instruction': 'Geste de paiement (frotter pouce-index), puis geste "Merci" : main plate depuis les lèvres vers l\'avant.',
          'emoji': '🙏',
          'tip': 'Terminez toujours par un signe de remerciement — universellement compris.',
        },
      ],
    },
  ];

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
        title: const Text(
          'Scénarios pratiques',
          style: TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header banner — clickable intro
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6F00), Color(0xFFFF8F00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.play_circle_filled, color: Colors.white, size: 26),
                      SizedBox(width: 10),
                      Text('Simulations réelles',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Chaque scénario vous apprend les gestes essentiels pour communiquer dans des situations réelles.',
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            const Text('Choisissez un scénario',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
            const SizedBox(height: 4),
            Text('Appuyez pour commencer la simulation',
                style: TextStyle(color: Colors.grey[500], fontSize: 13)),

            const SizedBox(height: 16),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: scenarios.length,
              itemBuilder: (context, index) {
                final scenario = scenarios[index];
                final color = scenario['color'] as Color;
                final steps = scenario['steps'] as List;

                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ScenarioSimulationScreen(scenario: scenario),
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.07),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                    color: color.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12)),
                                child: Icon(scenario['icon'] as IconData, color: color, size: 26),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(scenario['title'] as String,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Color(0xFF1A1A2E))),
                                    const SizedBox(height: 3),
                                    Text(scenario['subtitle'] as String,
                                        style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                  ],
                                ),
                              ),
                              // Play button — clearly tappable
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                    color: color, shape: BoxShape.circle),
                                child: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              _Chip(icon: Icons.bar_chart, label: scenario['difficulty'] as String, color: color),
                              const SizedBox(width: 8),
                              _Chip(icon: Icons.timer, label: scenario['duration'] as String, color: color),
                              const Spacer(),
                              Icon(Icons.sign_language, color: color, size: 14),
                              const SizedBox(width: 4),
                              Text('${steps.length} gestes',
                                  style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Chip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// =====================================================================
// SIMULATION SCREEN — Step by step with gestures to learn
// =====================================================================
class ScenarioSimulationScreen extends StatefulWidget {
  final Map<String, dynamic> scenario;
  const ScenarioSimulationScreen({super.key, required this.scenario});

  @override
  State<ScenarioSimulationScreen> createState() => _ScenarioSimulationScreenState();
}

class _ScenarioSimulationScreenState extends State<ScenarioSimulationScreen>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  bool _practiced = false;
  bool _miniVideoPlaying = true;
  int _miniVideoFrame = 0;
  Timer? _miniVideoTimer;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat(reverse: true);
    _bounceAnim = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
    _startMiniVideoLoop();
  }

  @override
  void dispose() {
    _miniVideoTimer?.cancel();
    _bounceController.dispose();
    super.dispose();
  }

  void _startMiniVideoLoop() {
    _miniVideoTimer?.cancel();
    _miniVideoTimer = Timer.periodic(const Duration(milliseconds: 650), (_) {
      if (!mounted || !_miniVideoPlaying) return;
      setState(() {
        _miniVideoFrame = (_miniVideoFrame + 1) % 3;
      });
    });
  }

  void _toggleMiniVideo() {
    setState(() {
      _miniVideoPlaying = !_miniVideoPlaying;
    });
  }

  void _resetMiniVideo() {
    setState(() {
      _miniVideoFrame = 0;
      _miniVideoPlaying = true;
    });
  }

  String? _inferGestureName(Map<String, dynamic> step) {
    final text = '${step['title']} ${step['instruction']}'.toString().toLowerCase();
    if (text.contains('au secours')) return 'Au secours';
    if (text.contains('médecin') || text.contains('medecin')) return 'Médecin';
    if (text.contains('douleur')) return 'Douleur';
    if (text.contains('ambulance')) return 'Ambulance';
    if (text.contains('urgence')) return 'Urgence';
    if (text.contains('taxi')) return 'Taxi';
    if (text.contains('bus')) return 'Bus';
    if (text.contains('billet') || text.contains('ticket')) return 'Billet';
    if (text.contains('arrêt') || text.contains('arret')) return 'Arrêt';
    if (text.contains('gare')) return 'Gare';
    if (text.contains('infirmier')) return 'Infirmier';
    if (text.contains('médicament') || text.contains('medicament')) return 'Médicament';
    if (text.contains('rendez-vous') || text.contains('ordonnance')) return 'Rendez-vous';
    if (text.contains('opération') || text.contains('operation')) return 'Opération';
    if (text.contains('merci')) return 'Merci';
    if (text.contains('bonjour')) return 'Bonjour';
    return null;
  }

  String? _gestureVideoAssetFor(String gestureName) {
    switch (gestureName.toLowerCase()) {
      case 'au secours':
        return 'assets/videos/gestures/au_secours.mp4';
      case 'médecin':
        return 'assets/videos/gestures/medecin.mp4';
      case 'douleur':
        return 'assets/videos/gestures/douleur.mp4';
      case 'ambulance':
        return 'assets/videos/gestures/ambulance.mp4';
      case 'urgence':
        return 'assets/videos/gestures/urgence.mp4';
      case 'taxi':
        return 'assets/videos/gestures/taxi.mp4';
      case 'bus':
        return 'assets/videos/gestures/bus.mp4';
      case 'billet':
        return 'assets/videos/gestures/billet.mp4';
      case 'arrêt':
        return 'assets/videos/gestures/arret.mp4';
      case 'gare':
        return 'assets/videos/gestures/gare.mp4';
      case 'infirmier':
        return 'assets/videos/gestures/infirmier.mp4';
      case 'médicament':
        return 'assets/videos/gestures/medicament.mp4';
      case 'rendez-vous':
        return 'assets/videos/gestures/rendez_vous.mp4';
      case 'opération':
        return 'assets/videos/gestures/operation.mp4';
      case 'merci':
        return 'assets/videos/gestures/merci.mp4';
      case 'bonjour':
        return 'assets/videos/gestures/bonjour.mp4';
      default:
        return null;
    }
  }

  Widget _buildMiniVideoCard(Map<String, dynamic> step, Color color) {
    final gestureName = _inferGestureName(step);
    if (gestureName == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: color, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Mini video non disponible pour ce geste. Suivez les instructions et le tip.',
                style: TextStyle(color: Colors.grey[700], fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    final assetPath = _gestureVideoAssetFor(gestureName);
    if (assetPath == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.ondemand_video, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Video reelle du geste: $gestureName',
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _GestureAssetVideoPlayer(
            key: ValueKey(assetPath),
            assetPath: assetPath,
            color: color,
            gestureName: gestureName,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final steps = widget.scenario['steps'] as List<Map<String, dynamic>>;
    final color = widget.scenario['color'] as Color;
    final step = steps[_currentStep];

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF1A1A2E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.scenario['title'] as String,
            style: const TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text('${_currentStep + 1}/${steps.length}',
                style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (_currentStep + 1) / steps.length,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 20),

            // Step indicator row
            Row(
              children: List.generate(steps.length, (i) => Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _currentStep = i;
                    _practiced = false;
                    _miniVideoFrame = 0;
                  }),
                  child: Container(
                    margin: EdgeInsets.only(right: i < steps.length - 1 ? 4 : 0),
                    height: 36,
                    decoration: BoxDecoration(
                      color: i < _currentStep
                          ? color
                          : i == _currentStep
                          ? color
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: i < _currentStep
                          ? const Icon(Icons.check, color: Colors.white, size: 14)
                          : Text('${i + 1}',
                          style: TextStyle(
                              color: i == _currentStep ? Colors.white : Colors.grey[600],
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                    ),
                  ),
                ),
              )),
            ),

            const SizedBox(height: 20),

            // Main step card — scrollable content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Gesture display card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20)
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildMiniVideoCard(step, color),
                          const SizedBox(height: 14),
                          // Animated emoji
                          AnimatedBuilder(
                            animation: _bounceAnim,
                            builder: (context, child) => Transform.translate(
                              offset: Offset(0, _bounceAnim.value),
                              child: child,
                            ),
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.08),
                                shape: BoxShape.circle,
                                border: Border.all(color: color.withOpacity(0.2), width: 3),
                              ),
                              child: Center(
                                child: Text(step['emoji'] as String,
                                    style: const TextStyle(fontSize: 65)),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          Text(
                            step['title'] as String,
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
                          ),

                          const SizedBox(height: 16),

                          // Instruction box
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: color.withOpacity(0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.sign_language, color: color, size: 16),
                                    const SizedBox(width: 8),
                                    Text('Geste à effectuer :',
                                        style: TextStyle(
                                            color: color,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13)),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  step['instruction'] as String,
                                  style: TextStyle(
                                      color: Colors.grey[700], fontSize: 14, height: 1.5),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Tip box
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.amber.withOpacity(0.3)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.lightbulb, color: Colors.amber, size: 16),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    step['tip'] as String,
                                    style: TextStyle(
                                        color: Colors.grey[700], fontSize: 13, height: 1.4),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (_practiced) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green, size: 18),
                                  SizedBox(width: 8),
                                  Text('Geste pratiqué ✓',
                                      style: TextStyle(
                                          color: Colors.green, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      setState(() => _practiced = true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('✅ Geste enregistré — Bien joué !'),
                          backgroundColor: color,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('J\'ai pratiqué'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color.withOpacity(0.1),
                      foregroundColor: color,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      if (_currentStep < steps.length - 1) {
                        setState(() {
                          _currentStep++;
                          _practiced = false;
                        _miniVideoFrame = 0;
                        });
                      } else {
                        _showCompletion(context, color);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      _currentStep < steps.length - 1 ? 'Suivant →' : '🎉 Terminer',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCompletion(BuildContext context, Color color) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎊', style: TextStyle(fontSize: 70)),
            const SizedBox(height: 16),
            const Text('Scénario terminé !',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Vous avez appris tous les gestes pour "${widget.scenario['title']}" avec succès !',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, height: 1.4),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star, color: color, size: 20),
                  const SizedBox(width: 8),
                  Text('Scénario maîtrisé',
                      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Retour aux scénarios', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _GestureAssetVideoPlayer extends StatefulWidget {
  const _GestureAssetVideoPlayer({
    super.key,
    required this.assetPath,
    required this.color,
    required this.gestureName,
  });

  final String assetPath;
  final Color color;
  final String gestureName;

  @override
  State<_GestureAssetVideoPlayer> createState() => _GestureAssetVideoPlayerState();
}

class _GestureAssetVideoPlayerState extends State<_GestureAssetVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      final controller = VideoPlayerController.asset(widget.assetPath);
      await controller.initialize();
      await controller.setLooping(true);
      await controller.play();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _isLoading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Video non trouvee: ${widget.assetPath}';
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        width: double.infinity,
        height: 170,
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _controller == null) {
      return _FallbackAnimatedGesturePlayer(
        gestureName: widget.gestureName,
        color: widget.color,
      );
    }

    final controller = _controller!;
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio == 0 ? 16 / 9 : controller.value.aspectRatio,
            child: VideoPlayer(controller),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              onPressed: () async {
                if (!controller.value.isInitialized) return;
                if (controller.value.isPlaying) {
                  await controller.pause();
                } else {
                  await controller.play();
                }
                if (mounted) setState(() {});
              },
              icon: Icon(
                controller.value.isPlaying ? Icons.pause_circle : Icons.play_circle,
                color: widget.color,
              ),
            ),
            TextButton.icon(
              onPressed: () async {
                await controller.seekTo(Duration.zero);
                await controller.play();
                if (mounted) setState(() {});
              },
              icon: const Icon(Icons.replay, size: 16),
              label: const Text('Rejouer'),
            ),
          ],
        ),
      ],
    );
  }
}

class _FallbackAnimatedGesturePlayer extends StatefulWidget {
  const _FallbackAnimatedGesturePlayer({
    required this.gestureName,
    required this.color,
  });

  final String gestureName;
  final Color color;

  @override
  State<_FallbackAnimatedGesturePlayer> createState() =>
      _FallbackAnimatedGesturePlayerState();
}

class _FallbackAnimatedGesturePlayerState
    extends State<_FallbackAnimatedGesturePlayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 170,
      decoration: BoxDecoration(
        color: widget.color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: AnimatedBuilder(
        animation: _floatAnimation,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: child,
        ),
        child: Center(
          child: GestureIllustration(
            gestureName: widget.gestureName,
            color: widget.color,
            size: 110,
          ),
        ),
      ),
    );
  }
}