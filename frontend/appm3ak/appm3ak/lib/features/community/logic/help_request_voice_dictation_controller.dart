import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Phase d’interface pour la dictée (aperçu utilisateur, pas l’état brut du plugin).
enum HelpRequestVoicePhase {
  /// Initialisation ou jamais initialisé.
  uninitialized,

  /// Micro + STT prêts, pas d’écoute active.
  ready,

  /// Écoute en cours.
  listening,

  /// Écoute terminée avec du texte dans le champ (modifiable).
  recognized,

  /// Erreur bloquante ; l’utilisateur peut réessayer ([retry]).
  error,
}

bool _isBenignSttError(String msg) {
  switch (msg) {
    case 'error_speech_timeout':
    case 'error_no_match':
      return true;
    default:
      return false;
  }
}

/// Encapsule [speech_to_text] pour l’écran de demande d’aide (dictée → champ description).
///
/// Le texte court ou ambigu reste compatible avec l’envoi via préréglages + message builder serveur.
class HelpRequestVoiceDictationController extends ChangeNotifier {
  HelpRequestVoiceDictationController(this._description);

  final TextEditingController _description;
  final stt.SpeechToText _speech = stt.SpeechToText();

  HelpRequestVoicePhase phase = HelpRequestVoicePhase.uninitialized;
  String? errorCode;
  String localeId = 'fr_FR';
  bool _preferArabic = false;

  bool get isListening => _speech.isListening;

  /// À appeler une fois (ex. après le premier frame) avec la langue utilisateur.
  Future<void> init({required bool preferArabic}) async {
    _preferArabic = preferArabic;
    phase = HelpRequestVoicePhase.uninitialized;
    errorCode = null;
    notifyListeners();

    if (!kIsWeb) {
      final mic = await Permission.microphone.request();
      if (!mic.isGranted) {
        phase = HelpRequestVoicePhase.error;
        errorCode = 'microphone_denied';
        notifyListeners();
        return;
      }
    }

    final ok = await _speech.initialize(
      onError: _onSpeechError,
      onStatus: _onSpeechStatus,
    );

    if (!ok) {
      phase = HelpRequestVoicePhase.error;
      errorCode = 'init_failed';
      notifyListeners();
      return;
    }

    await _pickLocale(preferArabic);
    phase = HelpRequestVoicePhase.ready;
    notifyListeners();
  }

  Future<void> _pickLocale(bool preferArabic) async {
    try {
      final locales = await _speech.locales();
      if (locales.isEmpty) {
        localeId = preferArabic ? 'ar_SA' : 'fr_FR';
        return;
      }
      if (preferArabic) {
        final ar = locales.where(
          (l) => l.localeId.toLowerCase().startsWith('ar'),
        );
        localeId = ar.isNotEmpty ? ar.first.localeId : locales.first.localeId;
      } else {
        final fr = locales.where(
          (l) => l.localeId.toLowerCase().startsWith('fr'),
        );
        localeId = fr.isNotEmpty ? fr.first.localeId : locales.first.localeId;
      }
    } catch (_) {
      localeId = preferArabic ? 'ar_SA' : 'fr_FR';
    }
  }

  void _onSpeechError(SpeechRecognitionError e) {
    if (_isBenignSttError(e.errorMsg)) {
      if (_speech.isListening) return;
      _afterListenEnds();
      return;
    }
    unawaited(_speech.stop());
    phase = HelpRequestVoicePhase.error;
    errorCode = e.errorMsg;
    notifyListeners();
  }

  void _onSpeechStatus(String status) {
    if (kDebugMode) {
      debugPrint('[HelpRequestVoice] status=$status');
    }
    // Fin naturelle de session d’écoute.
    if ((status == 'done' || status == 'notListening') &&
        phase == HelpRequestVoicePhase.listening &&
        !_speech.isListening) {
      _afterListenEnds();
    }
    notifyListeners();
  }

  void _onResult(SpeechRecognitionResult result) {
    _description.text = result.recognizedWords;
    notifyListeners();
  }

  void _afterListenEnds() {
    final t = _description.text.trim();
    if (t.isEmpty) {
      phase = HelpRequestVoicePhase.ready;
    } else {
      phase = HelpRequestVoicePhase.recognized;
    }
    notifyListeners();
  }

  /// Démarre l’écoute, ou arrête si déjà en cours. Depuis [error], relance [init].
  Future<void> toggleListen() async {
    if (phase == HelpRequestVoicePhase.uninitialized) return;

    if (phase == HelpRequestVoicePhase.error) {
      await init(preferArabic: _preferArabic);
      return;
    }

    if (_speech.isListening) {
      await _speech.stop();
      _afterListenEnds();
      return;
    }

    phase = HelpRequestVoicePhase.listening;
    errorCode = null;
    notifyListeners();

    try {
      await _speech.listen(
        onResult: _onResult,
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 3),
        localeId: localeId,
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          cancelOnError: false,
          partialResults: true,
        ),
      );
    } catch (e) {
      phase = HelpRequestVoicePhase.error;
      errorCode = e.toString();
      notifyListeners();
    }
  }

  /// Réessaie après erreur (même flux que depuis l’état erreur).
  Future<void> retry() async {
    await init(preferArabic: _preferArabic);
  }

  /// Arrête l’écoute sans en relancer une (ex. changement de mode de saisie).
  Future<void> stopIfListening() async {
    if (!_speech.isListening) return;
    await _speech.stop();
    _afterListenEnds();
  }

  @override
  void dispose() {
    unawaited(_speech.stop());
    super.dispose();
  }
}
