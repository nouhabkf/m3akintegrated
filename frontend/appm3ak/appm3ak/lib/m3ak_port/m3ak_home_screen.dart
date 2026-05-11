import 'dart:async';

import 'package:flutter/material.dart';
import 'package:appm3ak/m3ak_port/services/voice_command_service.dart';
import 'package:appm3ak/m3ak_port/screens/learning_center_screen.dart';
import 'package:appm3ak/m3ak_port/screens/sign_language_screen.dart';
import 'package:appm3ak/m3ak_port/screens/practical_scenarios_screen.dart';
import 'package:appm3ak/m3ak_port/screens/converter_screen.dart';
import 'package:appm3ak/m3ak_port/screens/daily_challenge_screen.dart';
import 'package:appm3ak/m3ak_port/screens/sign_chatbot_screen.dart';
import 'package:appm3ak/m3ak_port/screens/sign_phrase_ai_screen.dart';
import 'package:appm3ak/m3ak_port/screens/assistive_communication_screen.dart';
import 'package:appm3ak/m3ak_port/screens/face_recognition_screen.dart';
import 'package:appm3ak/m3ak_port/services/api_service.dart';

/// Hub M3AK (Braille, LSF, visage…) — intégré dans l’app Ma3ak.
class M3akHomeScreen extends StatefulWidget {
  const M3akHomeScreen({super.key});

  @override
  State<M3akHomeScreen> createState() => _M3akHomeScreenState();
}

class _M3akHomeScreenState extends State<M3akHomeScreen> {
  final VoiceCommandService _voiceService = VoiceCommandService();
  bool _voiceInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVoiceCommands();
  }

  Future<void> _initializeVoiceCommands() async {
    try {
      final initialized = await _voiceService.initialize();
      if (initialized && mounted) {
        setState(() => _voiceInitialized = true);
        _startVoiceListening();
      }
    } catch (_) {}
  }

  void _startVoiceListening() {
    _voiceService.startListening(_onHomeVoiceCommand);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() {});
    });
  }

  Future<void> _onHomeVoiceCommand(String command) async {
    if (!mounted) return;

    if (command == 'open_chatbot') {
      await _voiceService.stopListening();
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SignChatbotScreen()),
      );
      if (mounted) _startVoiceListening();
      return;
    }

    if (command == 'open_face_recognition') {
      await _voiceService.stopListening();
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const FaceRecognitionScreen()),
      );
      if (mounted) _startVoiceListening();
    }
  }

  @override
  void dispose() {
    _voiceService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        tooltip: 'IA Chat Signes',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SignChatbotScreen()),
          );
        },
        child: const Icon(Icons.forum),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_voiceInitialized)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.shade200, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _voiceService.isListening ? Icons.mic : Icons.mic_none,
                          size: 14,
                          color: _voiceService.isListening ? Colors.green.shade700 : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _voiceService.isListening
                                ? 'Écoute active - Dites "ouvrir chatbot" ou "open chat"'
                                : 'Écoute inactive - Cliquez pour redémarrer',
                            style: TextStyle(
                              fontSize: 11,
                              color: _voiceService.isListening ? Colors.green.shade700 : Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            _startVoiceListening();
                            if (mounted) setState(() {});
                          },
                          child: Icon(Icons.refresh, size: 14, color: Colors.green.shade700),
                        ),
                      ],
                    ),
                  ),
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.accessibility_new,
                          size: 60,
                          color: Color(0xFF2196F3),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'M3AK',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Inclusion & Communication Accessible',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                _buildModuleCard(
                  context,
                  icon: Icons.menu_book,
                  title: 'Apprentissage Braille',
                  description:
                      'Apprenez le Braille à votre rythme avec des exercices adaptés par IA',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LearningCenterScreen()),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildModuleCard(
                  context,
                  icon: Icons.pan_tool,
                  title: 'Langue des signes',
                  description:
                      'Cours interactifs avec reconnaissance gestuelle en temps réel',
                  color: Colors.green,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignLanguageScreen()),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildModuleCard(
                  context,
                  icon: Icons.emergency,
                  title: 'Scénarios pratiques',
                  description:
                      'Simulations de situations réelles (hôpital, transport, urgence)',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PracticalScenariosScreen()),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildModuleCard(
                  context,
                  icon: Icons.emoji_events,
                  title: 'Challenge quotidien',
                  description: 'Questions adaptées par modèle IA · Niveau 1',
                  color: Colors.purple,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DailyChallengeScreen(
                          userId: '1',
                          initialLevel: 1,
                          apiService: context.apiService,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildModuleCard(
                  context,
                  icon: Icons.swap_horiz,
                  title: 'Convertisseur Braille',
                  description:
                      'Traduisez instantanément vos textes en Braille et vice-versa',
                  color: Colors.teal,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ConverterScreen()),
                    );
                  },
                ),
                _buildModuleCard(
                  context,
                  icon: Icons.auto_awesome,
                  title: 'IA Traducteur Signes',
                  description: 'Traduit texte vers signes et signes vers texte',
                  color: const Color(0xFF2563EB),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignPhraseAiScreen()),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildModuleCard(
                  context,
                  icon: Icons.record_voice_over,
                  title: 'Assistant Vocal & Urgence',
                  description: 'Parler rapidement avec gros boutons, voix et vibration',
                  color: const Color(0xFF111827),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AssistiveCommunicationScreen()),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildModuleCard(
                  context,
                  icon: Icons.face,
                  title: 'M3AK Visage',
                  description: 'Reconnaissance faciale vocale pour personnes non-voyantes',
                  color: const Color(0xFF9C27B0),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FaceRecognitionScreen()),
                    );
                  },
                ),
                const SizedBox(height: 30),
                Center(
                  child: Text(
                    '🇹🇳 Pour une Tunisie inclusive 🇹🇳',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModuleCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: color,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
