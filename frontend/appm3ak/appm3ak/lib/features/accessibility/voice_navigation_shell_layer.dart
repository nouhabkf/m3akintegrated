import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../m3ak_assist/m3ak_nav_key.dart';
import 'accessibility_post_prefs.dart';
import 'voice_navigation_parser.dart';

/// Erreurs STT fréquentes quand personne ne parle ou le signal est trop faible — pas un dysfonctionnement.
bool _isBenignSpeechError(String errorMsg) {
  switch (errorMsg) {
    case 'error_speech_timeout':
    case 'error_no_match':
      return true;
    default:
      return false;
  }
}

/// Enveloppe le corps du [MainShell] : micro flottant + feuille « assistant navigation vocale ».
class VoiceNavigationShellLayer extends StatefulWidget {
  const VoiceNavigationShellLayer({super.key, required this.child});

  final Widget child;

  @override
  State<VoiceNavigationShellLayer> createState() =>
      _VoiceNavigationShellLayerState();
}

class _VoiceNavigationShellLayerState extends State<VoiceNavigationShellLayer> {
  void _openSession() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetCtx) {
        return _VoiceNavSessionPanel(navigatorContext: context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        widget.child,
        Positioned(
          right: 10,
          bottom: 10,
          child: Semantics(
            button: true,
            label:
                'Assistant navigation vocale. Dites accueil, santé, transport, lieux, communauté, profil ou créer un post.',
            child: Tooltip(
              message: kIsWeb
                  ? 'Navigation vocale (Chrome demandera le micro)'
                  : 'Navigation vocale',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Material(
                    elevation: 10,
                    shadowColor: Colors.black54,
                    shape: const CircleBorder(),
                    color: theme.colorScheme.primary,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _openSession,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Icon(
                          Icons.mic,
                          size: 32,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Text(
                      'Vocal',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _VoiceNavSessionPanel extends StatefulWidget {
  const _VoiceNavSessionPanel({required this.navigatorContext});

  final BuildContext navigatorContext;

  @override
  State<_VoiceNavSessionPanel> createState() => _VoiceNavSessionPanelState();
}

class _VoiceNavSessionPanelState extends State<_VoiceNavSessionPanel> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _listening = false;
  bool _sessionActive = true;
  bool _utteranceInProgress = false;
  bool _keepAlive = true;

  String _status = 'Préparation…';
  String _lastHeard = '';
  String _latestPartial = '';
  Timer? _partialDebounce;

  VoiceNavCommand? _pendingCritical;

  /// True si cette session d'écoute a déjà déclenché une commande (évite double relance).
  bool _utteranceConsumedThisCycle = false;

  String _speechLocaleId = 'fr_FR';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startSession());
  }

  @override
  void dispose() {
    _sessionActive = false;
    _partialDebounce?.cancel();
    unawaited(_speech.stop());
    unawaited(_tts.stop());
    super.dispose();
  }

  Future<void> _startSession() async {
    if (!kIsWeb) {
      final mic = await Permission.microphone.request();
      if (!mic.isGranted) {
        if (mounted) {
          setState(() =>
              _status = 'Microphone refusé. Autorisez-le dans les paramètres.');
        }
        return;
      }
    }

    final ok = await _speech.initialize(
      onError: (SpeechRecognitionError e) {
        if (!mounted) return;
        if (kDebugMode) {
          debugPrint('[VoiceNav] STT onError: ${e.errorMsg} permanent=${e.permanent}');
        }
        // Sur Android, timeout / pas de match sont courants (émulateur sans micro, silence).
        if (_isBenignSpeechError(e.errorMsg)) {
          setState(() {
            _status = _keepAlive
                ? 'Pas de voix détectée. Nouvelle écoute…'
                : 'Parlez après le message, ou réessayez.';
          });
          return;
        }
        setState(() {
          _status =
              'Erreur reconnaissance: ${e.errorMsg}. Vérifiez Google Speech.';
        });
      },
    );
    if (!ok) {
      if (mounted) {
        setState(() => _status = 'Reconnaissance vocale indisponible.');
      }
      return;
    }

    // Ne pas bloquer le 1er écoute sur `locales()` (peut prendre plusieurs secondes sur Android).
    unawaited(_resolveSpeechLocale());

    try {
      await _tts.setLanguage('fr-FR');
      await _tts.setSpeechRate(0.45);
      await _tts.awaitSpeakCompletion(true);
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _status = kIsWeb
          ? 'Parlez. Sur le web, le texte reconnu s affiche ci-dessous.'
          : 'Écoute…';
    });

    // Message court : moins de charge UI et micro disponible plus vite.
    await _speak(
      'Dites une commande : accueil, posts, milieux, ou stop.',
    );
    if (mounted && _sessionActive) await _listenOnce();
  }

  Future<void> _resolveSpeechLocale() async {
    try {
      final locales = await _speech.locales();
      final fr = locales
          .where((l) => l.localeId.toLowerCase().startsWith('fr'))
          .toList();
      if (!mounted) return;
      setState(() {
        if (fr.isNotEmpty) {
          _speechLocaleId = fr.first.localeId;
        } else if (locales.isNotEmpty) {
          _speechLocaleId = locales.first.localeId;
        }
      });
    } catch (_) {}
  }

  void _scheduleListen() {
    Future<void>.delayed(const Duration(milliseconds: 420), () {
      if (_sessionActive && mounted) _listenOnce();
    });
  }

  Future<void> _listenOnce() async {
    if (!_sessionActive || !mounted) return;
    if (_listening) return;

    await _speech.stop();
    if (!_sessionActive || !mounted) return;

    _utteranceConsumedThisCycle = false;

    setState(() {
      _listening = true;
      _status = "J'écoute…";
    });

    if (kDebugMode) {
      debugPrint('[VoiceNav] listen start locale=$_speechLocaleId');
    }

    try {
      await _speech.listen(
        onResult: (r) {
          if (!mounted || _utteranceInProgress) return;
          _latestPartial = r.recognizedWords;
          if (kDebugMode) {
            debugPrint(
              '[VoiceNav] result final=${r.finalResult} len=${r.recognizedWords.length} «${r.recognizedWords}»',
            );
          }
          setState(() => _lastHeard = _latestPartial);
          _partialDebounce?.cancel();

          if (r.finalResult) {
            _utteranceConsumedThisCycle = true;
            _listening = false;
            unawaited(_finalizeUtterance(_latestPartial));
            return;
          }

          // >= 2 : "ok", "oui", "non"…
          if (_latestPartial.trim().length >= 2) {
            _partialDebounce = Timer(
              Duration(milliseconds: kIsWeb ? 1400 : 1600),
              () {
                if (!mounted || !_sessionActive || _utteranceInProgress) return;
                if (!_listening) return;
                final t = _latestPartial.trim();
                if (t.length >= 2) {
                  _utteranceConsumedThisCycle = true;
                  _listening = false;
                  unawaited(_finalizeUtterance(t));
                }
              },
            );
          }
        },
        // Assez long pour parler ; l’émulateur déclenche souvent error_speech_timeout si silence.
        listenFor: Duration(seconds: kIsWeb ? 25 : 30),
        pauseFor: Duration(seconds: kIsWeb ? 5 : 5),
        localeId: _speechLocaleId,
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          // Dictation: meilleure reconnaissance des phrases FR sur émulateur / OEM.
          listenMode: stt.ListenMode.dictation,
        ),
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[VoiceNav] listen error: $e\n$st');
      }
      _listening = false;
      if (_sessionActive && mounted) {
        setState(() => _status = 'Micro STT: $e');
        _scheduleListen();
      }
    } finally {
      if (kDebugMode) {
        debugPrint('[VoiceNav] listen session ended consumed=$_utteranceConsumedThisCycle');
      }
      // CRITIQUE: sans ça, si la session STT se termine sans finalResult,
      // `_listening` reste true et l'écoute ne redémarre jamais.
      _listening = false;
      if (mounted) setState(() {});
      if (_sessionActive &&
          _keepAlive &&
          mounted &&
          !_utteranceConsumedThisCycle &&
          !_utteranceInProgress) {
        _scheduleListen();
      }
    }
  }

  Future<void> _finalizeUtterance(String words) async {
    _partialDebounce?.cancel();
    try {
      await _speech.stop();
    } catch (_) {}
    if (_utteranceInProgress || !mounted) return;
    final trimmed = words.trim();
    if (trimmed.isEmpty) {
      if (_sessionActive && mounted) _scheduleListen();
      return;
    }
    _utteranceInProgress = true;
    try {
      await _handleFinal(trimmed);
    } finally {
      _utteranceInProgress = false;
    }
  }

  bool _isYes(String t) {
    final s = t.toLowerCase().trim();
    return s == 'oui' ||
        s == 'ok' ||
        s.contains("d'accord") ||
        s.contains('daccord') ||
        s.contains('confirme') ||
        s.contains('valide');
  }

  bool _isNo(String t) {
    final s = t.toLowerCase().trim();
    return s == 'non' || s.contains('annule') || s.contains('annuler');
  }

  bool _isCritical(VoiceNavCommand cmd) {
    return cmd == VoiceNavCommand.sosAlerts ||
        cmd == VoiceNavCommand.sosTactile;
  }

  String _getConfirmationText(VoiceNavCommand cmd) {
    switch (cmd) {
      case VoiceNavCommand.home:
        return "J'affiche l'accueil.";
      case VoiceNavCommand.health:
        return "Ouverture de votre espace santé.";
      case VoiceNavCommand.communityPosts:
        return 'Voici les publications de la communauté.';
      case VoiceNavCommand.community:
        return 'Ouverture des lieux et accessibilité.';
      case VoiceNavCommand.communityPlaces:
        return 'Ouverture des lieux.';
      case VoiceNavCommand.communityHelp:
        return "Ouverture des demandes d'aide.";
      case VoiceNavCommand.profile:
        return 'Ouverture du profil.';
      case VoiceNavCommand.createPost:
        return 'Ouverture de la création de post.';
      case VoiceNavCommand.sosAlerts:
        return "J'affiche les alertes d'urgence.";
      case VoiceNavCommand.sosTactile:
        return 'Ouverture du SOS tactile.';
      default:
        return "C'est fait.";
    }
  }

  Future<void> _speakAndListen(String text) async {
    if (!mounted || !_sessionActive) return;
    setState(() => _status = 'M3AK parle…');
    try {
      await _speech.stop();
    } catch (_) {}
    await _speak(text);
    if (!mounted || !_sessionActive) return;
    if (_keepAlive) _scheduleListen();
  }

  Future<void> _handleFinal(String words) async {
    if (!_sessionActive || !mounted) return;

    final pending = _pendingCritical;
    if (pending != null) {
      if (_isYes(words)) {
        _pendingCritical = null;
        await _apply(pending);
        await _speakAndListen(_getConfirmationText(pending));
        return;
      }
      if (_isNo(words)) {
        _pendingCritical = null;
        await _speakAndListen('Annulé.');
        return;
      }
      await _speakAndListen('Dites oui pour confirmer, ou non pour annuler.');
      return;
    }

    final cmd = VoiceNavigationParser.parse(words);

    if (cmd == VoiceNavCommand.stop) {
      await _speak("Compris, je ferme l'assistant. À bientôt.");
      _sessionActive = false;
      await _speech.stop();
      if (mounted) Navigator.of(context).pop();
      return;
    }

    if (cmd == VoiceNavCommand.unknown) {
      await _speakAndListen("Je n'ai pas compris. Pouvez-vous répéter ?");
      return;
    }

    if (_isCritical(cmd)) {
      _pendingCritical = cmd;
      await _speakAndListen(
        cmd == VoiceNavCommand.sosTactile
            ? 'Voulez-vous ouvrir le SOS tactile ? Dites oui ou non.'
            : 'Voulez-vous ouvrir les alertes SOS ? Dites oui ou non.',
      );
      return;
    }

    await _apply(cmd);
    await _speakAndListen(_getConfirmationText(cmd));
  }

  Future<void> _apply(VoiceNavCommand cmd) async {
    final rootCtx = m3akRootNavigatorKey.currentContext;
    final nav = (rootCtx != null && rootCtx.mounted)
        ? rootCtx
        : widget.navigatorContext;
    if (!nav.mounted) return;
    final router = GoRouter.of(nav);

    if (cmd == VoiceNavCommand.createPost) {
      final shortcut = await AccessibilityPostPrefs.getPostCreationShortcut();
      if (!nav.mounted) return;
      switch (shortcut) {
        case PostCreationShortcut.headGesture:
          router.push('/create-post-head-gesture');
          return;
        case PostCreationShortcut.vibration:
          router.push('/create-post-vibration');
          return;
        case PostCreationShortcut.voiceVibration:
          router.push('/create-post-voice-vibration');
          return;
        case PostCreationShortcut.form:
          router.push('/create-post');
          return;
      }
    }

    late final String location;
    switch (cmd) {
      case VoiceNavCommand.home:
        location = Uri(path: '/home', queryParameters: const {'tab': '0'})
            .toString();
        break;
      case VoiceNavCommand.health:
        location = Uri(path: '/home', queryParameters: const {'tab': '1'})
            .toString();
        break;
      case VoiceNavCommand.transport:
        location = Uri(path: '/home', queryParameters: const {'tab': '2'})
            .toString();
        break;
      case VoiceNavCommand.community:
        location = Uri(path: '/home', queryParameters: const {'tab': '3'})
            .toString();
        break;
      case VoiceNavCommand.communityPosts:
        location =
            Uri(path: '/home', queryParameters: const {'tab': '4'}).toString();
        break;
      case VoiceNavCommand.communityPlaces:
        location =
            Uri(path: '/home', queryParameters: const {'tab': '3'}).toString();
        break;
      case VoiceNavCommand.communityProches:
        location =
            Uri(path: '/home', queryParameters: const {'tab': '3'}).toString();
        break;
      case VoiceNavCommand.communityHelp:
        location = Uri(
          path: '/home',
          queryParameters: const {'tab': '4', 'communityTab': '3'},
        ).toString();
        break;
      case VoiceNavCommand.profile:
        location = Uri(path: '/home', queryParameters: const {'tab': '5'})
            .toString();
        break;
      case VoiceNavCommand.createPost:
        return;
      case VoiceNavCommand.createHelpRequest:
        router.push('/create-help-request');
        return;
      case VoiceNavCommand.sosTactile:
        router.push('/haptic-help');
        return;
      case VoiceNavCommand.sosAlerts:
        router.push('/sos-alerts');
        return;
      case VoiceNavCommand.emergencyContacts:
        router.push('/accompagnants');
        return;
      case VoiceNavCommand.submitPlace:
        router.push('/submit-location');
        return;
      case VoiceNavCommand.back:
        if (Navigator.of(nav).canPop()) {
          Navigator.of(nav).pop();
        }
        return;
      case VoiceNavCommand.stop:
      case VoiceNavCommand.unknown:
        return;
    }

    router.go(location);
    final loc = location;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final ctx = m3akRootNavigatorKey.currentContext;
      final c = (ctx != null && ctx.mounted) ? ctx : nav;
      if (!c.mounted) return;
      GoRouter.of(c).go(loc);
    });
  }

  Future<void> _speak(String text) async {
    if (kIsWeb) {
      await Future<void>.delayed(const Duration(milliseconds: 80));
      return;
    }
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {}
  }

  Future<void> _stopSession() async {
    _sessionActive = false;
    await _speech.stop();
    await _tts.stop();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Navigation vocale',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: _listening
                        ? const Color(0xFF22C55E)
                        : theme.colorScheme.outline.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _listening ? 'Micro: écoute en cours' : 'Micro: en pause',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _keepAlive
                        ? 'Mode mains-libres: activé'
                        : 'Mode mains-libres: désactivé',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Switch(
                  value: _keepAlive,
                  onChanged: (v) => setState(() => _keepAlive = v),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(_status, style: theme.textTheme.bodyMedium),
            if (_lastHeard.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Entendu : $_lastHeard',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Essayez : accueil — santé — transport — milieux — posts — lieux — proches — demandes d aide — créer un post — stop.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _stopSession,
              icon: const Icon(Icons.close),
              label: const Text("Fermer l'assistant"),
            ),
          ],
        ),
      ),
    );
  }
}
