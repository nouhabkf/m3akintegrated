import 'package:flutter/material.dart';
import 'package:appm3ak/m3ak_port/models/sign_phrase_analysis.dart';
import 'package:appm3ak/m3ak_port/screens/gesture_illustrations.dart';
import 'package:appm3ak/m3ak_port/services/sign_phrase_ai_service.dart';
import 'package:video_player/video_player.dart';

class SignPhraseAiScreen extends StatefulWidget {
  const SignPhraseAiScreen({super.key});

  @override
  State<SignPhraseAiScreen> createState() => _SignPhraseAiScreenState();
}

class _SignPhraseAiScreenState extends State<SignPhraseAiScreen> {
  final SignPhraseAiService _service = const SignPhraseAiService();
  final TextEditingController _textToSignsController = TextEditingController();
  final TextEditingController _signsToTextController = TextEditingController();
  SignPhraseAnalysis _textToSignsAnalysis = const SignPhraseAnalysis(
    normalizedText: '',
    translatedText: '',
    detectedContext: 'Aucun',
    confidence: 0,
    gestures: [],
    tips: ['Ecris une phrase pour obtenir une proposition de gestes.'],
  );
  SignPhraseAnalysis _signsToTextAnalysis = const SignPhraseAnalysis(
    normalizedText: '',
    translatedText: '',
    detectedContext: 'Aucun',
    confidence: 0,
    gestures: [],
    tips: ['Ecris des gestes separes par virgule: Bonjour, Merci, Medecin'],
  );

  void _runTextToSigns() {
    setState(() {
      _textToSignsAnalysis = _service.analyzeTextToSigns(_textToSignsController.text);
    });
  }

  void _runSignsToText() {
    setState(() {
      _signsToTextAnalysis = _service.analyzeSignsToText(_signsToTextController.text);
    });
  }

  @override
  void dispose() {
    _textToSignsController.dispose();
    _signsToTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F4FF),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Color(0xFF1A1A2E)),
          title: const Text(
            'IA Traducteur Signes',
            style: TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Texte → Signes'),
              Tab(text: 'Signes → Texte'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTextToSignsTab(),
            _buildSignsToTextTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextToSignsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBanner(
            'Ecris une phrase en francais. L IA propose comment la dire en langue des signes.',
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _textToSignsController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Ex: Je cherche un medecin, j ai mal...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _runTextToSigns,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Traduire en signes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _buildAnalysisCard(
            analysis: _textToSignsAnalysis,
            translationTitle: 'Proposition de phrase en signes',
          ),
        ],
      ),
    );
  }

  Widget _buildSignsToTextTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBanner(
            'Ecris les gestes separes par virgule et l IA te donne la phrase en texte.',
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _signsToTextController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Ex: Bonjour, Medecin, Douleur, Au secours',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _runSignsToText,
              icon: const Icon(Icons.translate),
              label: const Text('Traduire en texte'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _buildAnalysisCard(
            analysis: _signsToTextAnalysis,
            translationTitle: 'Phrase traduite en texte',
          ),
        ],
      ),
    );
  }

  Widget _buildBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Colors.white, height: 1.35, fontSize: 13),
      ),
    );
  }

  Widget _buildAnalysisCard({
    required SignPhraseAnalysis analysis,
    required String translationTitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip('Contexte: ${analysis.detectedContext}', const Color(0xFF0EA5E9)),
              _chip('Confiance: ${analysis.confidence}%', const Color(0xFF16A34A)),
            ],
          ),
          const SizedBox(height: 10),
          if (analysis.normalizedText.isNotEmpty) ...[
            const Text('Entree normalisee', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(analysis.normalizedText),
            const SizedBox(height: 10),
          ],
          Text(translationTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            analysis.translatedText.isEmpty ? '-' : analysis.translatedText,
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 10),
          const Text('Sequence de gestes proposee', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (analysis.gestures.isEmpty)
            const Text('Aucune sequence disponible.')
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: analysis.gestures
                  .asMap()
                  .entries
                  .map((entry) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text('${entry.key + 1}. ${entry.value}'),
                      ))
                  .toList(),
            ),
          if (analysis.gestures.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'Illustrations des gestes',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildGestureVisualGrid(analysis.gestures),
          ],
          const SizedBox(height: 12),
          const Text('Conseils IA', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          ...analysis.tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.check_circle, size: 14, color: Color(0xFF16A34A)),
                  ),
                  const SizedBox(width: 7),
                  Expanded(child: Text(tip, style: const TextStyle(fontSize: 12))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGestureVisualGrid(List<String> gestures) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: gestures.map((gesture) {
        return Container(
          width: 145,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.18)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _gestureIcon(gesture),
                color: const Color(0xFF2563EB),
                size: 24,
              ),
              const SizedBox(height: 6),
              _GestureMediaPreview(
                gestureName: gesture,
                color: const Color(0xFF2563EB),
                size: 88,
              ),
              const SizedBox(height: 8),
              Text(
                gesture,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  IconData _gestureIcon(String gesture) {
    switch (gesture.toLowerCase()) {
      case 'bonjour':
        return Icons.waving_hand;
      case 'merci':
        return Icons.favorite;
      case 'au revoir':
        return Icons.waving_hand;
      case 'au secours':
      case 'urgence':
        return Icons.sos;
      case 'medecin':
      case 'médecin':
      case 'douleur':
      case 'ambulance':
        return Icons.local_hospital;
      case 'taxi':
        return Icons.local_taxi;
      case 'bus':
        return Icons.directions_bus;
      case 'arrêt':
      case 'arret':
        return Icons.do_not_disturb;
      case 'billet':
        return Icons.confirmation_num;
      default:
        return Icons.front_hand;
    }
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 11),
      ),
    );
  }
}

class _GestureMediaPreview extends StatefulWidget {
  const _GestureMediaPreview({
    required this.gestureName,
    required this.color,
    this.size = 88,
  });

  final String gestureName;
  final Color color;
  final double size;

  @override
  State<_GestureMediaPreview> createState() => _GestureMediaPreviewState();
}

class _GestureMediaPreviewState extends State<_GestureMediaPreview> {
  VideoPlayerController? _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBestVideo();
  }

  @override
  void didUpdateWidget(covariant _GestureMediaPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gestureName != widget.gestureName) {
      _loadBestVideo();
    }
  }

  String _normalize(String text) => text.trim().toLowerCase();

  String _stripAccents(String text) {
    return text
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('à', 'a')
        .replaceAll('ù', 'u')
        .replaceAll('ô', 'o')
        .replaceAll('ï', 'i')
        .replaceAll('ç', 'c');
  }

  List<String> _candidateAssets(String gestureName) {
    final key = _normalize(gestureName);
    final noAccent = _stripAccents(key).replaceAll(' ', '_').replaceAll('-', '_');
    return [
      'assets/videos/gestures/$noAccent.mp4',
      'assets/videos/$noAccent.mp4',
      'assets/videos/$noAccent.mp4.mp4',
    ];
  }

  Future<void> _loadBestVideo() async {
    setState(() {
      _isLoading = true;
    });
    await _controller?.dispose();
    _controller = null;

    for (final asset in _candidateAssets(widget.gestureName)) {
      try {
        final candidate = VideoPlayerController.asset(asset);
        await candidate.initialize();
        await candidate.setLooping(true);
        await candidate.setVolume(0);
        await candidate.play();
        if (!mounted) {
          await candidate.dispose();
          return;
        }
        setState(() {
          _controller = candidate;
          _isLoading = false;
        });
        return;
      } catch (_) {
        // Try next candidate path.
      }
    }

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return GestureIllustration(
        gestureName: widget.gestureName,
        color: widget.color,
        size: widget.size,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _controller!.value.size.width,
            height: _controller!.value.size.height,
            child: VideoPlayer(_controller!),
          ),
        ),
      ),
    );
  }
}

