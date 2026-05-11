import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../core/volume/android_volume_hub.dart';
import '../../data/models/post_model.dart';
import 'accessibility_post_handoff.dart';

/// Dictée vocale + « lecture » par vibrations (1 impulsion / mot) + validation au dos du téléphone.
class VoiceVibrationPostScreen extends StatefulWidget {
  const VoiceVibrationPostScreen({super.key});

  @override
  State<VoiceVibrationPostScreen> createState() =>
      _VoiceVibrationPostScreenState();
}

enum _Phase {
  idle,
  listening,
}

enum _VoiceVibrationFlowState {
  idle,
  listening,
  readyToPublish,
}

class _VoiceVibrationPostScreenState extends State<VoiceVibrationPostScreen> {
  /// Court mais exploitable ; évite les posts d’un seul caractère.
  static const int _minChars = 5;

  static bool _messageMeetsMinimum(String text) {
    final t = text.trim();
    if (t.isEmpty) return false;
    if (t.length >= _minChars) return true;
    final words = t.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    return words >= 2;
  }

  final stt.SpeechToText _speech = stt.SpeechToText();
  final ImagePicker _imagePicker = ImagePicker();
  Timer? _partialDebounce;
  Timer? _photoChoiceTimer;
  Future<bool> Function()? _previousVolumeUpPriority;

  _Phase _phase = _Phase.idle;
  bool _speechReady = false;
  String _selectedLocaleId = 'fr_FR';
  String _livePartial = '';
  String _finalText = '';
  /// Texte figé après « Terminer la dictée » (pour vibrations + publication).
  String _lockedMessage = '';
  String _status = '';
  final List<XFile> _extraImages = [];
  static const int _maxImages = 10;
  bool _photoChoiceActive = false;
  bool _returnHandoffOnPublish = false;
  double? _draftLatitude;
  double? _draftLongitude;
  String? _draftLocationSharingMode;

  final FlutterTts _tts = FlutterTts();
  /// File d’attente TTS : une phrase après l’autre, sans chevauchement.
  Future<void> _ttsChain = Future<void>.value();
  final Set<String> _guidanceSpokenKeys = <String>{};
  int _lastPhotoGuidanceCount = 0;

  static const String _ttsWelcome =
      'Voulez-vous dire quelque chose ? Appuyez sur Volume plus pour démarrer la dictée.';
  static const String _ttsHeadZoneOpening =
      'Ouverture du mode tête et yeux pour ajouter une photo.';
  static const String _ttsPhotoAdded =
      'Photo ajoutée. Vous pouvez ajouter un texte avec Volume plus ou publier.';
  static const String _ttsLocationAdded = 'Localisation ajoutée.';
  static const String _ttsDictationStarted =
      'Dictée démarrée. Parlez maintenant.';
  static const String _ttsDictationStopped =
      'Dictée terminée. Votre texte est prêt. Pour ajouter une photo, touchez la grande zone en haut.';
  static const String _ttsPublishReady =
      'Publication prête. Appuyez sur Volume plus pour publier ou utilisez le bouton publier.';
  static const String _ttsPublishSuccess =
      'Publication en cours de traitement. Vérifiez ensuite dans Mes posts.';

  _VoiceVibrationFlowState get _flowState {
    if (_phase == _Phase.listening) return _VoiceVibrationFlowState.listening;
    if (_extraImages.isNotEmpty || _messageMeetsMinimum(_lockedMessage)) {
      return _VoiceVibrationFlowState.readyToPublish;
    }
    return _VoiceVibrationFlowState.idle;
  }

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _status =
          'Non disponible sur le web (micro + vibrations + capteur de choc requis). Utilisez l’app sur téléphone.';
      return;
    }
    AndroidVolumeHub.ensureInitialized();
    _previousVolumeUpPriority = AndroidVolumeHub.onVolumeUpPriority;
    AndroidVolumeHub.onVolumeUpPriority = _onVolumeUp;
    _initSpeech();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final q = GoRouterState.of(context).uri.queryParameters;
      _returnHandoffOnPublish = q['returnHandoff'] == '1';
      if (q['photoIntent'] == '1') {
        _startPhotoChoiceWindow();
      }
      if (!kIsWeb) {
        unawaited(_initTtsAndWelcome());
      }
    });
  }

  Future<void> _initTtsAndWelcome() async {
    try {
      await _tts.awaitSpeakCompletion(true);
      await _tts.setLanguage('fr-FR');
      await _tts.setSpeechRate(0.44);
    } catch (_) {}
    await _speakGuidance(_ttsWelcome, dedupeKey: 'welcome');
  }

  /// [dedupeKey] : une seule fois par clé tant que l’écran est ouvert (sauf [force]).
  Future<void> _speakGuidance(
    String text, {
    String? dedupeKey,
    bool force = false,
  }) async {
    if (kIsWeb) return;
    if (!force && dedupeKey != null && _guidanceSpokenKeys.contains(dedupeKey)) {
      return;
    }

    _ttsChain = _ttsChain.then((_) async {
      if (!mounted) return;
      try {
        await _tts.stop();
        await _tts.setLanguage('fr-FR');
        await _tts.setSpeechRate(0.44);
        await _tts.speak(text);
        await _tts.awaitSpeakCompletion(true);
        if (dedupeKey != null && !force) {
          _guidanceSpokenKeys.add(dedupeKey);
        }
      } catch (_) {}
    });
    return _ttsChain;
  }

  void _maybeAnnouncePhotoAdded() {
    if (_extraImages.isEmpty) return;
    if (_extraImages.length == _lastPhotoGuidanceCount) return;
    _lastPhotoGuidanceCount = _extraImages.length;
    unawaited(_speakGuidance(_ttsPhotoAdded, dedupeKey: 'photo_$_lastPhotoGuidanceCount'));
  }

  bool get _hasDraftLocation => _draftLatitude != null && _draftLongitude != null;

  Future<void> _replayCurrentGuidance() async {
    if (kIsWeb) return;
    final String msg;
    if (_phase == _Phase.listening) {
      msg = _ttsDictationStarted;
    } else if (_flowState == _VoiceVibrationFlowState.readyToPublish) {
      msg = _ttsPublishReady;
    } else if (_extraImages.isNotEmpty) {
      msg = _ttsPhotoAdded;
    } else {
      msg = _ttsWelcome;
    }
    await _speakGuidance(msg, force: true);
  }

  Future<void> _initSpeech() async {
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      if (mounted) {
        setState(() {
          _speechReady = false;
          _status =
              'Microphone refusé. Autorisez-le pour démarrer la dictée.';
        });
      }
      return;
    }
    String? lastStatus;
    String? lastError;
    final ok = await _speech.initialize(
      onError: (e) {
        lastError = e.errorMsg;
        if (!mounted) return;
        setState(() {
          _speechReady = false;
          _status =
              'Erreur reconnaissance vocale: ${e.errorMsg}. Réessayez ou vérifiez Google Speech.';
        });
      },
      onStatus: (s) {
        lastStatus = s;
        if (!mounted) return;
        setState(() {});
      },
    );

    // Choisir une locale FR si dispo, sinon garder celle par défaut.
    try {
      final locales = await _speech.locales();
      _selectedLocaleId = _selectBestLocaleForTunisianSpeech(
        locales: locales,
        fallback: _selectedLocaleId,
      );
    } catch (_) {
      _selectedLocaleId = 'fr_FR';
    }

    if (mounted) {
      setState(() {
        _speechReady = ok;
        if (!ok) {
          _status = 'Reconnaissance vocale indisponible sur cet appareil.'
              '${lastStatus != null ? ' (status: $lastStatus)' : ''}'
              '${lastError != null ? ' (error: $lastError)' : ''}';
        } else {
          _status = '';
        }
      });
    }
  }

  String _selectBestLocaleForTunisianSpeech({
    required List<stt.LocaleName> locales,
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

    final priorities = <String>[
      'ar_tn',
      'fr_tn',
      'ar_ma',
      'ar_dz',
      'fr_fr',
      'ar_sa',
      'fr',
      'ar',
    ];
    return pickByPriority(priorities) ?? locales.first.localeId;
  }

  @override
  void dispose() {
    _photoChoiceTimer?.cancel();
    _partialDebounce?.cancel();
    unawaited(_speech.stop());
    unawaited(_tts.stop());
    if (AndroidVolumeHub.onVolumeUpPriority == _onVolumeUp) {
      AndroidVolumeHub.onVolumeUpPriority = _previousVolumeUpPriority;
    }
    super.dispose();
  }

  Future<bool> _onVolumeUp() async {
    if (!mounted || kIsWeb) return false;
    await _handlePrimaryAccessibilityShortcut();
    return true;
  }

  Future<void> _handlePrimaryAccessibilityShortcut() async {
    if (_phase == _Phase.listening) {
      await _finishDictationAndConfirm();
      return;
    }
    // Volume+ publie dès qu'il y a un brouillon valide (texte et/ou photo).
    final hasLocked = _messageMeetsMinimum(_lockedMessage);
    final hasDraft = _messageMeetsMinimum(_finalText);
    if (hasLocked || hasDraft || _extraImages.isNotEmpty) {
      if (!hasLocked && hasDraft) {
        _lockedMessage = _finalText.trim();
      }
      unawaited(_popHandoff());
      return;
    }
    await _startDictation();
  }

  Future<void> _startDictation() async {
    _photoChoiceTimer?.cancel();
    _photoChoiceActive = false;
    if (kIsWeb || _phase == _Phase.listening) return;
    if (!_speechReady) {
      await _initSpeech();
      if (!mounted || !_speechReady) return;
    }
    await _speech.stop();
    _partialDebounce?.cancel();
    if (!mounted) return;
    setState(() {
      _phase = _Phase.listening;
      _livePartial = '';
      _finalText = '';
      _status = '';
    });
    await _speakGuidance(_ttsDictationStarted);
    if (!mounted) return;
    try {
      await _speech.listen(
        onResult: (r) {
          if (!mounted) return;
          setState(() {
            _livePartial = r.recognizedWords;
            if (r.finalResult) _finalText = r.recognizedWords;
          });

          // Sur certains appareils, `finalResult` peut ne jamais arriver.
          // On “fige” le texte après une courte pause.
          _partialDebounce?.cancel();
          final t = r.recognizedWords.trim();
          if (t.length >= 3 && _phase == _Phase.listening) {
            _partialDebounce = Timer(const Duration(milliseconds: 1400), () {
              if (!mounted) return;
              if (_phase != _Phase.listening) return;
              setState(() => _finalText = _livePartial);
            });
          }
        },
        listenFor: const Duration(seconds: 120),
        pauseFor: const Duration(seconds: 4),
        localeId: _selectedLocaleId,
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          listenMode: stt.ListenMode.dictation,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _phase = _Phase.idle;
          _status =
              'Impossible de démarrer l’écoute.\n${e.runtimeType}: $e\nVérifiez “Services Google de reconnaissance vocale”.';
        });
      }
    }
  }

  Future<void> _finishDictationAndConfirm() async {
    if (_phase != _Phase.listening) return;
    _partialDebounce?.cancel();
    await _speech.stop();
    if (!mounted) return;

    final text = (_finalText.trim().isNotEmpty ? _finalText : _livePartial)
        .trim();
    if (!_messageMeetsMinimum(text)) {
      setState(() {
        _phase = _Phase.idle;
        _status = 'Message trop court.';
      });
      return;
    }

    setState(() {
      _lockedMessage = text;
      _phase = _Phase.idle;
      _status = '';
    });

    await _speakGuidance(_ttsDictationStopped);
    if (!mounted) return;
  }

  Future<void> _popHandoff() async {
    final t = _lockedMessage.trim();
    final hasText = _messageMeetsMinimum(t);
    final hasPhoto = _extraImages.isNotEmpty;
    if (!hasText && !hasPhoto) return;
    await _speakGuidance(_ttsPublishReady, force: true);
    if (!mounted) return;
    await _speakGuidance(_ttsPublishSuccess, force: true);
    if (!mounted) return;
    final handoff = AccessibilityPostHandoff(
      content: hasText ? t : 'Photo partagée via voix et vibrations.',
      images: List<XFile>.from(_extraImages),
      suggestedPostType: PostType.autre,
      // Si l'écran est autonome, on force la publication via CreatePost.
      autoPublish: !_returnHandoffOnPublish,
      latitude: _draftLatitude,
      longitude: _draftLongitude,
      locationSharingMode: _draftLocationSharingMode,
    );
    if (_returnHandoffOnPublish) {
      context.pop(handoff);
      return;
    }
    context.pushReplacement('/create-post', extra: handoff);
  }

  Future<void> _pickFromGallery() async {
    if (_extraImages.length >= _maxImages) return;
    var list = await _imagePicker.pickMultiImage(imageQuality: 85);
    if (kIsWeb && list.isEmpty) {
      final one = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (one != null) list = [one];
    }
    if (!mounted || list.isEmpty) return;
    setState(() {
      for (final x in list) {
        if (_extraImages.length >= _maxImages) break;
        _extraImages.add(x);
      }
    });
    _maybeAnnouncePhotoAdded();
  }

  void _startPhotoChoiceWindow() {
    _photoChoiceTimer?.cancel();
    setState(() {
      _photoChoiceActive = true;
      _status =
          'Photo: appuyez sur + pour prendre une photo. Sans action, la galerie s’ouvre automatiquement.';
    });
    _photoChoiceTimer = Timer(const Duration(seconds: 3), () async {
      if (!mounted || !_photoChoiceActive) return;
      setState(() => _photoChoiceActive = false);
      await _pickFromGallery();
    });
  }

  Future<void> _openHeadGestureFromVoice() async {
    if (_phase == _Phase.listening) return;
    await _speakGuidance(_ttsHeadZoneOpening, force: true);
    if (!mounted) return;
    final handoff = await context.push<AccessibilityPostHandoff?>(
      '/create-post-head-gesture?returnHandoff=1',
    );
    if (!mounted || handoff == null) return;
    setState(() {
      // Important: après "Tête & yeux", on reste dans ce flux et on n'auto-publie jamais.
      // Le texte éventuel n'est pas verrouillé ici; l'utilisateur peut encore dicter.
      if (handoff.content.trim().isNotEmpty) {
        _finalText = handoff.content.trim();
        _lockedMessage = handoff.content.trim();
      }
      for (final img in handoff.images) {
        if (_extraImages.length >= _maxImages) break;
        _extraImages.add(img);
      }
      _draftLatitude = handoff.latitude;
      _draftLongitude = handoff.longitude;
      _draftLocationSharingMode = handoff.locationSharingMode;
      if (_extraImages.isNotEmpty && _hasDraftLocation) {
        _status = 'Photo ajoutée. Localisation ajoutée. Vous pouvez dicter puis publier.';
      } else if (_extraImages.isNotEmpty) {
        _status = 'Photo ajoutée. Vous pouvez maintenant dicter un texte puis publier.';
      }
    });
    if (_hasDraftLocation) {
      unawaited(_speakGuidance(_ttsLocationAdded, force: true));
    }
    _maybeAnnouncePhotoAdded();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(title: const Text('Voix + vibrations')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _status,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
          ),
        ),
      );
    }

    final listening = _phase == _Phase.listening;
    final canManualPublish =
        (_messageMeetsMinimum(_lockedMessage) || _extraImages.isNotEmpty) &&
        _phase != _Phase.listening;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voix + vibrations'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 12,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: _buildHeadEyesPrimaryZone(
                theme: theme,
                listening: listening,
                busy: false,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (listening ||
                      _livePartial.isNotEmpty ||
                      _finalText.isNotEmpty)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          listening
                              ? (_livePartial.isEmpty ? '…' : _livePartial)
                              : _lockedMessage.isNotEmpty
                                  ? _lockedMessage
                                  : (_finalText.isNotEmpty
                                      ? _finalText
                                      : _livePartial),
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                    ),
                  if (_status.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _status,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
          Material(
            elevation: 6,
            color: theme.colorScheme.surface,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        minimumSize: const Size.fromHeight(56),
                      ),
                      onPressed: listening ? null : _startDictation,
                      icon: const Icon(Icons.mic),
                      label: const Text('Démarrer la dictée'),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Volume+ : démarrer / arrêter la dictée',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Après dictée ou photo : Volume+ pour publier',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        minimumSize: const Size.fromHeight(56),
                      ),
                      onPressed: canManualPublish
                          ? () => unawaited(_popHandoff())
                          : null,
                      icon: const Icon(Icons.send),
                      label: const Text('Publier'),
                    ),
                    if (!listening) ...[
                      const SizedBox(height: 6),
                      TextButton.icon(
                        onPressed: () => unawaited(_replayCurrentGuidance()),
                        icon: const Icon(Icons.record_voice_over_outlined),
                        label: const Text('Réécouter les instructions'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Zone principale accessible : plein écran sans photo, aperçu réduit avec photo.
  Widget _buildHeadEyesPrimaryZone({
    required ThemeData theme,
    required bool listening,
    required bool busy,
  }) {
    final enabled = !busy && !listening;
    final onPrimary = theme.colorScheme.onPrimary;
    final primary = theme.colorScheme.primary;

    if (_extraImages.isNotEmpty) {
      final path = _extraImages.first.path;
      return Semantics(
        button: true,
        label:
            'Photo ajoutée. Touchez pour ouvrir tête et yeux et ajouter une autre image.',
        child: Material(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? () => unawaited(_openHeadGestureFromVoice()) : null,
            splashColor: primary.withValues(alpha: 0.35),
            highlightColor: primary.withValues(alpha: 0.12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 120,
                  child: Image.file(
                    File(path),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => ColoredBox(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Icon(Icons.broken_image_outlined, color: primary),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle, color: primary, size: 28),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Photo ajoutée',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _hasDraftLocation
                              ? 'Localisation ajoutée. Touchez pour tête et yeux ou une autre photo.'
                              : 'Touchez pour tête et yeux ou une autre photo.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1.25,
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
      );
    }

    return Semantics(
      button: true,
      label:
          'Grande zone photo et tête et yeux. Touchez pour ajouter une photo ou utiliser tête et yeux.',
      child: Material(
        color: primary,
        borderRadius: BorderRadius.circular(28),
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? () => unawaited(_openHeadGestureFromVoice()) : null,
          splashColor: onPrimary.withValues(alpha: 0.22),
          highlightColor: onPrimary.withValues(alpha: 0.12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.face_retouching_natural,
                  size: 72,
                  color: onPrimary,
                ),
                const SizedBox(height: 12),
                Icon(
                  Icons.photo_camera_outlined,
                  size: 48,
                  color: onPrimary.withValues(alpha: 0.92),
                ),
                const SizedBox(height: 20),
                Text(
                  'Touchez pour ajouter une photo',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: onPrimary,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'La photo restera ici avant publication',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: onPrimary.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Ou utilisez tête et yeux',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: onPrimary.withValues(alpha: 0.88),
                    height: 1.35,
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
}
