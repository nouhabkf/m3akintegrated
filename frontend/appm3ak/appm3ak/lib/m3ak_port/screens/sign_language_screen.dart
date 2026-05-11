import 'package:flutter/material.dart';
import 'gesture_illustrations.dart';
import 'package:appm3ak/m3ak_port/screens/sign_camera_screen.dart';

class SignLanguageScreen extends StatelessWidget {
  const SignLanguageScreen({super.key});

  static final List<Map<String, dynamic>> lessons = [
    {
      'title': 'Les salutations',
      'description': 'Bonjour, Au revoir, Merci, S\'il vous plaît',
      'icon': Icons.waving_hand,
      'color': Color(0xFF4CAF50),
      'level': 'Débutant',
      'gestures': [
        {'name': 'Bonjour',         'description': 'Main ouverte, paume vers l\'avant. Mouvement de droite à gauche en partant du front.'},
        {'name': 'Au revoir',       'description': 'Main ouverte, agiter les doigts de haut en bas. Mouvement ample gauche-droite.'},
        {'name': 'Merci',           'description': 'Main plate contre les lèvres, puis avancer la main vers l\'interlocuteur.'},
        {'name': 'S\'il vous plaît','description': 'Deux mains ouvertes, paumes vers le haut, léger mouvement vers l\'avant.'},
        {'name': 'Excusez-moi',     'description': 'Main levée, paume vers l\'avant, près de la tête, petit mouvement latéral.'},
      ],
    },
    {
      'title': 'Situations d\'urgence',
      'description': 'Au secours, Médecin, Douleur, Ambulance',
      'icon': Icons.emergency,
      'color': Color(0xFFE53935),
      'level': 'Intermédiaire',
      'gestures': [
        {'name': 'Au secours', 'description': 'Les deux bras levés au-dessus de la tête, agités vigoureusement de gauche à droite.'},
        {'name': 'Médecin',    'description': 'Lettre M en langue des signes posée contre le poignet gauche (comme vérifier le pouls).'},
        {'name': 'Douleur',    'description': 'Deux index pointés l\'un vers l\'autre, tourner vers la zone douloureuse du corps.'},
        {'name': 'Ambulance',  'description': 'Deux doigts posés sur l\'avant-bras, puis main ouverte lancée vers l\'avant (urgence).'},
        {'name': 'Urgence',    'description': 'Poing fermé, mouvement répété vers le haut pour attirer l\'attention d\'urgence.'},
      ],
    },
    {
      'title': 'Transport',
      'description': 'Bus, Taxi, Gare, Billet, Arrêt',
      'icon': Icons.directions_bus,
      'color': Color(0xFF1976D2),
      'level': 'Débutant',
      'gestures': [
        {'name': 'Bus',    'description': 'Deux mains tenant un volant imaginaire, puis pointer vers l\'avant — "prendre le bus".'},
        {'name': 'Taxi',   'description': 'Bras tendu vers le haut, paume ouverte — geste universel pour héler un taxi.'},
        {'name': 'Gare',   'description': 'Deux index parallèles à l\'horizontal symbolisant des rails, puis mouvement vers l\'avant.'},
        {'name': 'Billet', 'description': 'Simuler tenir un billet entre pouce et index, puis le présenter vers l\'avant.'},
        {'name': 'Arrêt',  'description': 'Paume ouverte vers l\'avant, bras à hauteur de poitrine — geste STOP universel.'},
      ],
    },
    {
      'title': 'Hôpital',
      'description': 'Médecin, Infirmier, Médicament, Rendez-vous',
      'icon': Icons.local_hospital,
      'color': Color(0xFF9C27B0),
      'level': 'Avancé',
      'gestures': [
        {'name': 'Médecin',      'description': 'Lettre M contre poignet gauche — symbole de prise de pouls.'},
        {'name': 'Infirmier',    'description': 'Index traçant une croix médicale sur l\'avant-bras.'},
        {'name': 'Médicament',   'description': 'Pouce et index formant un cercle (pilule), mouvement vers la bouche.'},
        {'name': 'Rendez-vous',  'description': 'Index pointé, puis main plate imitant un agenda — notion de date planifiée.'},
        {'name': 'Opération',    'description': 'Index glissant le long de l\'avant-bras — mime d\'une incision chirurgicale.'},
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
          'Langue des signes',
          style: TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Camera banner
            GestureDetector(
              onTap: () => _openCameraDialog(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF4CAF50).withOpacity(0.35), blurRadius: 15, offset: const Offset(0, 5)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Reconnaissance en temps réel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          SizedBox(height: 4),
                          Text('Activez la caméra pour pratiquer', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                      child: const Text('Démarrer', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            const Text('Leçons disponibles', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
            const SizedBox(height: 14),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: lessons.length,
              itemBuilder: (context, index) {
                final lesson = lessons[index];
                final color = lesson['color'] as Color;
                return GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => LessonDetailScreen(lesson: lesson))),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                          child: Icon(lesson['icon'] as IconData, color: color, size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Text(lesson['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A1A2E))),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                                  child: Text(lesson['level'] as String, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
                                ),
                              ]),
                              const SizedBox(height: 4),
                              Text(lesson['description'] as String, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                              const SizedBox(height: 6),
                              Text('${(lesson['gestures'] as List).length} gestes avec illustrations',
                                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 14),
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

  void _openCameraDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SignCameraScreen()),
    );
  }
}

// =====================================================================
// CAMERA DIALOG — Interactive with gesture detection simulation
// =====================================================================
class _CameraDialog extends StatefulWidget {
  @override
  State<_CameraDialog> createState() => _CameraDialogState();
}

class _CameraDialogState extends State<_CameraDialog> with TickerProviderStateMixin {
  bool _isAnalyzing = false;
  String? _detectedGesture;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  final List<String> _sampleGestures = ['Bonjour', 'Merci', 'Au revoir', 'Au secours', 'Arrêt'];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this)..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.9, end: 1.0).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _simulateDetection() async {
    setState(() { _isAnalyzing = true; _detectedGesture = null; });
    await Future.delayed(const Duration(milliseconds: 1800));
    if (mounted) {
      setState(() {
        _isAnalyzing = false;
        _detectedGesture = (_sampleGestures..shuffle()).first;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF4CAF50).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.camera_alt, color: Color(0xFF4CAF50)),
              ),
              const SizedBox(width: 12),
              const Text('Reconnaissance gestuelle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            ]),
            const SizedBox(height: 18),

            // Viewfinder
            Container(
              height: 210,
              decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(16)),
              child: Stack(
                children: [
                  // Corner brackets
                  ...[Alignment.topLeft, Alignment.topRight, Alignment.bottomLeft, Alignment.bottomRight]
                      .map((a) => Positioned(
                    top: a == Alignment.topLeft || a == Alignment.topRight ? 12 : null,
                    bottom: a == Alignment.bottomLeft || a == Alignment.bottomRight ? 12 : null,
                    left: a == Alignment.topLeft || a == Alignment.bottomLeft ? 12 : null,
                    right: a == Alignment.topRight || a == Alignment.bottomRight ? 12 : null,
                    child: SizedBox(
                      width: 22, height: 22,
                      child: CustomPaint(painter: _CornerPainter(a)),
                    ),
                  )),

                  Center(
                    child: _isAnalyzing
                        ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      ScaleTransition(
                        scale: _pulseAnim,
                        child: Container(
                          width: 70, height: 70,
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF4CAF50), width: 3)),
                          child: const Icon(Icons.pan_tool, color: Colors.white54, size: 35),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('Analyse du geste...', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 8),
                      const CircularProgressIndicator(color: Color(0xFF4CAF50), strokeWidth: 2),
                    ])
                        : _detectedGesture != null
                        ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 48),
                      const SizedBox(height: 10),
                      Text('Geste détecté :', style: TextStyle(color: Colors.white60, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(_detectedGesture!, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    ])
                        : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.pan_tool, color: Colors.white30, size: 55),
                      const SizedBox(height: 10),
                      const Text('Positionnez votre main ici', style: TextStyle(color: Colors.white54, fontSize: 13)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.5)),
                        ),
                        child: const Text('En attente...', style: TextStyle(color: Color(0xFF4CAF50), fontSize: 12)),
                      ),
                    ]),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            if (_detectedGesture != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.star, color: Color(0xFF4CAF50), size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Excellent ! Geste "$_detectedGesture" reconnu avec succès !',
                      style: const TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.w600, fontSize: 13))),
                ]),
              )
            else
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.amber.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.amber.withOpacity(0.3))),
                child: const Row(children: [
                  Icon(Icons.info_outline, color: Colors.amber, size: 14),
                  SizedBox(width: 8),
                  Expanded(child: Text('Cliquez "Analyser" et montrez votre geste', style: TextStyle(color: Colors.amber, fontSize: 11))),
                ]),
              ),

            const SizedBox(height: 14),

            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF4CAF50)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: const Text('Fermer', style: TextStyle(color: Color(0xFF4CAF50))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isAnalyzing ? null : _simulateDetection,
                  icon: _isAnalyzing
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.search, size: 16),
                  label: Text(_isAnalyzing ? 'Analyse...' : 'Analyser'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Alignment alignment;
  _CornerPainter(this.alignment);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF4CAF50)..strokeWidth = 2.5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final isLeft = alignment == Alignment.topLeft || alignment == Alignment.bottomLeft;
    final isTop = alignment == Alignment.topLeft || alignment == Alignment.topRight;
    final startX = isLeft ? 0.0 : size.width;
    final startY = isTop ? 0.0 : size.height;
    canvas.drawLine(Offset(startX, startY), Offset(isLeft ? size.width : 0, startY), paint);
    canvas.drawLine(Offset(startX, startY), Offset(startX, isTop ? size.height : 0), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// =====================================================================
// LESSON DETAIL — With gesture illustrations (CustomPainter)
// =====================================================================
class LessonDetailScreen extends StatefulWidget {
  final Map<String, dynamic> lesson;
  const LessonDetailScreen({super.key, required this.lesson});

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> with SingleTickerProviderStateMixin {
  int _currentGesture = 0;
  bool _practiced = false;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(duration: const Duration(milliseconds: 900), vsync: this)..repeat(reverse: true);
    _bounceAnim = Tween<double>(begin: 0, end: -6).animate(CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gestures = widget.lesson['gestures'] as List<Map<String, dynamic>>;
    final color = widget.lesson['color'] as Color;
    final gesture = gestures[_currentGesture];

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1A1A2E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.lesson['title'] as String,
            style: const TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Progress
            Row(
              children: List.generate(gestures.length, (i) => Expanded(
                child: Container(
                  height: 6,
                  margin: EdgeInsets.only(right: i < gestures.length - 1 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: i <= _currentGesture ? color : Colors.grey[300],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              )),
            ),
            const SizedBox(height: 6),
            Text('Geste ${_currentGesture + 1} / ${gestures.length}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 18),

            // Main card
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20)],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // *** GESTURE ILLUSTRATION (CustomPainter) ***
                      AnimatedBuilder(
                        animation: _bounceAnim,
                        builder: (context, child) => Transform.translate(
                          offset: Offset(0, _bounceAnim.value),
                          child: child,
                        ),
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.06),
                            shape: BoxShape.circle,
                            border: Border.all(color: color.withOpacity(0.2), width: 3),
                          ),
                          child: Center(
                            child: GestureIllustration(
                              gestureName: gesture['name'] as String,
                              color: color,
                              size: 120,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Text(
                        gesture['name'] as String,
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
                      ),

                      const SizedBox(height: 16),

                      // Description
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
                            Row(children: [
                              Icon(Icons.sign_language, color: color, size: 16),
                              const SizedBox(width: 8),
                              Text('Comment faire ce geste :', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
                            ]),
                            const SizedBox(height: 10),
                            Text(gesture['description'] as String,
                                style: TextStyle(color: Colors.grey[700], fontSize: 14, height: 1.6)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Step indicators
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: color.withOpacity(0.04), borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Étapes :', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(height: 8),
                            ..._buildSteps(gesture['name'] as String, color),
                          ],
                        ),
                      ),

                      if (_practiced) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, color: Colors.green, size: 18),
                              SizedBox(width: 8),
                              Text('Geste pratiqué ✓', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Row(children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _practiced = true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('✅ Geste pratiqué !'),
                        backgroundColor: color,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.camera_alt, size: 16),
                  label: const Text('Pratiquer'),
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
                    if (_currentGesture < gestures.length - 1) {
                      setState(() { _currentGesture++; _practiced = false; });
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
                  child: Text(_currentGesture < gestures.length - 1 ? 'Suivant' : 'Terminer',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSteps(String gestureName, Color color) {
    final stepsMap = {
      'Bonjour': ['1. Levez la main droite, paume ouverte', '2. Approchez la main du front', '3. Déplacez vers l\'avant-droit'],
      'Au revoir': ['1. Main ouverte levée', '2. Agitez les doigts vers le bas', '3. Mouvement gauche-droite'],
      'Merci': ['1. Main plate, dos contre lèvres', '2. Avancez la main vers l\'avant', '3. Inclinez légèrement la tête'],
      "S'il vous plaît": ['1. Ouvrez les deux mains', '2. Paumes tournées vers le haut', '3. Avancez légèrement'],
      'Excusez-moi': ['1. Main levée, paume vers l\'avant', '2. Positionnez près de la tête', '3. Petit mouvement latéral'],
      'Au secours': ['1. Levez les deux bras', '2. Agitez vigoureusement', '3. Criez si possible'],
      'Médecin': ['1. Formez la lettre M (3 doigts)', '2. Posez sur poignet gauche', '3. Regardez votre interlocuteur'],
      'Douleur': ['1. Deux index pointés', '2. Approchez-les l\'un de l\'autre', '3. Tournez vers la zone'],
      'Bus': ['1. Deux mains en volant', '2. Tenez le cercle imaginaire', '3. Pointez vers l\'avant'],
      'Taxi': ['1. Tendez le bras droit', '2. Paume ouverte vers le haut', '3. Maintenez levé'],
      'Arrêt': ['1. Bras tendu en avant', '2. Paume ouverte face à l\'avant', '3. Restez immobile'],
    };
    final steps = stepsMap[gestureName] ?? ['1. Observez l\'illustration', '2. Reproduisez le geste', '3. Pratiquez avec la caméra'];
    return steps.map((step) => Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 6, height: 6, margin: const EdgeInsets.only(top: 6, right: 10), decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          Expanded(child: Text(step, style: TextStyle(color: Colors.grey[700], fontSize: 13))),
        ],
      ),
    )).toList();
  }

  void _showCompletion(BuildContext context, Color color) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 16),
            const Text('Leçon terminée !', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Vous avez appris tous les gestes de "${widget.lesson['title']}".',
                textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
          ],
        ),
        actions: [
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () { Navigator.pop(ctx); Navigator.pop(context); },
            style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
            child: const Text('Retour aux leçons'),
          )),
        ],
      ),
    );
  }
}