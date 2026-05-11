import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:appm3ak/m3ak_port/services/vibration_manager.dart';

class AssistiveCommunicationScreen extends StatefulWidget {
  const AssistiveCommunicationScreen({super.key});

  @override
  State<AssistiveCommunicationScreen> createState() =>
      _AssistiveCommunicationScreenState();
}

class _AssistiveCommunicationScreenState
    extends State<AssistiveCommunicationScreen> {
  final FlutterTts _tts = FlutterTts();
  final VibrationManager _vibration = VibrationManager();
  final TextEditingController _customController = TextEditingController();

  static const List<_QuickPhrase> _phrases = [
    _QuickPhrase(
      label: 'Aide immédiate',
      phrase: 'J ai besoin d aide, s il vous plait.',
      icon: Icons.support_agent,
      color: Color(0xFFE53935),
    ),
    _QuickPhrase(
      label: 'Urgence médicale',
      phrase: 'Urgence medicale. Appelez un medecin maintenant.',
      icon: Icons.local_hospital,
      color: Color(0xFFD32F2F),
    ),
    _QuickPhrase(
      label: 'Douleur',
      phrase: 'J ai une douleur forte. Aidez moi s il vous plait.',
      icon: Icons.healing,
      color: Color(0xFFFB8C00),
    ),
    _QuickPhrase(
      label: 'Transport',
      phrase: 'Pouvez vous m aider pour le transport ?',
      icon: Icons.directions_bus,
      color: Color(0xFF1976D2),
    ),
    _QuickPhrase(
      label: 'Appeler famille',
      phrase: 'Merci d appeler ma famille, s il vous plait.',
      icon: Icons.call,
      color: Color(0xFF6A1B9A),
    ),
    _QuickPhrase(
      label: 'Merci',
      phrase: 'Merci pour votre aide.',
      icon: Icons.favorite,
      color: Color(0xFF2E7D32),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('fr-FR');
      await _tts.setSpeechRate(0.46);
      await _tts.setPitch(1.0);
      await _tts.speak(
        'Assistant vocal actif. Touchez un bouton pour parler. Appui long pour repetition.',
      );
    } catch (_) {}
  }

  Future<void> _speak(String text, {bool repeat = false}) async {
    if (text.trim().isEmpty) return;
    try {
      await _vibration.vibrateSuccess();
      await _tts.stop();
      await Future.delayed(const Duration(milliseconds: 100)); // Petit délai pour éviter les conflits
      await _tts.speak(text);
      if (repeat) {
        await Future.delayed(const Duration(milliseconds: 450));
        await _tts.speak(text);
      }
    } catch (e) {
      // Ignorer les erreurs TTS pour garder l'UI responsive
      print('TTS Error: $e');
    }
  }

  Future<void> _readAllOptions() async {
    try {
      await _tts.stop();
      await Future.delayed(const Duration(milliseconds: 100));
      await _vibration.vibrateSuccess();
      await _tts.speak(
        'Options disponibles. 1 aide immediate. 2 urgence medicale. 3 douleur. 4 transport. 5 appeler famille. 6 merci.',
      );
    } catch (e) {
      // Ignorer les erreurs TTS
      print('TTS Error: $e');
    }
  }

  @override
  void dispose() {
    _tts.stop();
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A2E)),
        title: const Text(
          'Assistant Vocal & Urgence',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _readAllOptions,
            icon: const Icon(Icons.record_voice_over),
            tooltip: 'Lire toutes les options',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF111827), Color(0xFF1F2937)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Utilisation rapide:\n• Touchez un bouton pour parler a haute voix.\n• Appui long pour repetition forte.\n• L icone micro lit toutes les options pour le mode non-voyant.',
                style: TextStyle(color: Colors.white, height: 1.35),
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              itemCount: _phrases.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.25,
              ),
              itemBuilder: (_, i) {
                final item = _phrases[i];
                return GestureDetector(
                  onTap: () => _speak(item.phrase),
                  onLongPress: () => _speak(item.phrase, repeat: true),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: item.color,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: item.color.withValues(alpha: 0.30),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(item.icon, color: Colors.white, size: 26),
                        const Spacer(),
                        Text(
                          item.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Touchez pour parler',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black.withValues(alpha: 0.07)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Phrase personnalisée',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _customController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Ex: Je ne peux pas parler, merci de m aider.',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _speak(_customController.text, repeat: true),
                      icon: const Icon(Icons.volume_up),
                      label: const Text('Parler la phrase'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickPhrase {
  final String label;
  final String phrase;
  final IconData icon;
  final Color color;

  const _QuickPhrase({
    required this.label,
    required this.phrase,
    required this.icon,
    required this.color,
  });
}

