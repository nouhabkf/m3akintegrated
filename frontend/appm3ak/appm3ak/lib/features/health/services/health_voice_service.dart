import 'package:flutter_tts/flutter_tts.dart';

import 'health_voice_lang.dart';

/// Lecture vocale bilingue (fr-FR / en-US) pour l’assistant santé.
class HealthVoiceService {
  HealthVoiceService() : _tts = FlutterTts();

  final FlutterTts _tts;
  bool _ready = false;

  Future<void> ensureReady() async {
    if (_ready) return;
    await _tts.awaitSpeakCompletion(true);
    _ready = true;
  }

  Future<void> stop() async {
    await _tts.stop();
  }

  /// Retourne `false` si la synthèse vocale a échoué (fréquent sur le web).
  Future<bool> speak(String text, HealthVoiceLang lang) async {
    if (text.trim().isEmpty) return true;
    try {
      await ensureReady();
      await _tts.stop();
      await _tts.setLanguage(lang.ttsCode);
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.speak(text);
      return true;
    } catch (_) {
      return false;
    }
  }
}
