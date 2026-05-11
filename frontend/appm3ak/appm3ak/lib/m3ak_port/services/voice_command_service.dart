import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

/// [home] : navigation depuis l’accueil (chatbot, M3AK Visage).
/// [faceRecognition] : commandes sur l’écran reconnaissance (ajouter, tester, etc.).
enum VoiceListenContext { home, faceRecognition }

class VoiceCommandService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isInitialized = false;
  Function(String)? _onCommandDetected;
  Timer? _restartTimer;
  VoiceListenContext _context = VoiceListenContext.home;

  /// Initialise le service de reconnaissance vocale
  Future<bool> initialize() async {
    if (_isInitialized) {
      print('✅ Service vocal déjà initialisé');
      return true;
    }

    print('🎤 Demande de permission microphone...');
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      print('❌ Permission microphone refusée');
      return false;
    }
    print('✅ Permission microphone accordée');

    print('🎤 Initialisation de SpeechToText...');
    final available = await _speech.initialize(
      onError: (error) {
        print('❌ Erreur SpeechToText: ${error.errorMsg}');
        _scheduleRestart();
      },
      onStatus: (status) {
        print('📊 Statut SpeechToText: $status');
        if (status == 'done' || status == 'notListening') {
          _scheduleRestart();
        }
      },
    );

    _isInitialized = available;
    if (available) {
      print('✅ SpeechToText initialisé avec succès');
    } else {
      print('❌ Échec de l\'initialisation de SpeechToText');
    }
    return available;
  }

  void _scheduleRestart() {
    _restartTimer?.cancel();
    _restartTimer = Timer(const Duration(milliseconds: 500), () {
      if (_isInitialized && !_isListening && _onCommandDetected != null) {
        _startListeningInternal();
      }
    });
  }

  /// Démarre l'écoute continue pour détecter les commandes
  Future<void> startListening(
    Function(String) onCommandDetected, {
    VoiceListenContext context = VoiceListenContext.home,
  }) async {
    if (!_isInitialized) {
      print('🔄 Réinitialisation du service vocal...');
      final initialized = await initialize();
      if (!initialized) {
        print('❌ Impossible de démarrer l\'écoute: service non initialisé');
        return;
      }
    }

    if (_isListening) {
      print('⚠️ Écoute déjà en cours');
      return;
    }

    print('🎧 Démarrage de l\'écoute continue (context=$context)...');
    _context = context;
    _onCommandDetected = onCommandDetected;
    print('✅ Callback enregistré: ${_onCommandDetected != null}');
    _startListeningInternal();
  }

  Future<void> _startListeningInternal() async {
    if (_isListening) return;
    _isListening = true;

    try {
      print('🎤 Démarrage de l\'écoute SpeechToText...');
      await _speech.listen(
        onResult: (result) {
          print(
            '📝 Résultat reçu - Final: ${result.finalResult}, Texte: "${result.recognizedWords}"',
          );

          if (result.finalResult) {
            if (result.recognizedWords.isNotEmpty) {
              print('✅ Traitement du résultat final: "${result.recognizedWords}"');
              _processCommand(result.recognizedWords);
            } else {
              print('⚠️ Résultat final vide, relance de l\'écoute...');
            }
            _isListening = false;
            _scheduleRestart();
          } else {
            if (result.recognizedWords.isNotEmpty) {
              print('⏳ Résultat partiel: "${result.recognizedWords}"');
            }
          }
        },
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 2),
        localeId: 'fr_FR',
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          listenMode: stt.ListenMode.dictation,
        ),
      );
      print('✅ Écoute démarrée avec succès');
    } catch (e) {
      print('❌ Erreur lors de l\'écoute: $e');
      _isListening = false;
      _scheduleRestart();
    }
  }

  Future<void> stopListening() async {
    if (!_isListening) {
      await _speech.stop();
      _onCommandDetected = null;
      return;
    }
    await _speech.stop();
    _isListening = false;
    _onCommandDetected = null;
  }

  bool _wantsOpenFaceRecognition(String text) {
    if (text.contains('reconnaissance faciale')) return true;
    if (text.contains('reconnaissance facial')) return true;
    if (text.contains('reconnaissance du visage')) return true;
    if (text.contains('m3ak visage')) return true;
    if (text.contains('reconnaissance') &&
        (text.contains('visage') || text.contains('facial'))) {
      return true;
    }

    const openKeywords = [
      'ouvrir',
      'ouvre',
      'ouvre le',
      'ouvrir le',
      'ouvre la',
      'ouvrir la',
      'open',
      'lance',
      'lancer',
      'start',
      'démarrer',
      'démarre',
    ];
    final hasOpen = openKeywords.any((k) => text.contains(k));
    if (hasOpen &&
        (text.contains('visage') ||
            text.contains('facial') ||
            text.contains('reconnaissance'))) {
      return true;
    }
    return false;
  }

  void _processFaceScreenCommands(String text) {
    if (text.contains('tester') ||
        text.contains('bouton tester') ||
        text.contains('lance le test') ||
        text.contains('lancer le test') ||
        _hasWholeWord(text, 'test')) {
      print('✅ Commande écran visage : tester');
      _onCommandDetected?.call('face_screen_test');
      return;
    }

    if (text.contains('ajouter') ||
        text.contains('bouton ajouter') ||
        text.contains('nouvelle personne') ||
        text.contains('enregistrer une personne') ||
        (text.contains('ajouter') && text.contains('personne'))) {
      print('✅ Commande écran visage : ajouter');
      _onCommandDetected?.call('add_person');
      return;
    }

    if (text.contains('qui est') &&
        (text.contains('là') ||
            text.contains('la') ||
            text.contains('devant') ||
            text.contains('caméra') ||
            text.contains('camera'))) {
      _onCommandDetected?.call('who_is_there');
      return;
    }

    if (text.contains('liste') &&
        (text.contains('personne') || text.contains('person') || text.contains('enregistr'))) {
      _onCommandDetected?.call('list_persons');
      return;
    }

    if (text.contains('annuler') ||
        text.contains('fermer ajout') ||
        text.contains('quitte') ||
        text.contains('retour en arrière') ||
        text.trim() == 'retour') {
      _onCommandDetected?.call('face_screen_cancel');
      return;
    }

    print('❌ Commande visage non reconnue: "$text"');
  }

  bool _hasWholeWord(String text, String word) {
    return RegExp(r'(^|\s)' + RegExp.escape(word) + r'($|\s|[,\.])')
        .hasMatch(text);
  }

  void _processCommand(String recognizedText) {
    if (recognizedText.isEmpty) {
      print('⚠️ Texte vide, ignoré');
      return;
    }

    final text = recognizedText.toLowerCase().trim();
    print('🔊 Analyse de la commande: "$text"');

    if (_context == VoiceListenContext.faceRecognition) {
      _processFaceScreenCommands(text);
      return;
    }

    // ——— Accueil : ouvrir M3AK Visage AVANT le chatbot (accessibilité) ———
    if (_wantsOpenFaceRecognition(text)) {
      print('✅ COMMANDE: open_face_recognition');
      _onCommandDetected?.call('open_face_recognition');
      return;
    }

    const chatbotKeywords = [
      'chatbot',
      'chat bot',
      'chat',
      'chabot',
      'chabote',
      'assistant',
      'assistant vocal',
      'signe',
    ];

    const openKeywords = [
      'ouvrir',
      'ouvre',
      'ouvre le',
      'ouvrir le',
      'ouvre la',
      'ouvrir la',
      'open',
      'lance',
      'lancer',
      'start',
      'démarrer',
      'démarre',
    ];

    final hasChatbotKeyword = chatbotKeywords.any((k) => text.contains(k));
    final hasOpenKeyword = openKeywords.any((k) => text.contains(k));

    if (hasOpenKeyword && hasChatbotKeyword) {
      print('✅ COMMANDE: open_chatbot');
      _onCommandDetected?.call('open_chatbot');
      return;
    }

    if (hasChatbotKeyword) {
      print('✅ COMMANDE: open_chatbot (mot-clé seul)');
      _onCommandDetected?.call('open_chatbot');
      return;
    }

    if (hasOpenKeyword && (text.contains('chat') || text.contains('bot'))) {
      print('✅ COMMANDE: open_chatbot (ouvrir + chat)');
      _onCommandDetected?.call('open_chatbot');
      return;
    }

    if ((text.contains('chat') || text.contains('assistant')) &&
        text.contains('signe')) {
      print('✅ COMMANDE: open_chatbot (signe)');
      _onCommandDetected?.call('open_chatbot');
      return;
    }

    // « ouvrir » / « ouvre » seul : chatbot par défaut (après exclusion visage)
    if (hasOpenKeyword && text.split(RegExp(r'\s+')).length <= 2) {
      print('✅ COMMANDE: open_chatbot (ouvrir court)');
      _onCommandDetected?.call('open_chatbot');
      return;
    }

    if (text.contains('ajouter') &&
        (text.contains('personne') || text.contains('person'))) {
      _onCommandDetected?.call('add_person');
      return;
    }

    if (text.contains('qui est') && (text.contains('là') || text.contains('la'))) {
      _onCommandDetected?.call('who_is_there');
      return;
    }

    if (text.contains('liste') &&
        (text.contains('personne') || text.contains('person'))) {
      _onCommandDetected?.call('list_persons');
      return;
    }

    print('❌ Aucune commande détectée dans: "$text"');
  }

  bool get isListening => _isListening;

  void dispose() {
    _restartTimer?.cancel();
    _speech.stop();
    _isListening = false;
    _isInitialized = false;
    _onCommandDetected = null;
    _context = VoiceListenContext.home;
  }
}
