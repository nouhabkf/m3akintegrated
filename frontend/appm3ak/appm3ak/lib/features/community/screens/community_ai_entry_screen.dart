import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../core/volume/android_volume_hub.dart';
import '../../../data/models/community_action_plan_result.dart';
import '../../../m3ak_assist/m3ak_create_post_launch.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/community_providers.dart';
import '../logic/information_head_gesture_intent.dart';

enum _CommunityEntryIntent {
  publish,
  help,
  location,
  unknown,
}

enum _InputModeHint {
  keyboard('keyboard'),
  voice('voice'),
  headEyes('headEyes'),
  haptic('haptic'),
  volumeShortcut('volume_shortcut');

  const _InputModeHint(this.apiValue);
  final String apiValue;
}

class CommunityAiEntryScreen extends ConsumerStatefulWidget {
  const CommunityAiEntryScreen({super.key});

  @override
  ConsumerState<CommunityAiEntryScreen> createState() =>
      _CommunityAiEntryScreenState();
}

class _CommunityAiEntryScreenState extends ConsumerState<CommunityAiEntryScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final TextEditingController _inputController = TextEditingController();
  /// Permet de capturer le texte au moment où le champ perd le focus (avant que
  /// l’IME Android ne vide parfois le [TextEditingController] quand on tape sur « Analyser »).
  final FocusNode _inputFocusNode = FocusNode(debugLabel: 'communityAiEntryInput');
  /// Dernière valeur non vide vue au blur du champ.
  String _textCaptureOnFieldBlur = '';
  /// Dernière valeur non vide du contrôleur (n’est jamais écrasée par une chaîne vide).
  String _lastNonEmptyInput = '';
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _didAutoSpeak = false;
  bool _isAnalyzing = false;
  bool _hasNavigatedFromAi = false;
  bool _speechReady = false;
  bool _voiceSessionActive = false;
  bool _dictationStartAnnounced = false;
  bool _showKeyboardFallback = false;
  bool _voiceAutoFinalizing = false;
  bool _showPostSuggestions = false;
  String _assistantStateText = 'Prêt à naviguer';
  String _listenLocaleId = 'fr_FR';
  _InputModeHint? _lastInputModeHint;
  Future<bool> Function()? _previousVolumeUpPriority;
  Future<void>? _speechInitFuture;
  Future<void> _speechGuidanceChain = Future<void>.value();
  late AnimationController _listenPulseController;

  // —— Mode caméra tête / yeux (navigation accessible, posts uniquement)
  bool _headEyesModeActive = false;
  bool _headEyesInitializing = false;
  bool _headEyesPermissionDenied = false;
  String _headEyesLiveHint = '';
  CameraController? _headEyesCamera;
  FaceDetector? _headEyesFaceDetector;
  bool _headEyesProcessingFrame = false;
  bool _headEyesNavigating = false;
  bool _headEyesNeedsResumeAfterPause = false;
  bool _headEyesFaceDetectedDebug = false;
  int _headEyesSelectedIndex = 0;
  double _headEyesConfirmProgress = 0;
  DateTime _headEyesLastNavAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _headEyesAwaitNeutral = false;
  DateTime? _headEyesEyeClosedSince;
  DateTime _headEyesLastGestureConfirmAt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime? _headEyesNeutralStillSince;
  DateTime _headEyesLastTtsAt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _headEyesLastNoFaceTtsAt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _headEyesLastFrameHandledAt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime? _headEyesLastFaceSeenAt;
  int _headEyesNoFaceStreak = 0;
  String _headEyesPendingSelectionPrompt = '';
  double? _headEyesLastYaw;
  double? _headEyesLastLeftEye;
  double? _headEyesLastRightEye;
  String _headEyesLastGestureDebug = 'aucun';
  bool _headEyesLastStreamState = false;
  bool _headEyesLastNoFaceLogged = false;
  DateTime _headEyesLastDebugSetStateAt = DateTime.fromMillisecondsSinceEpoch(0);
  /// Après l’ouverture du flux caméra : pas de validation par yeux/immobilité
  /// (évite un faux « validation » au repos pendant l’intro TTS).
  DateTime? _headEyesConfirmAllowedAfter;
  static const bool kHeadEyesDebug = true;

  static const Duration _headEyesTtsMinGap = Duration(milliseconds: 900);
  static const Duration _headEyesNoFaceTtsMinGap = Duration(milliseconds: 3200);
  static const Duration _headEyesFrameThrottle = Duration(milliseconds: 300);
  static const int _headEyesNoFaceWarnStreak = 8;
  static const Duration _headEyesNoFaceGrace = Duration(milliseconds: 1300);
  static const Duration _headEyesNavCooldown = Duration(milliseconds: 900);
  static const Duration _headEyesEyeHoldConfirm = Duration(milliseconds: 1000);
  static const Duration _headEyesStillnessConfirm = Duration(milliseconds: 2800);
  static const Duration _headEyesGestureConfirmCooldown = Duration(milliseconds: 1700);
  static const Duration _headEyesConfirmGraceAfterStream =
      Duration(seconds: 6);
  static const double _headEyesYawNext = 15;
  static const double _headEyesYawPrev = -15;
  static const double _headEyesYawNeutral = 9;
  static const double _headEyesEyeClosedMax = 0.40;
  static const double _headEyesEyeOpenMin = 0.48;
  static const double _headEyesMinFaceCoverage = 0.02;

  static const List<String> _headEyesOptionLabels = <String>[
    'Poster photo (voix)',
    'Lancer un live',
    'Lire les posts',
    'Lire commentaires',
    'Commenter avec la voix',
  ];

  static const String _headEyesIntroTts =
      'Mode tête et yeux activé. Tournez la tête à droite ou à gauche pour changer de choix. Fermez les yeux pour valider.';

  /// Annonce vocale (sans émoji) — alignée sur la carte d’accueil.
  static const String _introTtsText =
      'Touchez la grande zone pour utiliser tête et yeux. Appuyez sur Volume plus pour dicter.';
  /// Seuil pour l’assistant d’entrée uniquement. À 0.85, presque aucune requête
  /// n’atteignait la navigation auto (confiance souvent 0.32–0.75 selon l’API).
  /// Seuil plus bas que le défaut serveur : l’entrée communautaire doit souvent
  /// ouvrir un parcours même quand la confiance heuristique est moyenne.
  static const double _autoNavigateMinConfidence = 0.5;

  /// Texte rapide « obstacle » → parcours **tête & yeux** sans passer par l’IA.
  static const String _obstacleHeadGesturePhrase = 'je veux signaler un obstacle';

  bool _isObstacleHeadGestureRequest(String raw) {
    return raw.trim().toLowerCase() == _obstacleHeadGesturePhrase;
  }

  /// Phrase réduite au profil déficience visuelle → dictée vocale (/create-post-voice-vibration).
  bool _isStandaloneVisualProfilePhrase(String raw) {
    final t = _normalizeSpeechText(raw);
    final compact = _compactSpeechText(t);
    const singles = <String>{
      'non voyant',
      'nonvoyant',
      'non voyante',
      'nonvoyante',
      'non-voyant',
      'non-voyante',
      'malvoyant',
      'malvoyante',
      'mal voyant',
      'mal voyante',
      'aveugle',
      'deficience visuelle',
      'deficiencevisuelle',
      'déficience visuelle',
      'handicap visuel',
      'handicapvisuel',
      'ma nchoufech',
      'manchoufech',
      'man nchoufech',
      'ma nchoufch',
      'manchoufch',
      'ma nchoufich',
      'man nchoufich',
    };
    return singles.contains(t) || singles.contains(compact);
  }

  bool _mentionsVisualImpairment(String raw) {
    final t = raw.toLowerCase().replaceAll('’', "'");
    return t.contains('non voyant') ||
        t.contains('non voyante') ||
        t.contains('non-voyant') ||
        t.contains('non-voyante') ||
        t.contains('malvoyant') ||
        t.contains('malvoyante') ||
        t.contains('mal voyant') ||
        t.contains('mal voyante') ||
        t.contains('aveugle') ||
        t.contains('deficience visuelle') ||
        t.contains('déficience visuelle') ||
        t.contains('handicap visuel') ||
        t.contains('ma nchoufech') ||
        t.contains('man nchoufech') ||
        t.contains('ma nchoufch') ||
        t.contains('manchoufech') ||
        t.contains('ma nchoufich') ||
        t.contains('man nchoufich');
  }

  /// Profil visuel + autre texte (pas seul, pas photo/signalement tête-yeux) → dictée publication.
  bool _isVoicePostVisualCompoundPhrase(String raw) {
    if (_isStandaloneVisualProfilePhrase(raw)) return false;
    if (_isBlindPhotoOrPlaceReportPhrase(raw)) return false;
    return _mentionsVisualImpairment(raw);
  }

  /// Non-voyant / « ma nchoufech » + envoi photo ou signalement de lieu → tête & yeux.
  bool _isBlindPhotoOrPlaceReportPhrase(String raw) {
    if (_isStandaloneVisualProfilePhrase(raw)) return false;
    if (!_mentionsVisualImpairment(raw)) return false;
    final t = raw.toLowerCase();
    final wantsReport = t.contains('signalement') ||
        t.contains('signaler') ||
        t.contains('obstacle') ||
        t.contains('je veux signaler') ||
        t.contains('signaler une place') ||
        t.contains('signaler le lieu') ||
        t.contains('place inaccessible') ||
        t.contains('lieu inaccessible') ||
        t.contains('njm3lem') ||
        t.contains('njem3lem') ||
        t.contains('nheb nsn3el') ||
        t.contains('n7eb nsn3el') ||
        t.contains('norbet') ||
        (t.contains('place') &&
            (t.contains('signa') ||
                t.contains('obstacle') ||
                t.contains('inaccessible') ||
                t.contains('problème') ||
                t.contains('probleme'))) ||
        (t.contains('lieu') &&
            (t.contains('signa') ||
                t.contains('obstacle') ||
                t.contains('inaccessible')));
    return wantsReport;
  }

  void _navigateVoiceDictationPost() {
    if (!mounted || _hasNavigatedFromAi) return;
    _hasNavigatedFromAi = true;
    context.push('/create-post-voice-vibration');
  }

  void _navigateBlindPhotoOrReportHeadGesture() {
    if (!mounted || _hasNavigatedFromAi) return;
    _hasNavigatedFromAi = true;
    context.push('/create-post-head-gesture');
  }

  /// Poster / envoyer une photo — dictée → tête & yeux ; clavier → création + caméra.
  bool _isWantPostPhotoPhrase(String raw) {
    final t = raw.toLowerCase().replaceAll('’', "'").trim();
    if (t.contains('nhabet taswira') ||
        t.contains('nhab taswira') ||
        t.contains('nhbt taswira') ||
        t.contains('nb3th taswira')) {
      return true;
    }
    if (t.contains('je veux poster une photo')) return true;
    if (t.contains('poster une photo') || t.contains('publier une photo')) {
      return true;
    }
    if (t.contains('envoyer une photo') || t.contains('envoyer une image')) {
      return true;
    }
    if ((t.contains('veux poster') || t.contains('veux publier')) &&
        (t.contains('photo') || t.contains('image') || t.contains('taswira'))) {
      return true;
    }
    return false;
  }

  void _navigatePostPhotoVoiceHeadGesture() {
    if (!mounted || _hasNavigatedFromAi) return;
    _hasNavigatedFromAi = true;
    context.push('/create-post-voice-vibration?photoIntent=1');
  }

  void _navigatePostPhotoKeyboardCamera(String content) {
    if (!mounted || _hasNavigatedFromAi) return;
    _hasNavigatedFromAi = true;
    context.push(
      '/create-post',
      extra: M3akCreatePostLaunch(
        initialContent: content.trim(),
        accessibilityAnnounceGalleryVolumeOrCameraFallback: true,
      ),
    );
  }

  /// Voir / ouvrir le dernier post publié (FR + oral tunisien).
  bool _isOpenLatestPostRequest(String raw) {
    final t = _normalizeSpeechText(raw);
    final compact = _compactSpeechText(t);
    if (t.isEmpty) return false;

    // Ne pas confondre avec « je veux poster / publier ».
    if (t.contains('je veux poster') ||
        t.contains('veux publier') ||
        t.contains('poster une') ||
        t.contains('nhabet taswira')) {
      return false;
    }

    if (t.contains('dernier post') ||
        t.contains('derenier post') ||
        t.contains('dernier poste') ||
        t.contains('derenier poste') ||
        t.contains('derniers posts') ||
        t.contains('dernière publication') ||
        t.contains('dernier publication')) {
      return true;
    }
    // Règle large: toute phrase combinant "dernier" + (post/poste/publication).
    if (t.contains('dernier') &&
        (t.contains('post') ||
            t.contains('poste') ||
            t.contains('publication'))) {
      return true;
    }
    if (compact.contains('voirdernierpost') ||
        compact.contains('voirdernierposte') ||
        compact.contains('voirdrnierpost') ||
        compact.contains('voirdrnierposte')) {
      return true;
    }
    if (t.contains('voir dernier post') || t.contains('voir dernier poste')) {
      return true;
    }
    if (t.contains('voir') &&
        t.contains('dernier') &&
        (t.contains('post') ||
            t.contains('poste') ||
            t.contains('publication') ||
            t.contains('publications'))) {
      return true;
    }
    if (t.contains('ouvrir') && t.contains('dernier') && t.contains('post')) {
      return true;
    }
    if (t.contains('afficher') && t.contains('dernier') && t.contains('post')) {
      return true;
    }
    // Tunisien : nheb/n7eb … nchouf … post / akher / dernier
    final tunWantSee = (t.contains('nheb') || t.contains('n7eb') || t.contains('nhbt')) &&
        (t.contains('nchouf') ||
            t.contains('nchov') ||
            t.contains(' chouf') ||
            t.contains(' chov') ||
            t.endsWith('chouf') ||
            t.endsWith('chov'));
    if (tunWantSee &&
        (t.contains('post') ||
            t.contains('poste') ||
            t.contains('akher') ||
            t.contains('a5er') ||
            t.contains('dernier') ||
            t.contains('publication'))) {
      return true;
    }
    if ((t.contains('akher') || t.contains('a5er')) &&
        (t.contains('post') || t.contains('publication'))) {
      return true;
    }
    if (compact.contains('nhebnchovakherpost') ||
        compact.contains('nhebnchovakherposte') ||
        compact.contains('nhebnchoufakherpost') ||
        compact.contains('nhebnchoufakherposte')) {
      return true;
    }
    return false;
  }

  bool _isReadLatestPostCommentsRequest(String raw) {
    final t = _normalizeSpeechText(raw);
    return (t.contains('lire') || t.contains('ecouter')) &&
        (t.contains('commentaire') || t.contains('commentaires')) &&
        (t.contains('dernier post') ||
            t.contains('derenier post') ||
            t.contains('dernier poste') ||
            t.contains('derenier poste') ||
            t.contains('akher post'));
  }

  bool _isReadPostsAudioRequest(String raw) {
    final t = _normalizeSpeechText(raw);
    final hasReadVerb = t.contains('lire') || t.contains('ecouter');
    final hasPosts = t.contains('post') || t.contains('posts') || t.contains('publication');
    return hasReadVerb && hasPosts && !t.contains('commentaire');
  }

  bool _isReadCommentsAudioRequest(String raw) {
    final t = _normalizeSpeechText(raw);
    final hasReadVerb = t.contains('lire') || t.contains('ecouter');
    final hasComments = t.contains('commentaire') || t.contains('commentaires');
    return hasReadVerb && hasComments;
  }

  bool _isVoiceCommentRequest(String raw) {
    final t = _normalizeSpeechText(raw);
    return (t.contains('commenter') || t.contains('commentaire')) &&
        (t.contains('voix') || t.contains('vocal'));
  }

  bool _isLaunchLiveRequest(String raw) {
    final t = _normalizeSpeechText(raw);
    final hasLaunchVerb =
        t.contains('lancer') || t.contains('demarrer') || t.contains('start');
    final hasLiveWord = t.contains('live') || t.contains('direct');
    return hasLaunchVerb && hasLiveWord;
  }

  bool _isReadCommentsAudioListRequest(String raw) {
    final t = _normalizeSpeechText(raw);
    final mentionsComments = t.contains('commentaire') || t.contains('commentaires');
    if (!mentionsComments) return false;
    return t.contains('lire les commentaires') ||
        t.contains('ecouter les commentaires') ||
        t.contains('commentaires d un post') ||
        t.contains('commentaires d un poste') ||
        t.contains('commentaires post') ||
        t.contains('lire commentaire');
  }

  bool _isReadLatestPostSummaryRequest(String raw) {
    final t = _normalizeSpeechText(raw);
    return (t.contains('lire') || t.contains('ecouter')) &&
        (t.contains('resume') || t.contains('résumé')) &&
        (t.contains('dernier post') ||
            t.contains('derenier post') ||
            t.contains('dernier poste') ||
            t.contains('derenier poste') ||
            t.contains('akher post'));
  }

  bool _isOpenHeadEyesCameraCommand(String raw) {
    final t = _normalizeSpeechText(raw);
    return (t.contains('ouvre camera') ||
            t.contains('ouvrir camera') ||
            t.contains('open camera') ||
            t.contains('camera tete yeux') ||
            t.contains('camera tete et yeux') ||
            t.contains('camera')) &&
        (t.contains('poster') ||
            t.contains('post') ||
            t.contains('tete yeux') ||
            t.contains('tete et yeux') ||
            t == 'ouvre camera' ||
            t == 'ouvrir camera' ||
            t == 'open camera');
  }

  /// Premier post du fil global page 1 (tri côté API : le plus récent en tête).
  Future<void> _openLatestCommunityPost({
    bool autoReadPost = false,
    bool autoReadComments = false,
    bool autoReadSummary = false,
  }) async {
    if (!mounted || _hasNavigatedFromAi) return;
    setState(() {
      _isAnalyzing = true;
      _showPostSuggestions = false;
    });
    try {
      final bundle = await ref.read(
        communityFeedProvider((
          page: 1,
          limit: 20,
          smart: false,
        )).future,
      );
      final posts = bundle.posts;
      if (posts.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(content: Text('Aucun post pour le moment.')),
        );
        return;
      }
      final id = posts.first.id;
      _hasNavigatedFromAi = true;
      if (!mounted) return;
      final query = <String, String>{};
      if (autoReadPost) query['autoReadPost'] = '1';
      if (autoReadComments) query['autoReadComments'] = '1';
      if (autoReadSummary) query['autoReadSummary'] = '1';
      final qp = query.entries.map((e) => '${e.key}=${e.value}').join('&');
      final route = qp.isEmpty ? '/post-detail/$id' : '/post-detail/$id?$qp';
      context.push(route);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text('Impossible d’ouvrir le dernier post. $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  /// Parcours **tête & yeux** sans appel IA (obstacle, info lieu accessible, etc.).
  void _pushHeadGestureEntryBypassAi() {
    if (!mounted || _hasNavigatedFromAi) return;
    _hasNavigatedFromAi = true;
    context.push('/create-post-head-gesture');
  }

  void _navigateObstacleHeadGesture() => _pushHeadGestureEntryBypassAi();

  String _normalizeSpeechText(String raw) {
    var t = raw.toLowerCase().replaceAll('’', "'").trim();
    const replacements = <String, String>{
      'à': 'a',
      'â': 'a',
      'ä': 'a',
      'á': 'a',
      'ã': 'a',
      'å': 'a',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ï': 'i',
      'ó': 'o',
      'ò': 'o',
      'ô': 'o',
      'ö': 'o',
      'õ': 'o',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ç': 'c',
    };
    replacements.forEach((k, v) {
      t = t.replaceAll(k, v);
    });
    t = t.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    return t;
  }

  String _compactSpeechText(String normalized) {
    return normalized.replaceAll(' ', '');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listenPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _inputController.addListener(_onInputTextChanged);
    _inputFocusNode.addListener(_onInputFocusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakIntro(automatic: true);
    });
    if (!kIsWeb && Platform.isAndroid) {
      AndroidVolumeHub.ensureInitialized();
      _previousVolumeUpPriority = AndroidVolumeHub.onVolumeUpPriority;
      AndroidVolumeHub.onVolumeUpPriority = _onVolumeUpVoice;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (!kIsWeb && Platform.isAndroid) {
      if (AndroidVolumeHub.onVolumeUpPriority == _onVolumeUpVoice) {
        AndroidVolumeHub.onVolumeUpPriority = _previousVolumeUpPriority;
      }
    }
    unawaited(_speech.stop());
    _tts.stop();
    unawaited(_disposeHeadEyesMode());
    _inputController.removeListener(_onInputTextChanged);
    _inputFocusNode.removeListener(_onInputFocusChanged);
    _listenPulseController.dispose();
    _inputFocusNode.dispose();
    _inputController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (!_headEyesModeActive || kIsWeb) return;
    if (kHeadEyesDebug) {
      debugPrint('[HeadEyesDebug] lifecycle changed: $state');
    }
    if (state == AppLifecycleState.inactive) {
      // Samsung can emit inactive during transient UI overlays (IME, system bars).
      // Do not tear down camera pipeline on inactive.
      return;
    }
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _headEyesNeedsResumeAfterPause = true;
      final cam = _headEyesCamera;
      if (cam != null && cam.value.isStreamingImages) {
        unawaited(() async {
          try {
            await cam.stopImageStream();
            if (kHeadEyesDebug) {
              debugPrint('[HeadEyesDebug] stream stopped on lifecycle pause');
            }
          } catch (_) {}
        }());
      }
      return;
    }
    if (state == AppLifecycleState.resumed) {
      if (!_headEyesNeedsResumeAfterPause) return;
      _headEyesNeedsResumeAfterPause = false;
      final cam = _headEyesCamera;
      if (cam != null && cam.value.isInitialized) {
        unawaited(() async {
          try {
            if (!cam.value.isStreamingImages) {
              await cam.startImageStream(_onHeadEyesCameraImage);
              if (kHeadEyesDebug) {
                debugPrint('[HeadEyesDebug] stream resumed without full camera restart');
              }
            }
          } catch (_) {
            await _startHeadEyesCameraMode(forceRestart: true);
          }
        }());
        return;
      }
      unawaited(_startHeadEyesCameraMode(forceRestart: true));
    }
  }

  void _onInputFocusChanged() {
    if (!_inputFocusNode.hasFocus) {
      final raw = _inputController.text;
      if (raw.trim().isNotEmpty) _textCaptureOnFieldBlur = raw;
    }
  }

  void _onInputTextChanged() {
    final raw = _inputController.text;
    if (raw.trim().isNotEmpty) _lastNonEmptyInput = raw;
    setState(() {});
  }

  /// Ordre : texte actuel du contrôleur → capture au blur → dernier non vide (dictée / IME).
  String _resolveRawTextForAnalysis() {
    if (_inputController.text.trim().isNotEmpty) return _inputController.text;
    if (_textCaptureOnFieldBlur.trim().isNotEmpty) {
      return _textCaptureOnFieldBlur;
    }
    if (_lastNonEmptyInput.trim().isNotEmpty) return _lastNonEmptyInput;
    return '';
  }

  void _setListeningPulse(bool active) {
    if (active) {
      _listenPulseController.repeat(reverse: true);
    } else {
      _listenPulseController
        ..stop()
        ..reset();
    }
  }

  Future<void> _speakDictationGuidance(String text) {
    _speechGuidanceChain = _speechGuidanceChain.then((_) async {
      if (!mounted) return;
      try {
        await _tts.awaitSpeakCompletion(true);
        await _tts.setLanguage('fr-FR');
        await _tts.setSpeechRate(0.46);
        await _tts.setPitch(1.0);
        await _tts.stop();
        await _tts.speak(text);
      } catch (_) {}
    });
    return _speechGuidanceChain;
  }

  void _setAssistantState(String text) {
    if (!mounted || _assistantStateText == text) return;
    setState(() => _assistantStateText = text);
  }

  Future<void> _announceRecognizedAndAnalyze(String recognized) async {
    final normalized = recognized.trim().replaceAll('\n', ' ');
    if (normalized.isEmpty) return;
    final clipped = normalized.length > 150
        ? '${normalized.substring(0, 150)}...'
        : normalized;
    await _speakDictationGuidance(
      'Vous voulez dire : $clipped. Je vais analyser votre demande.',
    );
  }

  bool _isLowConfidenceResult(CommunityActionPlanResult result) {
    final conf = result.confidence ?? 0;
    return result.requiresConfirmation == true || conf < 0.70;
  }

  List<({String label, String route})> _postSuggestionRoutes(String text) {
    final suggestions = <({String label, String route})>[
      (label: 'Poster une photo', route: '/create-post-voice-vibration'),
      (label: 'Écrire un post', route: '/create-post'),
      (label: 'Signaler un obstacle', route: '/create-post-head-gesture'),
      (label: 'Voir les derniers posts', route: '/community-posts'),
    ];
    final lowered = text.toLowerCase();
    if (lowered.contains('obstacle') || lowered.contains('rampe')) {
      return [
        suggestions[2],
        suggestions[1],
        suggestions[3],
      ];
    }
    if (lowered.contains('photo') || lowered.contains('taswira')) {
      return [
        suggestions[0],
        suggestions[1],
        suggestions[3],
      ];
    }
    if (lowered.contains('dernier') || lowered.contains('posts')) {
      return [
        suggestions[3],
        suggestions[1],
        suggestions[0],
      ];
    }
    return [
      suggestions[1],
      suggestions[0],
      suggestions[2],
    ];
  }

  Future<void> _handleVolumeShortcut() async {
    if (_isListeningUi) {
      _setAssistantState('Analyse en cours');
      if (!_voiceAutoFinalizing) {
        await _speakDictationGuidance('Dictée arrêtée. Analyse en cours.');
      }
      _dictationStartAnnounced = false;
      await _toggleVoiceListening();
      return;
    }
    if (!_dictationStartAnnounced) {
      _dictationStartAnnounced = true;
      _setAssistantState('Je vous écoute');
      await _speakDictationGuidance('Dictée démarrée. Parlez maintenant.');
    }
    await _toggleVoiceListening();
  }

  /// Volume+ : même action que le bouton micro (dictée puis analyse / navigation).
  Future<bool> _onVolumeUpVoice() async {
    if (!mounted || kIsWeb) return false;
    if (_headEyesModeActive) return true;
    _lastInputModeHint = _InputModeHint.volumeShortcut;
    await _handleVolumeShortcut();
    return true;
  }

  Future<void> _ensureSpeechReady() async {
    if (_speechReady) return;
    _speechInitFuture ??= _runSpeechInit();
    await _speechInitFuture;
    _speechInitFuture = null;
  }

  Future<void> _runSpeechInit() async {
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Microphone refusé. Autorisez-le dans les paramètres pour parler à l’assistant.',
            ),
          ),
        );
      }
      return;
    }

    final user = ref.read(authStateProvider).valueOrNull;
    final preferArabic =
        user?.preferredLanguage?.name.toLowerCase() == 'ar';

    final ok = await _speech.initialize(
      onError: (_) {
        if (!mounted) return;
        setState(() => _speechReady = false);
      },
      onStatus: _onSpeechStatus,
    );

    var localeId = preferArabic ? 'ar_SA' : 'fr_FR';
    try {
      final locales = await _speech.locales();
      localeId = _selectBestLocaleForTunisianSpeech(
        locales: locales,
        preferArabic: preferArabic,
        fallback: localeId,
      );
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _speechReady = ok;
      _listenLocaleId = localeId;
    });
  }

  String _selectBestLocaleForTunisianSpeech({
    required List<stt.LocaleName> locales,
    required bool preferArabic,
    required String fallback,
  }) {
    if (locales.isEmpty) return fallback;

    String normalize(String v) => v.toLowerCase().replaceAll('-', '_');
    final normalizedToRaw = <String, String>{
      for (final l in locales) normalize(l.localeId): l.localeId,
    };
    bool hasPrefix(String value, String prefix) =>
        value == prefix || value.startsWith('${prefix}_');

    String? pickByPriority(List<String> priorities) {
      for (final wanted in priorities) {
        final normalizedWanted = normalize(wanted);
        final exact = normalizedToRaw[normalizedWanted];
        if (exact != null) return exact;
        for (final entry in normalizedToRaw.entries) {
          if (hasPrefix(entry.key, normalizedWanted)) return entry.value;
        }
      }
      return null;
    }

    final priorities = preferArabic
        ? <String>[
            'ar_tn',
            'ar_ma',
            'ar_dz',
            'ar_sa',
            'ar',
            'fr_tn',
            'fr_fr',
            'fr',
          ]
        : <String>[
            'fr_tn',
            'fr_fr',
            'fr',
            'ar_tn',
            'ar',
          ];

    return pickByPriority(priorities) ?? locales.first.localeId;
  }

  void _onSpeechStatus(String status) {
    if (!_voiceSessionActive) return;
    if (status != 'done' && status != 'notListening') return;
    if (_speech.isListening) return;
    if (_voiceAutoFinalizing) return;
    _voiceSessionActive = false;
    unawaited(_finalizeVoiceAndAnalyze());
  }

  Future<void> _stopVoiceAndAnalyzeFromFinalResult() async {
    if (_voiceAutoFinalizing) return;
    _voiceAutoFinalizing = true;
    try {
      _voiceSessionActive = false;
      _setListeningPulse(false);
      if (_speech.isListening) {
        await _speech.stop();
      }
      await _finalizeVoiceAndAnalyze();
    } finally {
      _voiceAutoFinalizing = false;
    }
  }

  Future<void> _finalizeVoiceAndAnalyze() async {
    if (!mounted) return;
    _setListeningPulse(false);
    final recognized = _resolveRawTextForAnalysis();
    setState(() {
      _voiceSessionActive = false;
      _dictationStartAnnounced = false;
    });
    _setAssistantState('Analyse en cours');
    await _announceRecognizedAndAnalyze(recognized);
    // Même chemin que le clavier : résolution du texte + analyse IA (pas deux logiques).
    await _prepareAndRunAnalysis(afterVoice: true);
  }

  /// Texte saisi au clavier ou reconnu à l’oral → une seule analyse IA.
  Future<void> _prepareAndRunAnalysis({bool afterVoice = false}) async {
    var typed = _resolveRawTextForAnalysis();
    FocusScope.of(context).unfocus();

    if (typed.trim().isEmpty) {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      typed = _resolveRawTextForAnalysis();
    }

    if (typed.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(
            afterVoice
                ? 'Rien n’a été reconnu. Réessayez ou saisissez au clavier.'
                : 'Saisissez ou dictez du texte avant d’analyser.',
          ),
        ),
      );
      return;
    }
    _setAssistantState('Analyse en cours');

    if (_isStandaloneVisualProfilePhrase(typed)) {
      _navigateVoiceDictationPost();
      return;
    }
    if (_isBlindPhotoOrPlaceReportPhrase(typed)) {
      _navigateBlindPhotoOrReportHeadGesture();
      return;
    }
    if (_isVoicePostVisualCompoundPhrase(typed)) {
      _navigateVoiceDictationPost();
      return;
    }
    if (_isObstacleHeadGestureRequest(typed)) {
      _navigateObstacleHeadGesture();
      return;
    }
    if (_isOpenHeadEyesCameraCommand(typed)) {
      _navigateObstacleHeadGesture();
      return;
    }
    if (_isLaunchLiveRequest(typed)) {
      if (!mounted || _hasNavigatedFromAi) return;
      _hasNavigatedFromAi = true;
      context.push('/community-live?host=1');
      return;
    }
    if (_isVoiceCommentRequest(typed)) {
      if (!mounted || _hasNavigatedFromAi) return;
      _hasNavigatedFromAi = true;
      context.push('/community-posts?mode=voiceComment');
      return;
    }
    if (_isReadCommentsAudioRequest(typed)) {
      if (!mounted || _hasNavigatedFromAi) return;
      _hasNavigatedFromAi = true;
      context.push('/community-posts?mode=readComments');
      return;
    }
    if (_isReadPostsAudioRequest(typed)) {
      if (!mounted || _hasNavigatedFromAi) return;
      _hasNavigatedFromAi = true;
      context.push('/community-posts?mode=readPost');
      return;
    }
    if (_isReadCommentsAudioListRequest(typed)) {
      if (!mounted || _hasNavigatedFromAi) return;
      _hasNavigatedFromAi = true;
      context.push('/community-posts?mode=readCommentsAudio');
      return;
    }
    if (_isReadLatestPostCommentsRequest(typed)) {
      await _openLatestCommunityPost(
        autoReadPost: true,
        autoReadComments: true,
      );
      return;
    }
    if (_isReadLatestPostSummaryRequest(typed)) {
      await _openLatestCommunityPost(
        autoReadPost: true,
        autoReadSummary: true,
      );
      return;
    }
    if (isInformationAccessibleInfoHeadGesturePhrase(typed)) {
      _pushHeadGestureEntryBypassAi();
      return;
    }
    if (_isOpenLatestPostRequest(typed)) {
      await _openLatestCommunityPost(autoReadPost: true);
      return;
    }
    if (_isWantPostPhotoPhrase(typed)) {
      if (afterVoice) {
        _navigatePostPhotoVoiceHeadGesture();
      } else {
        _navigatePostPhotoKeyboardCamera(typed);
      }
      return;
    }
    final modeHint = afterVoice
        ? _InputModeHint.voice.apiValue
        : (_lastInputModeHint?.apiValue ?? _InputModeHint.keyboard.apiValue);
    await _runAiAnalysis(typed, inputModeHint: modeHint);
  }

  Future<void> _toggleVoiceListening() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La dictée vocale nécessite l’application mobile (micro).',
          ),
        ),
      );
      return;
    }

    await _tts.stop();

    if (_speech.isListening) {
      _voiceSessionActive = false;
      _setListeningPulse(false);
      await _speech.stop();
      await _finalizeVoiceAndAnalyze();
      return;
    }

    await _ensureSpeechReady();
    if (!_speechReady || !mounted) return;

    _voiceSessionActive = true;
    _lastInputModeHint = _InputModeHint.voice;
    _setListeningPulse(true);
    _setAssistantState('Je vous écoute');
    setState(() {});

    unawaited(() async {
      try {
        await _speech.listen(
          onResult: (r) {
            if (!mounted) return;
            setState(() {
              _inputController.text = r.recognizedWords;
              _inputController.selection = TextSelection.fromPosition(
                TextPosition(offset: _inputController.text.length),
              );
            });
            if (r.finalResult && r.recognizedWords.trim().isNotEmpty) {
              unawaited(_stopVoiceAndAnalyzeFromFinalResult());
            }
          },
          listenFor: const Duration(seconds: 60),
          pauseFor: const Duration(seconds: 3),
          localeId: _listenLocaleId,
          listenOptions: stt.SpeechListenOptions(
            listenMode: stt.ListenMode.dictation,
            cancelOnError: false,
            partialResults: true,
          ),
        );
      } catch (_) {
        _voiceSessionActive = false;
        _setListeningPulse(false);
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible de démarrer l’écoute. Réessayez.'),
            ),
          );
        }
      }
    }());
  }

  Future<void> _speakIntro({bool automatic = false}) async {
    if (automatic && _didAutoSpeak) return;
    if (automatic) _didAutoSpeak = true;

    try {
      await _tts.awaitSpeakCompletion(true);
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.setLanguage('fr-FR');
      await _tts.stop();
      await _tts.speak(_introTtsText);
    } catch (_) {
      // On garde un comportement silencieux si TTS indisponible.
    }
  }

  Future<void> _onKeyboardSubmit() async {
    _lastInputModeHint = _InputModeHint.keyboard;
    await _prepareAndRunAnalysis(afterVoice: false);
  }

  void _openClassicModule() {
    context.push('/community-posts');
  }

  /// Message utile en dev : différencie « serveur éteint » et « IA Python off ».
  String _userMessageForAiFailure(Object error) {
    if (error is DioException) {
      final code = error.response?.statusCode;
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError) {
        return 'Connexion impossible vers l’API. '
            'Vérifiez que Nest tourne et l’URL (émulateur Android : souvent '
            'http://10.0.2.2:3000).';
      }
      if (code == 503 || code == 502) {
        return 'Le serveur répond mais le service IA est indisponible. '
            'Lancez le service Python (port 8000) ou vérifiez Nest / .env.';
      }
      if (code == 401 || code == 403) {
        return 'Session expirée ou accès refusé. Reconnectez-vous.';
      }
      if (code != null && code >= 500) {
        return 'Erreur serveur ($code). Réessayez ou consultez les logs Nest.';
      }
      final body = error.response?.data;
      if (body is Map && body['message'] != null) {
        return '${body['message']}';
      }
    }
    return 'Impossible d’analyser pour le moment. Réessayez dans un instant.';
  }

  Future<void> _onMicPressed() async {
    await _handleVolumeShortcut();
  }

  Future<void> _onTapLargeHeadEyesZone() async {
    HapticFeedback.mediumImpact();
    await _speakDictationGuidance('Mode tête et yeux activé.');
    if (!mounted) return;
    await _startHeadEyesCameraMode();
  }

  void _openKeyboardInput() {
    _lastInputModeHint = _InputModeHint.keyboard;
    setState(() => _showKeyboardFallback = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _inputFocusNode.requestFocus();
    });
  }

  String _postEntryFallbackRoute(String rawText) {
    final t = rawText.trim();
    if (_isOpenLatestPostRequest(t)) return '/community-posts';
    if (_isObstacleHeadGestureRequest(t)) return '/create-post-head-gesture';
    if (_isWantPostPhotoPhrase(t)) return '/create-post-voice-vibration';
    if (_isBlindPhotoOrPlaceReportPhrase(t)) return '/create-post-head-gesture';
    if (_isStandaloneVisualProfilePhrase(t) || _isVoicePostVisualCompoundPhrase(t)) {
      return '/create-post-voice-vibration';
    }
    return '/create-post';
  }

  bool _isPostAllowedRoute(String? route) {
    if (route == null || route.trim().isEmpty) return false;
    final r = route.trim().toLowerCase();
    return r.contains('/create-post') || r.contains('/community-posts');
  }

  bool _isNonPostAiDecision(CommunityActionPlanResult result) {
    final action = result.action.toLowerCase();
    final route = result.recommendedRoute?.toLowerCase();
    final helpAction = action == 'create_help_request';
    final helpRoute = route != null && route.contains('help');
    final locationRoute = route != null &&
        (route.contains('community-nearby') || route.contains('community-location'));
    return helpAction || helpRoute || locationRoute;
  }

  // ——————————————————————————————————————————————————————————
  // Mode caméra tête / yeux
  // ——————————————————————————————————————————————————————————

  Future<void> _speakHeadEyes(String text, {bool force = false}) async {
    final now = DateTime.now();
    if (!force && now.difference(_headEyesLastTtsAt) < _headEyesTtsMinGap) {
      return;
    }
    _headEyesLastTtsAt = now;
    try {
      await _tts.stop();
      await _tts.awaitSpeakCompletion(true);
      await _tts.setLanguage('fr-FR');
      await _tts.setSpeechRate(0.42);
      await _tts.speak(text);
    } catch (_) {}
  }

  void _setHeadEyesLiveHint(String value) {
    if (!mounted || _headEyesLiveHint == value) return;
    setState(() => _headEyesLiveHint = value);
  }

  void _setHeadEyesDebugSnapshot({
    bool? faceDetected,
    double? yaw,
    double? leftEye,
    double? rightEye,
    String? gesture,
  }) {
    _headEyesFaceDetectedDebug = faceDetected ?? _headEyesFaceDetectedDebug;
    _headEyesLastYaw = yaw ?? _headEyesLastYaw;
    _headEyesLastLeftEye = leftEye ?? _headEyesLastLeftEye;
    _headEyesLastRightEye = rightEye ?? _headEyesLastRightEye;
    if (gesture != null && gesture.isNotEmpty) {
      _headEyesLastGestureDebug = gesture;
    }
    if (!kHeadEyesDebug || !mounted) return;
    final now = DateTime.now();
    if (now.difference(_headEyesLastDebugSetStateAt) <
        const Duration(milliseconds: 120)) {
      return;
    }
    _headEyesLastDebugSetStateAt = now;
    setState(() {});
  }

  Future<void> _disposeHeadEyesMode() async {
    final det = _headEyesFaceDetector;
    _headEyesFaceDetector = null;
    if (det != null) {
      try {
        await det.close();
      } catch (_) {}
    }
    final c = _headEyesCamera;
    _headEyesCamera = null;
    if (c == null) return;
    try {
      if (c.value.isStreamingImages) {
        await c.stopImageStream();
      }
    } catch (_) {}
    try {
      await c.dispose();
    } catch (_) {}
  }

  Future<bool> _ensureHeadEyesCameraPermission() async {
    try {
      final status = await Permission.camera.status;
      if (status.isGranted) return true;
      final req = await Permission.camera.request();
      return req.isGranted;
    } catch (_) {
      return true;
    }
  }

  Uint8List _headEyesYuv420ToNv21(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];
    final yRowStride = yPlane.bytesPerRow;
    final uvRowStride = uPlane.bytesPerRow;
    final uvPixelStride = uPlane.bytesPerPixel ?? 1;
    final out = Uint8List(width * height + (width * height ~/ 2));
    var outIndex = 0;
    for (var row = 0; row < height; row++) {
      final rowStart = row * yRowStride;
      out.setRange(outIndex, outIndex + width, yPlane.bytes, rowStart);
      outIndex += width;
    }
    final uvHeight = height ~/ 2;
    final uvWidth = width ~/ 2;
    for (var row = 0; row < uvHeight; row++) {
      final uRow = row * uvRowStride;
      final vRow = row * vPlane.bytesPerRow;
      for (var col = 0; col < uvWidth; col++) {
        final uvOffset = col * uvPixelStride;
        final v = vPlane.bytes[vRow + uvOffset];
        final u = uPlane.bytes[uRow + uvOffset];
        out[outIndex++] = v;
        out[outIndex++] = u;
      }
    }
    return out;
  }

  InputImageRotation? _headEyesInputRotation(CameraDescription camera) {
    var o = camera.sensorOrientation;
    if (Platform.isAndroid && camera.lensDirection == CameraLensDirection.front) {
      o = (360 - o) % 360;
    }
    return InputImageRotationValue.fromRawValue(o);
  }

  InputImage? _headEyesToInputImage(CameraImage image, CameraDescription camera) {
    final rotation = _headEyesInputRotation(camera);
    if (rotation == null) return null;
    if (Platform.isAndroid) {
      final bytes = image.planes.length == 1
          ? image.planes.first.bytes
          : (image.planes.length >= 3 ? _headEyesYuv420ToNv21(image) : null);
      if (bytes == null) return null;
      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.nv21,
          bytesPerRow: image.width,
        ),
      );
    }
    if (Platform.isIOS) {
      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (format == null) return null;
      final plane = image.planes.first;
      return InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
    }
    return null;
  }

  Future<void> _startHeadEyesCameraMode({bool forceRestart = false}) async {
    if (kIsWeb) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Le mode tête et yeux nécessite l’application mobile et la caméra.',
            ),
          ),
        );
      }
      return;
    }
    if (_headEyesModeActive && !forceRestart) return;

    await _tts.stop();
    if (_speech.isListening) {
      await _speech.stop();
    }
    _voiceSessionActive = false;
    _setListeningPulse(false);

      setState(() {
      _headEyesModeActive = true;
      _headEyesInitializing = true;
      _headEyesPermissionDenied = false;
      _headEyesNavigating = false;
      _headEyesSelectedIndex = 0;
      _headEyesConfirmProgress = 0;
      _headEyesAwaitNeutral = false;
      _headEyesEyeClosedSince = null;
      _headEyesNeutralStillSince = null;
      _headEyesLastFaceSeenAt = null;
      _headEyesNoFaceStreak = 0;
      _headEyesConfirmAllowedAfter = null;
      _headEyesLiveHint = 'Initialisation de la caméra…';
    });
    if (kHeadEyesDebug) {
      debugPrint('[HeadEyesDebug] start mode requested');
    }

    await _disposeHeadEyesMode();

    final permitted = await _ensureHeadEyesCameraPermission();
    if (!permitted) {
      if (mounted) {
        setState(() {
          _headEyesInitializing = false;
          _headEyesPermissionDenied = true;
          _headEyesLiveHint =
              'Caméra refusée. Autorisez-la dans Paramètres > Applications > Ma3ak.';
        });
      }
      unawaited(_speakHeadEyes('Permission caméra refusée.', force: true));
      return;
    }

    _headEyesFaceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.fast,
        enableClassification: true,
        enableTracking: true,
        minFaceSize: 0.03,
      ),
    );

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        await _disposeHeadEyesMode();
        if (mounted) {
          setState(() {
            _headEyesInitializing = false;
            _headEyesLiveHint = 'Aucune caméra sur cet appareil.';
          });
        }
        unawaited(_speakHeadEyes('Aucune caméra détectée.', force: true));
      return;
    }
      final frontCameras = cameras
          .where((c) => c.lensDirection == CameraLensDirection.front)
          .toList();
      if (frontCameras.isEmpty) {
        await _disposeHeadEyesMode();
        if (mounted) {
          setState(() {
            _headEyesInitializing = false;
            _headEyesLiveHint =
                'Caméra avant non disponible. Le mode tête/yeux nécessite la caméra selfie.';
          });
        }
        unawaited(
          _speakHeadEyes(
            'Caméra avant non disponible. Ce mode nécessite la caméra selfie.',
            force: true,
          ),
        );
        return;
      }
      final front = frontCameras.first;

      var controller = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup:
            Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.nv21,
      );
      try {
        await controller.initialize();
        if (kHeadEyesDebug) {
          debugPrint(
            '[HeadEyesDebug] camera initialized: id=${front.name} lens=${front.lensDirection.name}',
          );
        }
      } catch (_) {
        await controller.dispose();
        controller = CameraController(
          front,
          ResolutionPreset.medium,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.yuv420,
        );
        await controller.initialize();
        if (kHeadEyesDebug) {
          debugPrint(
            '[HeadEyesDebug] camera initialized (fallback format): id=${front.name} lens=${front.lensDirection.name}',
          );
        }
      }

      if (!mounted) {
        await controller.dispose();
        return;
      }

    setState(() {
        _headEyesCamera = controller;
        _headEyesInitializing = false;
        _headEyesLiveHint =
            'Placez votre visage au centre. Tournez la tête ou fermez les yeux pour valider.';
      });

      try {
        await controller.startImageStream(_onHeadEyesCameraImage);
        if (kHeadEyesDebug) {
          debugPrint(
            '[HeadEyesDebug] image stream started: id=${front.name} lens=${front.lensDirection.name}',
          );
        }
      } catch (_) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
        await controller.startImageStream(_onHeadEyesCameraImage);
        if (kHeadEyesDebug) {
          debugPrint(
            '[HeadEyesDebug] image stream started after retry: id=${front.name} lens=${front.lensDirection.name}',
          );
        }
      }

      final armAt = DateTime.now().add(_headEyesConfirmGraceAfterStream);
      if (mounted) {
        setState(() {
          _headEyesConfirmAllowedAfter = armAt;
          _headEyesLastGestureConfirmAt = DateTime.now();
        });
      }
      if (kHeadEyesDebug) {
        debugPrint(
          '[HeadEyesDebug] confirmation armed at ${armAt.toIso8601String()}',
        );
      }

      unawaited(() async {
        await _speakHeadEyes(_headEyesIntroTts, force: true);
        if (!mounted || !_headEyesModeActive) return;
        await Future<void>.delayed(const Duration(milliseconds: 400));
        if (!mounted || !_headEyesModeActive) return;
        await _speakHeadEyes(
          'Choix actuel : ${_headEyesOptionLabels[_headEyesSelectedIndex]}',
          force: true,
        );
      }());
    } catch (e) {
      await _disposeHeadEyesMode();
      if (mounted) {
        setState(() {
          _headEyesInitializing = false;
          _headEyesLiveHint = 'Erreur caméra : $e';
        });
      }
      unawaited(_speakHeadEyes('Erreur caméra.', force: true));
    }
  }

  Future<void> _exitHeadEyesCameraMode() async {
    await _disposeHeadEyesMode();
    if (!mounted) return;
    setState(() {
      _headEyesModeActive = false;
      _headEyesInitializing = false;
      _headEyesPermissionDenied = false;
      _headEyesConfirmProgress = 0;
      _headEyesLiveHint = '';
    });
  }

  Future<void> _headEyesReplayInstructions() async {
    await _speakHeadEyes(_headEyesIntroTts, force: true);
  }

  Future<void> _headEyesReadAllChoices() async {
    final b = StringBuffer('Choix disponibles. ');
    for (var i = 0; i < _headEyesOptionLabels.length; i++) {
      b.write('${i + 1}. ${_headEyesOptionLabels[i]}. ');
    }
    await _speakHeadEyes(b.toString(), force: true);
  }

  void _headEyesBumpSelection(int delta) {
    final n = _headEyesOptionLabels.length;
    var next = (_headEyesSelectedIndex + delta) % n;
    if (next < 0) next += n;
    _headEyesSelectedIndex = next;
    _headEyesLastNavAt = DateTime.now();
    _headEyesAwaitNeutral = true;
    _headEyesPendingSelectionPrompt = _headEyesOptionLabels[_headEyesSelectedIndex];
    _setHeadEyesDebugSnapshot(gesture: 'navigation_${delta > 0 ? 'next' : 'prev'}');
    if (kHeadEyesDebug) {
      debugPrint(
        '[HeadEyesDebug] navigation trigger -> selected=$_headEyesSelectedIndex label=$_headEyesPendingSelectionPrompt',
      );
    }
    _setAssistantState('Choix sélectionné');
    _setHeadEyesLiveHint(
      'Choix sélectionné : $_headEyesPendingSelectionPrompt. Fermez les yeux pour confirmer.',
    );
    setState(() {});
    unawaited(
      _speakHeadEyes(
        '$_headEyesPendingSelectionPrompt sélectionné. Fermez les yeux pour confirmer.',
        force: true,
      ),
    );
  }

  void _handleHeadEyesFace(Face face) {
    if (!_headEyesModeActive || _headEyesInitializing || _headEyesNavigating) return;

    final y = face.headEulerAngleY;
    final left = face.leftEyeOpenProbability;
    final right = face.rightEyeOpenProbability;
    final now = DateTime.now();
    final confirmArmed = _headEyesConfirmAllowedAfter != null &&
        !now.isBefore(_headEyesConfirmAllowedAfter!);
    _setHeadEyesDebugSnapshot(
      faceDetected: true,
      yaw: y,
      leftEye: left,
      rightEye: right,
    );

    var progress = 0.0;
    var eyesClosedTracking = false;

    if (!confirmArmed) {
      _headEyesEyeClosedSince = null;
      _headEyesNeutralStillSince = null;
      if (_headEyesConfirmProgress > 0 && mounted) {
        setState(() => _headEyesConfirmProgress = 0);
      }
    } else if (left != null && right != null) {
      final minEye = math.min(left, right);
      final maxEye = math.max(left, right);
      if (minEye >= _headEyesEyeOpenMin) {
        _headEyesEyeClosedSince = null;
        _headEyesNeutralStillSince = null;
        if (_headEyesConfirmProgress > 0 && mounted) {
          setState(() => _headEyesConfirmProgress = 0);
        }
      } else if (maxEye <= _headEyesEyeClosedMax) {
        eyesClosedTracking = true;
        if (_headEyesEyeClosedSince == null) {
          _setHeadEyesDebugSnapshot(gesture: 'eyes_close_confirm_start');
          if (kHeadEyesDebug) {
            debugPrint(
              '[HeadEyesDebug] eyes close confirmation starts: left=${left?.toStringAsFixed(2)} right=${right?.toStringAsFixed(2)}',
            );
          }
        }
        _headEyesEyeClosedSince ??= now;
        _headEyesNeutralStillSince = null;
        final held = now.difference(_headEyesEyeClosedSince!);
        progress = (held.inMilliseconds / _headEyesEyeHoldConfirm.inMilliseconds)
            .clamp(0.0, 1.0);
      } else {
        // Zone ambiguë entre ouvert et fermé : ne pas valider par erreur.
        _headEyesEyeClosedSince = null;
        _headEyesNeutralStillSince = null;
      }
    } else if (left == null && right == null) {
      // Repli immobilité uniquement si ML Kit n'expose aucune proba (pas si une seule est null).
      if (y != null && y.abs() < _headEyesYawNeutral) {
        _headEyesNeutralStillSince ??= now;
        final st = now.difference(_headEyesNeutralStillSince!);
        progress =
            (st.inMilliseconds / _headEyesStillnessConfirm.inMilliseconds)
                .clamp(0.0, 1.0);
      } else {
        _headEyesNeutralStillSince = null;
      }
    } else {
      _headEyesNeutralStillSince = null;
      _headEyesEyeClosedSince = null;
    }

    if (progress != _headEyesConfirmProgress ||
        (progress > 0 && progress >= _headEyesConfirmProgress)) {
      if (mounted) {
        setState(() => _headEyesConfirmProgress = progress);
      }
    }

    final confirmReady = confirmArmed &&
        (eyesClosedTracking
            ? (_headEyesEyeClosedSince != null &&
                now.difference(_headEyesEyeClosedSince!) >=
                    _headEyesEyeHoldConfirm)
            : (left == null &&
                right == null &&
                _headEyesNeutralStillSince != null &&
                now.difference(_headEyesNeutralStillSince!) >=
                    _headEyesStillnessConfirm));

    if (confirmReady &&
        now.difference(_headEyesLastGestureConfirmAt) >=
            _headEyesGestureConfirmCooldown) {
      _setHeadEyesDebugSnapshot(gesture: 'confirm_complete');
      if (kHeadEyesDebug) {
        debugPrint('[HeadEyesDebug] confirmation completes');
      }
      _headEyesLastGestureConfirmAt = now;
      _headEyesEyeClosedSince = null;
      _headEyesNeutralStillSince = null;
      if (mounted) setState(() => _headEyesConfirmProgress = 0);
      unawaited(_headEyesOnConfirmGesture());
      return;
    }

    // Navigation latérale (désactivée pendant une validation visuelle forte)
    if (_headEyesConfirmProgress > 0.2) return;
    if (y == null) return;

    if (_headEyesAwaitNeutral) {
      if (y.abs() < _headEyesYawNeutral) {
        _setHeadEyesDebugSnapshot(gesture: 'neutral_reset');
        if (mounted) setState(() => _headEyesAwaitNeutral = false);
      }
      return;
    }

    if (now.difference(_headEyesLastNavAt) < _headEyesNavCooldown) return;

    if (y >= _headEyesYawNext) {
      _setHeadEyesDebugSnapshot(gesture: 'yaw_cross_next');
      if (kHeadEyesDebug) {
        debugPrint('[HeadEyesDebug] yaw crossed NEXT threshold: yaw=${y.toStringAsFixed(1)}');
      }
      _headEyesBumpSelection(1);
    } else if (y <= _headEyesYawPrev) {
      _setHeadEyesDebugSnapshot(gesture: 'yaw_cross_prev');
      if (kHeadEyesDebug) {
        debugPrint('[HeadEyesDebug] yaw crossed PREV threshold: yaw=${y.toStringAsFixed(1)}');
      }
      _headEyesBumpSelection(-1);
    }
  }

  Future<void> _headEyesOnConfirmGesture() async {
    if (!mounted || _headEyesNavigating) return;
    _headEyesNavigating = true;
    HapticFeedback.heavyImpact();
    _setAssistantState('Prêt à naviguer');
    await _speakHeadEyes('Option sélectionnée.', force: true);
    final idx = _headEyesSelectedIndex;

    await _exitHeadEyesCameraMode();

    if (!mounted) {
      _headEyesNavigating = false;
      return;
    }

    switch (idx) {
      case 0:
        _lastInputModeHint = _InputModeHint.headEyes;
        _hasNavigatedFromAi = true;
        context.push('/create-post-voice-vibration');
        return;
      case 1:
        _hasNavigatedFromAi = true;
        context.push('/community-live?host=1');
        return;
      case 2:
        _hasNavigatedFromAi = true;
        context.push('/community-posts?mode=readPost');
        return;
      case 3:
        _hasNavigatedFromAi = true;
        context.push('/community-posts?mode=readComments');
        return;
      case 4:
        _hasNavigatedFromAi = true;
        context.push('/community-posts?mode=voiceComment');
        return;
      default:
        _headEyesNavigating = false;
        return;
    }
  }

  Future<void> _deleteMyLatestCommunityPost() async {
    final user = ref.read(authStateProvider).valueOrNull;
    final currentUserId = user?.id.trim();
    if (currentUserId == null || currentUserId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(content: Text('Connectez-vous pour supprimer votre post.')),
        );
      }
      await _speakHeadEyes('Connexion requise pour supprimer votre dernier post.', force: true);
      return;
    }

    try {
      final bundle = await ref.read(
        communityFeedProvider((
          page: 1,
          limit: 30,
          smart: false,
        )).future,
      );
      final mine = bundle.posts.where((p) => p.userId.trim() == currentUserId).toList();
      if (mine.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            const SnackBar(content: Text('Vous n’avez pas encore de post à supprimer.')),
          );
        }
        await _speakHeadEyes('Vous n avez pas encore de post a supprimer.', force: true);
        return;
      }

      final post = mine.first;
      await ref.read(communityRepositoryProvider).deletePost(post.id);
      ref.invalidate(communityFeedProvider((page: 1, limit: 20, smart: false)));
      ref.invalidate(communityFeedProvider((page: 1, limit: 20, smart: true)));
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(content: Text('Votre dernier post a été supprimé.')),
        );
      }
      await _speakHeadEyes('Votre dernier post a été supprime.', force: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text('Suppression impossible: $e')),
        );
      }
      await _speakHeadEyes('Suppression impossible.', force: true);
    }
  }

  Face _pickLargestFace(List<Face> faces) {
    if (faces.length == 1) return faces.first;
    Face best = faces.first;
    var bestArea =
        best.boundingBox.width.abs() * best.boundingBox.height.abs();
    for (final face in faces.skip(1)) {
      final area = face.boundingBox.width.abs() * face.boundingBox.height.abs();
      if (area > bestArea) {
        best = face;
        bestArea = area;
      }
    }
    return best;
  }

  bool _faceCoverageTooSmall(Face face, CameraImage image) {
    final imageArea = (image.width * image.height).toDouble();
    if (imageArea <= 0) return false;
    final faceArea =
        face.boundingBox.width.abs() * face.boundingBox.height.abs();
    final coverage = faceArea / imageArea;
    return coverage < _headEyesMinFaceCoverage;
  }

  Future<void> _onHeadEyesCameraImage(CameraImage image) async {
    if (_headEyesProcessingFrame ||
        !_headEyesModeActive ||
        _headEyesFaceDetector == null ||
        _headEyesNavigating) {
      return;
    }
    final now = DateTime.now();
    if (now.difference(_headEyesLastFrameHandledAt) < _headEyesFrameThrottle) {
      return;
    }
    _headEyesLastFrameHandledAt = now;
    final controller = _headEyesCamera;
    if (controller == null || !controller.value.isInitialized) return;
    final streamState = controller.value.isStreamingImages;
    if (streamState != _headEyesLastStreamState) {
      _headEyesLastStreamState = streamState;
      if (kHeadEyesDebug) {
        debugPrint('[HeadEyesDebug] camera streaming state changed: $streamState');
      }
    }

    _headEyesProcessingFrame = true;
    try {
      final input = _headEyesToInputImage(image, controller.description);
      if (input == null) return;
      final faces = await _headEyesFaceDetector!.processImage(input);
      if (!mounted || faces.isEmpty) {
        _setHeadEyesDebugSnapshot(faceDetected: false, gesture: 'mlkit_no_face');
        if (!_headEyesLastNoFaceLogged && kHeadEyesDebug) {
          _headEyesLastNoFaceLogged = true;
          debugPrint('[HeadEyesDebug] ML Kit: no face detected');
        }
        _headEyesNoFaceStreak += 1;
        final nowNoFace = DateTime.now();
        final recentFaceSeen = _headEyesLastFaceSeenAt != null &&
            nowNoFace.difference(_headEyesLastFaceSeenAt!) <= _headEyesNoFaceGrace;
        final shouldWarn = !recentFaceSeen &&
            _headEyesNoFaceStreak >= _headEyesNoFaceWarnStreak;
        if (shouldWarn) {
          _setHeadEyesLiveHint('Pas de visage — rapprochez le téléphone et centrez le visage.');
        }
        final ttsNow = DateTime.now();
        if (shouldWarn &&
            ttsNow.difference(_headEyesLastNoFaceTtsAt) >=
                _headEyesNoFaceTtsMinGap) {
          _headEyesLastNoFaceTtsAt = ttsNow;
          unawaited(
            _speakHeadEyes(
              'Visage non détecté. Essayez de vous placer devant la caméra.',
              force: true,
            ),
          );
        }
        return;
      }
      _headEyesLastNoFaceLogged = false;
      if (kHeadEyesDebug) {
        debugPrint('[HeadEyesDebug] ML Kit: face detected count=${faces.length}');
      }
      final targetFace = _pickLargestFace(faces);
      if (_faceCoverageTooSmall(targetFace, image)) {
        _headEyesNoFaceStreak += 1;
        _setHeadEyesLiveHint(
          'Visage trop loin — rapprochez le téléphone ou votre visage.',
        );
        return;
      }
      _headEyesLastFaceSeenAt = DateTime.now();
      _headEyesNoFaceStreak = 0;
      _setHeadEyesLiveHint('');
      _handleHeadEyesFace(targetFace);
    } catch (_) {
    } finally {
      _headEyesProcessingFrame = false;
    }
  }

  Widget _buildLargeHeadEyesTouchZone(ThemeData theme, ColorScheme scheme) {
    return Semantics(
      button: true,
      label: 'Utiliser tête et yeux. Touchez n’importe où dans la grande zone.',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _isAnalyzing ? null : () => unawaited(_onTapLargeHeadEyesZone()),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2563EB), Color(0xFF4F46E5), Color(0xFF7C3AED)],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.face_retouching_natural,
                    size: 96,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'UTILISER TETE & YEUX',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Touchez n’importe où pour activer',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Color(0xFF22C55E),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Caméra active',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeadEyesModePanel(ThemeData theme, ColorScheme scheme) {
    final cam = _headEyesCamera;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Mode caméra tête / yeux',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        if (_headEyesPermissionDenied)
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _headEyesLiveHint.isNotEmpty
                    ? _headEyesLiveHint
                    : 'Autorisez la caméra pour utiliser ce mode.',
                style: const TextStyle(color: Colors.white, height: 1.4),
              ),
            ),
          )
        else if (_headEyesInitializing || cam == null || !cam.value.isInitialized)
          const SizedBox(
            height: 200,
            child: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          )
        else
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: cam.value.aspectRatio,
              child: CameraPreview(cam),
            ),
          ),
        if (_headEyesLiveHint.isNotEmpty && !_headEyesPermissionDenied)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              _headEyesLiveHint,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.92),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        const SizedBox(height: 16),
        if (kHeadEyesDebug)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.38),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: DefaultTextStyle(
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('cameraInitialized=${cam?.value.isInitialized == true}'),
                  Text('streamingImages=${cam?.value.isStreamingImages == true}'),
                  Text('faceDetected=${_headEyesFaceDetectedDebug}'),
                  Text('yaw=${_headEyesLastYaw?.toStringAsFixed(2) ?? '-'}'),
                  Text('leftEyeOpen=${_headEyesLastLeftEye?.toStringAsFixed(2) ?? '-'}'),
                  Text('rightEyeOpen=${_headEyesLastRightEye?.toStringAsFixed(2) ?? '-'}'),
                  Text('selectedOption=$_headEyesSelectedIndex'),
                  Text('awaitNeutral=$_headEyesAwaitNeutral'),
                  Text('lastGesture=$_headEyesLastGestureDebug'),
                  Text('confirmProgress=${_headEyesConfirmProgress.toStringAsFixed(2)}'),
                  Text(
                    'confirmArmed=${() {
                      final t = _headEyesConfirmAllowedAfter;
                      if (t == null) return 'non';
                      return DateTime.now().isBefore(t) ? 'plus tard (${t.toIso8601String()})' : 'oui';
                    }()}',
                  ),
                  Text(
                    'camera=${cam == null ? 'null' : '${cam.description.name}/${cam.description.lensDirection.name}'}',
                  ),
                ],
              ),
            ),
          ),
        if (_headEyesConfirmProgress > 0)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Validation… gardez la pose',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.95),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _headEyesConfirmProgress,
                minHeight: 8,
                borderRadius: BorderRadius.circular(8),
                backgroundColor: Colors.white24,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
            ],
          ),
        for (var i = 0; i < _headEyesOptionLabels.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Semantics(
              selected: i == _headEyesSelectedIndex,
              label: _headEyesOptionLabels[i],
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: i == _headEyesSelectedIndex
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: i == _headEyesSelectedIndex
                        ? const Color(0xFF6366F1)
                        : Colors.white54,
                    width: i == _headEyesSelectedIndex ? 3 : 1,
                  ),
                  boxShadow: i == _headEyesSelectedIndex
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 30,
                        height: 30,
                        child: i == _headEyesSelectedIndex
                            ? Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value: _headEyesConfirmProgress > 0
                                        ? _headEyesConfirmProgress
                                        : null,
                                    strokeWidth: 3,
                                    color: const Color(0xFF4F46E5),
                                    backgroundColor: const Color(0xFFCBD5E1),
                                  ),
                                  const Icon(
                                    Icons.radio_button_checked,
                                    color: Color(0xFF4F46E5),
                                    size: 18,
                                  ),
                                ],
                              )
                            : const Icon(
                                Icons.radio_button_off,
                                color: Colors.white70,
                                size: 28,
                              ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          _headEyesOptionLabels[i],
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                            color: i == _headEyesSelectedIndex
                                ? const Color(0xFF0F172A)
                                : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            FilledButton.tonal(
              onPressed: () => unawaited(_headEyesReadAllChoices()),
              child: const Text('Lire les choix'),
            ),
            FilledButton.tonal(
              onPressed: () => unawaited(_headEyesReplayInstructions()),
              child: const Text('Réécouter les options'),
            ),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white70),
              ),
              onPressed: () {
                setState(() => _showKeyboardFallback = true);
                unawaited(_exitHeadEyesCameraMode());
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _inputFocusNode.requestFocus();
                });
              },
              child: const Text('Utiliser le clavier'),
            ),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white70),
              ),
              onPressed: () => unawaited(_exitHeadEyesCameraMode()),
              child: const Text('Quitter le mode caméra'),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildBottomEssentialControls(ThemeData theme, ColorScheme scheme) {
    Widget cell({
      required IconData icon,
      required String label,
      required VoidCallback? onTap,
      required String semanticsLabel,
    }) {
      return Semantics(
        button: true,
        label: semanticsLabel,
        child: Material(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: scheme.primary, size: 26),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: cell(
            icon: Icons.keyboard_alt_outlined,
            label: 'Clavier',
            semanticsLabel: 'Saisir au clavier',
            onTap: _isAnalyzing ? null : _openKeyboardInput,
          ),
        ),
      ],
    );
  }

  Widget _buildUnifiedAudioModeButtons() {
    Widget audioButton({
      required IconData icon,
      required String label,
      required String route,
    }) {
      return FilledButton.tonalIcon(
        onPressed: _isAnalyzing
            ? null
            : () {
                if (!mounted || _hasNavigatedFromAi) return;
                _hasNavigatedFromAi = true;
                context.push(route);
              },
        icon: Icon(icon),
        label: Text(label),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        audioButton(
          icon: Icons.record_voice_over_outlined,
          label: 'Lire les posts',
          route: '/community-posts?mode=readPost',
        ),
        audioButton(
          icon: Icons.forum_outlined,
          label: 'Lire commentaires',
          route: '/community-posts?mode=readComments',
        ),
        audioButton(
          icon: Icons.mic_none_rounded,
          label: 'Commenter avec la voix',
          route: '/community-posts?mode=voiceComment',
        ),
      ],
    );
  }

  Widget _buildPostSuggestionChips(ThemeData theme) {
    final text = _resolveRawTextForAnalysis();
    final suggestions = _postSuggestionRoutes(text);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final s in suggestions.take(3))
          ActionChip(
            label: Text(s.label),
            onPressed: _isAnalyzing
                ? null
                : () {
                    if (!mounted || _hasNavigatedFromAi) return;
                    _setAssistantState('Prêt à naviguer');
                    _hasNavigatedFromAi = true;
                    context.push(s.route);
                  },
            avatar: const Icon(Icons.arrow_outward_rounded, size: 16),
            labelStyle: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }

  String get _assistantDynamicText {
    if (_isAnalyzing) return 'Analyse en cours';
    if (_isListeningUi) return 'Je vous écoute';
    return _assistantStateText;
  }

  Widget _buildWaveform(ColorScheme scheme) {
    return AnimatedBuilder(
      animation: _listenPulseController,
      builder: (context, _) {
        final t = _isListeningUi ? _listenPulseController.value : 0.18;
        final bars = List.generate(18, (i) {
          final phase = (i % 6) / 6;
          final h = 6 + ((_isListeningUi ? 24 : 10) * (0.35 + (t + phase) % 1));
          return Container(
            width: 4,
            height: h,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: _isListeningUi ? 0.95 : 0.55),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        });
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final b in bars) ...[b, const SizedBox(width: 3)],
          ],
        );
      },
    );
  }

  Widget _buildHeroMicrophone(ThemeData theme, ColorScheme scheme) {
    final micActive = _isListeningUi;
    const double outer = 188;
    const double inner = 148;

    return Column(
      children: [
        AnimatedBuilder(
          animation: _listenPulseController,
          builder: (context, _) {
            final pulse = micActive ? _listenPulseController.value : 0.0;
            final glow = 12 + pulse * 18;
            return Container(
              width: outer,
              height: outer,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: micActive
                    ? [
                        BoxShadow(
                          color: scheme.primary.withValues(alpha: 0.28 + pulse * 0.12),
                          blurRadius: glow,
                          spreadRadius: 2 + pulse * 4,
                        ),
                        BoxShadow(
                          color: scheme.primary.withValues(alpha: 0.12),
                          blurRadius: 6,
                          spreadRadius: 0,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: scheme.shadow.withValues(alpha: 0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
              ),
              child: Transform.scale(
                scale: micActive ? 1.0 + pulse * 0.04 : 1.0,
                child: Semantics(
                  label: micActive
                      ? 'Écoute en cours. Appuyez pour arrêter et analyser'
                      : 'Parler à l’assistant',
                  button: true,
                  child: Tooltip(
                    message: micActive
                        ? 'Appuyez pour arrêter et analyser'
                        : 'Appuyez pour parler',
                    child: SizedBox(
                      width: inner,
                      height: inner,
                      child: FilledButton(
                        onPressed:
                            _isAnalyzing ? null : () => unawaited(_onMicPressed()),
                        style: FilledButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: EdgeInsets.zero,
                          elevation: micActive ? 6 : 2,
                          shadowColor: micActive
                              ? scheme.primary.withValues(alpha: 0.45)
                              : null,
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                        ),
                        child: DecoratedBox(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF1DA1F2),
                                Color(0xFF6366F1),
                                Color(0xFFE879F9),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              micActive ? Icons.stop_rounded : Icons.mic_rounded,
                              size: 62,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Text(
          'Assistant vocal',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _assistantDynamicText,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
            height: 1.35,
          ),
        ),
        const SizedBox(height: 16),
        _buildWaveform(scheme),
      ],
    );
  }


  Future<void> _runAiAnalysis(
    String rawText, {
    String? inputModeHint,
  }) async {
    final text = rawText.trim();
    if (text.isEmpty || _isAnalyzing) return;
    if (_isStandaloneVisualProfilePhrase(text)) {
      _navigateVoiceDictationPost();
      return;
    }
    if (_isBlindPhotoOrPlaceReportPhrase(text)) {
      _navigateBlindPhotoOrReportHeadGesture();
      return;
    }
    if (_isVoicePostVisualCompoundPhrase(text)) {
      _navigateVoiceDictationPost();
      return;
    }
    if (_isObstacleHeadGestureRequest(text)) {
      _navigateObstacleHeadGesture();
      return;
    }
    if (_isOpenHeadEyesCameraCommand(text)) {
      _navigateObstacleHeadGesture();
      return;
    }
    if (_isLaunchLiveRequest(text)) {
      if (!mounted || _hasNavigatedFromAi) return;
      _hasNavigatedFromAi = true;
      context.push('/community-live?host=1');
      return;
    }
    if (_isVoiceCommentRequest(text)) {
      if (!mounted || _hasNavigatedFromAi) return;
      _hasNavigatedFromAi = true;
      context.push('/community-posts?mode=voiceComment');
      return;
    }
    if (_isReadCommentsAudioRequest(text)) {
      if (!mounted || _hasNavigatedFromAi) return;
      _hasNavigatedFromAi = true;
      context.push('/community-posts?mode=readComments');
      return;
    }
    if (_isReadPostsAudioRequest(text)) {
      if (!mounted || _hasNavigatedFromAi) return;
      _hasNavigatedFromAi = true;
      context.push('/community-posts?mode=readPost');
      return;
    }
    if (_isReadCommentsAudioListRequest(text)) {
      if (!mounted || _hasNavigatedFromAi) return;
      _hasNavigatedFromAi = true;
      context.push('/community-posts?mode=readCommentsAudio');
      return;
    }
    if (_isReadLatestPostCommentsRequest(text)) {
      await _openLatestCommunityPost(
        autoReadPost: true,
        autoReadComments: true,
      );
      return;
    }
    if (_isReadLatestPostSummaryRequest(text)) {
      await _openLatestCommunityPost(
        autoReadPost: true,
        autoReadSummary: true,
      );
      return;
    }
    if (isInformationAccessibleInfoHeadGesturePhrase(text)) {
      _pushHeadGestureEntryBypassAi();
      return;
    }
    if (_isOpenLatestPostRequest(text)) {
      await _openLatestCommunityPost(autoReadPost: true);
      return;
    }
    final intent = _detectIntent(text);

    // Référence synchrone : après await, [context] peut être désactivé (clavier,
    // navigation) alors que le messenger racine reste utilisable.
    final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);

    setState(() => _isAnalyzing = true);
    try {
      final result = await ref.read(
        communityActionPlanProvider((
          text: text,
          contextHint: 'post',
          inputModeHint:
              inputModeHint ??
              _lastInputModeHint?.apiValue ??
              _InputModeHint.keyboard.apiValue,
          isForAnotherPersonHint: null,
        )).future,
      );

      if (!mounted) return;
      if (_isNonPostAiDecision(result)) {
        final forcedRoute = _postEntryFallbackRoute(text);
        if (!_hasNavigatedFromAi) {
          _hasNavigatedFromAi = true;
          context.push(forcedRoute, extra: result);
        }
        return;
      }
      await _handleAiNavigation(
        result,
        fallbackIntent: intent,
        originalText: text,
      );
    } catch (e, stack) {
      debugPrint('CommunityAiEntry: analyse échouée: $e');
      debugPrint('$stack');
      if (!mounted) return;
      final detail = _userMessageForAiFailure(e);
      final fallbackRoute = _postEntryFallbackRoute(text);
      if (fallbackRoute != null && !_hasNavigatedFromAi) {
        _hasNavigatedFromAi = true;
        scaffoldMessenger?.showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 6),
            content: Text(
              'IA indisponible : ouverture du parcours conseillé.\n$detail',
            ),
          ),
        );
        if (!mounted) return;
        context.push(fallbackRoute);
      } else {
        scaffoldMessenger?.showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 8),
            content: Text(detail),
            action: SnackBarAction(
              label: 'Fil',
              onPressed: () {
                if (!mounted) return;
                context.push('/community-posts');
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        if (!_isListeningUi && !_hasNavigatedFromAi) {
          _setAssistantState('Prêt à naviguer');
        }
      }
    }
  }

  /// Phrase déjà classée côté client + même famille de parcours que la route IA.
  bool _intentMatchesRecommendedRoute(
    String route,
    _CommunityEntryIntent intent,
  ) {
    final r = route.toLowerCase();
    switch (intent) {
      case _CommunityEntryIntent.publish:
        return r.contains('create-post');
      case _CommunityEntryIntent.help:
        return r.contains('help');
      case _CommunityEntryIntent.location:
        return r.contains('community-location') ||
            r.contains('community-nearby');
      case _CommunityEntryIntent.unknown:
        return false;
    }
  }

  /// Navigation auto si la confiance suffit, ou si l’utilisateur a dit une phrase
  /// qu’on reconnaît et que la route IA va dans le même sens (évite de rester
  /// bloqué quand la confiance heuristique est basse).
  bool _shouldOpenRecommendedRouteAutomatically(
    CommunityActionPlanResult result,
    _CommunityEntryIntent fallbackIntent,
  ) {
    // Ne pas bloquer ici sur [requiresConfirmation] : si l’intention locale
    // correspond à la route IA, on ouvre (l’utilisateur vient déjà de valider
    // « Analyser »). La confirmation serveur reste reflétée dans le dialogue.
    final route = result.recommendedRoute?.trim();
    if (route == null || route.isEmpty) return false;
    if (route == '/create-post-head-gesture') return false;
    if (_isLowConfidenceResult(result)) return false;

    if (result.shouldAutoNavigateForEntryScreen(
          minConfidence: _autoNavigateMinConfidence,
        ) &&
        result.requiresConfirmation != true) {
      return true;
    }
    if (fallbackIntent != _CommunityEntryIntent.unknown &&
        _intentMatchesRecommendedRoute(route, fallbackIntent)) {
      return true;
    }
    return false;
  }

  Future<void> _handleAiNavigation(
    CommunityActionPlanResult result, {
    required _CommunityEntryIntent fallbackIntent,
    required String originalText,
  }) async {
    if (!mounted || _hasNavigatedFromAi) return;

    var route = result.recommendedRoute?.trim();
    if (!_isPostAllowedRoute(route)) {
      route = _fallbackRouteForIntent(fallbackIntent) ?? '/create-post';
    }
    if (route != null && route.isNotEmpty) {
      final lowConfidence = _isLowConfidenceResult(result);
      if (lowConfidence) {
        _setAssistantState('Prêt à naviguer');
        setState(() => _showPostSuggestions = true);
        await _speakDictationGuidance(
          'Je ne suis pas sûr. Voulez-vous publier un post ?',
        );
      } else {
        setState(() => _showPostSuggestions = false);
      }

      if (_shouldOpenRecommendedRouteAutomatically(result, fallbackIntent)) {
        _setAssistantState('Prêt à naviguer');
        await _speakDictationGuidance(
          'Publication détectée. Ouverture du bon écran.',
        );
        await Future<void>.delayed(const Duration(milliseconds: 500));
        _hasNavigatedFromAi = true;
        context.push(route, extra: result);
        return;
      }

      final summary = result.decisionSummary?.trim();
      final reason = result.routeReason?.trim();
      final conf = result.confidence;
      final confidenceText = conf != null
          ? ' (confiance: ${(conf * 100).toStringAsFixed(0)}%)'
          : '';
      final core = (reason != null && reason.isNotEmpty)
          ? '$reason$confidenceText'
          : 'Suggestion: ouvrir $route$confidenceText';
      final message = (summary != null && summary.isNotEmpty)
          ? '$summary\n$core'
          : core;
      if (!lowConfidence) {
        await _speakDictationGuidance('Publication détectée. Choix sélectionné.');
      }
      await _presentRouteSuggestionDialog(
        route: route,
        result: result,
        message: message,
      );
      return;
    }

    final fallbackRoute = _postEntryFallbackRoute(originalText);
    if (fallbackRoute != null) {
      // Pas de route IA: fallback explicite par intention reconnue.
      _setAssistantState('Prêt à naviguer');
      _hasNavigatedFromAi = true;
      context.push(fallbackRoute, extra: result);
      return;
    }

    // Plan sans route explicite : ouvrir selon l’action métier renvoyée par l’API.
    if (!mounted) return;
    _hasNavigatedFromAi = true;
    context.push('/create-post', extra: result);
    return;

    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(
        content: Text('Analyse terminée. Vous pouvez continuer ici.'),
      ),
    );
  }

  _CommunityEntryIntent _detectIntent(String input) {
    final t = input.toLowerCase().trim();

    // Seul le profil visuel, sans autre demande : l’API choisit la dictée vocale (pas l’écran aide).
    if (_isStandaloneVisualProfilePhrase(t)) {
      return _CommunityEntryIntent.unknown;
    }

    if (t.contains('je veux publier') ||
        t.contains('je veux poster') ||
        t.contains('je veux poster une photo') ||
        t.contains('je veux faire une publication') ||
        t.contains('je veux signaler un obstacle') ||
        // Tunisien / arabizi — envoyer ou poster une photo
        t.contains('nhabet taswira') ||
        t.contains('nhab taswira') ||
        t.contains('nhbt taswira') ||
        t.contains('nb3th taswira')) {
      return _CommunityEntryIntent.publish;
    }

    if (t.contains('j’ai besoin d’aide') ||
        t.contains("j'ai besoin d’aide") ||
        t.contains('j\'ai besoin d\'aide') ||
        t.contains('aide rapide') ||
        t.contains('aide tactile') ||
        t.contains('aide tactile sos') ||
        t.contains('fisa') ||
        t.contains('fissa') ||
        t.contains('ani dhay3a') ||
        t.contains('ani dhaya3a') ||
        t.contains('ana dhay3a') ||
        t.contains('je suis perdu') ||
        t.contains('je suis bloqué') ||
        t.contains('urgence') ||
        // Profil handicaps — phrases courtes fréquentes à l’oral
        t.contains('non voyant') ||
        t.contains('non-voyant') ||
        t.contains('malvoyant') ||
        t.contains('mal voyant') ||
        t.contains('aveugle') ||
        t.contains('déficience visuelle') ||
        t.contains('deficience visuelle') ||
        t.contains('handicap visuel') ||
        t.contains('je suis sourd') ||
        t.contains('je suis sourde') ||
        t.contains('malentendant') ||
        t.contains('mal entendant')) {
      return _CommunityEntryIntent.help;
    }

    if (t.contains('je cherche un lieu accessible') ||
        t.contains('je veux voir les lieux') ||
        t.contains('je veux un lieu proche')) {
      return _CommunityEntryIntent.location;
    }

    // Signalement d’accessibilité / lieu (oral court, français ou tunisien).
    // Ex. « pas de rampe fi entrée mosquée » → publier une info à la communauté.
    if (t.contains('rampe') ||
        t.contains('escalier') ||
        t.contains('ascenseur') ||
        t.contains('entrée') ||
        t.contains('entree') ||
        t.contains('mosqu') ||
        t.contains('mosquee') ||
        t.contains('obstacle') ||
        t.contains('bloqué') ||
        t.contains('bloque') ||
        t.contains('dangereux') ||
        t.contains('dangereuse') ||
        t.contains('inaccessible')) {
      return _CommunityEntryIntent.publish;
    }

    return _CommunityEntryIntent.unknown;
  }

  String? _fallbackRouteForIntent(_CommunityEntryIntent intent) {
    switch (intent) {
      case _CommunityEntryIntent.publish:
      case _CommunityEntryIntent.help:
        return '/create-post';
      case _CommunityEntryIntent.location:
        return '/community-posts';
      case _CommunityEntryIntent.unknown:
        return '/create-post';
    }
  }

  /// Remplace l’ancienne SnackBar : un bandeau disparaît vite et donnait l’impression
  /// qu’« il n’y a rien à ouvrir » alors qu’une action était proposée.
  Future<void> _presentRouteSuggestionDialog({
    required String route,
    required CommunityActionPlanResult result,
    required String message,
  }) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          icon: Icon(
            Icons.touch_app_outlined,
            color: theme.colorScheme.primary,
            size: 32,
          ),
          title: const Text('Étape suivante'),
          content: SingleChildScrollView(
            child: Text(message),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Plus tard'),
            ),
            FilledButton(
          onPressed: () {
                Navigator.of(ctx).pop();
                if (!mounted || _hasNavigatedFromAi) return;
            _hasNavigatedFromAi = true;
            context.push(route, extra: result);
          },
              child: const Text('Ouvrir'),
        ),
          ],
        );
      },
    );
  }

  bool get _hasRecognizedText => _inputController.text.trim().isNotEmpty;

  bool get _isListeningUi =>
      _voiceSessionActive || (_speechReady && _speech.isListening);

  String get _volumeStateHint {
    if (_isAnalyzing) return 'Analyse en cours...';
    if (_isListeningUi) return 'Volume+ : arrêter et analyser';
    return 'Volume+ : démarrer la dictée';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistant intelligent'),
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0EA5E9), Color(0xFF4F46E5), Color(0xFFD946EF)],
            ),
          ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_headEyesModeActive) ...[
                        const SizedBox(height: 48),
                        _buildHeadEyesModePanel(theme, scheme),
                      ] else ...[
                      const SizedBox(height: 20),
                      if (!kIsWeb) ...[
                        SizedBox(
                          height: math.max(
                            320,
                            math.min(
                              constraints.maxHeight * 0.66,
                              560,
                            ),
                          ),
                          child: _buildLargeHeadEyesTouchZone(theme, scheme),
                        ),
                        const SizedBox(height: 16),
                      ] else ...[
                        Center(child: _buildHeroMicrophone(theme, scheme)),
                        const SizedBox(height: 16),
                      ],
                      DecoratedBox(
                                              decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                                                border: Border.all(
                            color: Colors.white.withValues(alpha: 0.28),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isListeningUi
                                    ? Icons.graphic_eq_rounded
                                    : Icons.record_voice_over_outlined,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _assistantDynamicText,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                      const SizedBox(height: 12),
                      _buildBottomEssentialControls(theme, scheme),
                      const SizedBox(height: 10),
                      _buildUnifiedAudioModeButtons(),
                                const SizedBox(height: 14),
                      Center(
                        child: Semantics(
                          button: true,
                          label: 'Mode classique communauté',
                          child: TextButton.icon(
                            onPressed: _openClassicModule,
                            icon: const Icon(
                              Icons.view_compact_alt_outlined,
                              color: Colors.white,
                            ),
                            label: Text(
                              'Mode classique',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Semantics(
                        liveRegion: true,
                        label: 'État du raccourci volume',
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.42),
                            ),
                          ),
                          child: Padding(
                                          padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                                          ),
                                          child: Text(
                              _volumeStateHint,
                                            textAlign: TextAlign.center,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                height: 1.25,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (_showPostSuggestions) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Je ne suis pas sûr. Suggestions:',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildPostSuggestionChips(theme),
                      ],
                      if (_hasRecognizedText) ...[
                        const SizedBox(height: 18),
                        Semantics(
                          label: 'Texte reconnu',
                          container: true,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHighest
                                  .withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color:
                                    scheme.outlineVariant.withValues(alpha: 0.45),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Texte reconnu',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _inputController.text.trim(),
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      AnimatedCrossFade(
                        duration: const Duration(milliseconds: 220),
                        crossFadeState: _showKeyboardFallback
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        firstChild: const SizedBox.shrink(),
                        secondChild: Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: Semantics(
                            textField: true,
                            label: 'Saisie optionnelle au clavier',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextField(
                                  controller: _inputController,
                                  focusNode: _inputFocusNode,
                                  minLines: 1,
                                  maxLines: 4,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) =>
                                      unawaited(_onKeyboardSubmit()),
                                  decoration: InputDecoration(
                                    hintText: 'Ex. : besoin près de la gare…',
                                    filled: true,
                                    suffixIcon: IconButton(
                                      onPressed: _isAnalyzing
                                          ? null
                                          : () => unawaited(_onKeyboardSubmit()),
                                      tooltip: 'Analyser et ouvrir',
                                      icon: const Icon(Icons.send_rounded),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () => setState(
                                      () => _showKeyboardFallback = false,
                                    ),
                                    icon: const Icon(Icons.keyboard_hide_rounded),
                                    label: const Text('Masquer le clavier'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: constraints.maxHeight > 640 ? 24 : 12),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
          ),
        ),
      ),
    );
  }
}
