import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../providers/auth_providers.dart';
import 'm3ak_create_post_launch.dart';
import 'm3ak_nav_key.dart';

class M3akGlobalAssistantLayer extends ConsumerStatefulWidget {
  const M3akGlobalAssistantLayer({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  ConsumerState<M3akGlobalAssistantLayer> createState() =>
      _M3akGlobalAssistantLayerState();
}

class _M3akGlobalAssistantLayerState
    extends ConsumerState<M3akGlobalAssistantLayer> {
  static const Duration _holdDuration = Duration(seconds: 3);
  static const Duration _cooldown = Duration(seconds: 2);

  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _stt = stt.SpeechToText();
  Timer? _holdTimer;
  DateTime? _lastTriggerAt;
  bool _sheetOpen = false;
  bool _holding = false;
  OverlayEntry? _assistantEntry;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initTts());
  }

  Future<void> _initTts() async {
    try {
      await _tts.awaitSpeakCompletion(true);
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
    } catch (_) {}
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _stt.stop();
    _tts.stop();
    _assistantEntry?.remove();
    _assistantEntry = null;
    super.dispose();
  }

  bool _isInCooldown() {
    final last = _lastTriggerAt;
    if (last == null) return false;
    return DateTime.now().difference(last) < _cooldown;
  }

  bool _hasEditableFocus() {
    final focus = FocusManager.instance.primaryFocus;
    if (focus == null) return false;
    final w = focus.context?.widget;
    return w is EditableText;
  }

  String _ttsLangCode() {
    final user = ref.read(authStateProvider).valueOrNull;
    final lang = (user?.preferredLanguage?.name ?? '').toLowerCase();
    return lang == 'ar' ? 'ar' : 'fr-FR';
  }

  Future<void> _speak(String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    try {
      await _tts.stop();
      await _tts.setLanguage(_ttsLangCode());
      await _tts.speak(t);
    } catch (_) {}
  }

  void _onPointerDown(PointerDownEvent _) {
    if (_sheetOpen) return;
    if (_isInCooldown()) return;
    if (_hasEditableFocus()) return;

    _holdTimer?.cancel();
    if (mounted) setState(() => _holding = true);
    _holdTimer = Timer(_holdDuration, () {
      _holdTimer = null;
      if (mounted) setState(() => _holding = false);
      _triggerAssistant();
    });
  }

  void _onPointerUp(PointerUpEvent _) {
    _holdTimer?.cancel();
    _holdTimer = null;
    if (mounted) setState(() => _holding = false);
  }

  void _onPointerCancel(PointerCancelEvent _) {
    _holdTimer?.cancel();
    _holdTimer = null;
    if (mounted) setState(() => _holding = false);
  }

  Future<void> _triggerAssistant() async {
    if (!mounted) return;
    if (_sheetOpen) return;

    HapticFeedback.mediumImpact();
    _lastTriggerAt = DateTime.now();
    _sheetOpen = true;

    // Sur Web, la TTS peut ne pas répondre ou ne pas compléter.
    // On ne bloque jamais l'ouverture du panneau d'écoute.
    unawaited(
      _speak('M3AK vous écoute. Quel problème souhaitez-vous signaler ?'),
    );

    // Feedback visuel immédiat (utile sur Chrome).
    final navState = m3akRootNavigatorKey.currentState;
    final overlayCtx = navState?.overlay?.context;
    final messenger =
        overlayCtx != null ? ScaffoldMessenger.maybeOf(overlayCtx) : null;
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      const SnackBar(
        content: Text('M3AK activé'),
        duration: Duration(seconds: 2),
      ),
    );

    if (!mounted) return;
    final overlay = navState?.overlay;
    if (overlay == null) {
      _sheetOpen = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _triggerAssistant();
      });
      return;
    }

    // IMPORTANT: sur Web, éviter showModalBottomSheet (dépend de Navigator context).
    // On utilise un OverlayEntry global.
    _assistantEntry?.remove();
    _assistantEntry = OverlayEntry(
      builder: (entryCtx) {
        return _AssistantOverlay(
          child: _AssistantSheet(
            speech: _stt,
            speak: _speak,
            ttsLangCode: _ttsLangCode,
            onClose: () => _closeAssistant(),
          ),
        );
      },
    );
    overlay.insert(_assistantEntry!);
  }

  void _closeAssistant() {
    _assistantEntry?.remove();
    _assistantEntry = null;
    _sheetOpen = false;
    try {
      _stt.stop();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_holding && kIsWeb)
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            left: 12,
            right: 12,
            child: IgnorePointer(
              child: Material(
                color: Colors.transparent,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Text(
                      'Maintenez 3 secondes…',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
              ),
            ),
          ),
        // Listener ne bloque pas les gestes/taps des widgets en dessous.
        Positioned.fill(
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: _onPointerDown,
            onPointerUp: _onPointerUp,
            onPointerCancel: _onPointerCancel,
          ),
        ),
      ],
    );
  }
}

class _AssistantSheet extends StatefulWidget {
  const _AssistantSheet({
    required this.speech,
    required this.speak,
    required this.ttsLangCode,
    required this.onClose,
  });

  final stt.SpeechToText speech;
  final Future<void> Function(String text) speak;
  final String Function() ttsLangCode;
  final VoidCallback onClose;

  @override
  State<_AssistantSheet> createState() => _AssistantSheetState();
}

class _AssistantSheetState extends State<_AssistantSheet> {
  bool _ready = false;
  bool _listening = false;
  String _recognized = '';
  String? _error;
  int _step = 0; // 0: menu, 1: dictée
  bool _wantPhoto = false;
  Timer? _choiceTimeout;
  bool _autoChoiceDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _choiceTimeout?.cancel();
    _choiceTimeout = null;
    super.dispose();
  }

  bool _looksLikePhotoIntent(String s) {
    final t = s.toLowerCase();
    // Français + arabe (basique) + variantes
    return t.contains('photo') ||
        t.contains('camera') ||
        t.contains('caméra') ||
        t.contains('image') ||
        t.contains('تصوير') ||
        t.contains('صورة') ||
        t.contains('كاميرا');
  }

  bool _looksLikeVocalIntent(String s) {
    final t = s.toLowerCase();
    return t.contains('vocal') ||
        t.contains('voix') ||
        t.contains('dicte') ||
        t.contains('dictée') ||
        t.contains('texte') ||
        t.contains('كتابة') ||
        t.contains('صوت');
  }

  Future<void> _start() async {
    try {
      _ready = await widget.speech.initialize(
        onStatus: (s) {
          if (s == 'done' || s == 'notListening') {
            if (mounted) setState(() => _listening = false);
          }
        },
        onError: (_) {
          if (mounted) setState(() => _listening = false);
        },
      );
    } catch (e) {
      _ready = false;
      _error = e.toString();
    }
    if (!mounted) return;
    setState(() {});
    if (_ready) {
      // Pour non-voyant: ne pas attendre un clic.
      // On pose la question et on écoute directement l'intention (photo/vocal).
      unawaited(
        widget.speak(
          "Tu veux faire quoi ? Dis 'photo' pour ouvrir la caméra, ou décris le problème pour un post vocal.",
        ),
      );
      await _listenForChoice();
    } else {
      await widget.speak('Microphone indisponible.');
    }
  }

  Future<void> _listenForChoice() async {
    if (!_ready) return;
    if (_autoChoiceDone) return;
    if (_listening) return;

    setState(() {
      _error = null;
      _listening = true;
      _recognized = '';
      _step = 0;
      _wantPhoto = false;
    });

    _choiceTimeout?.cancel();
    _choiceTimeout = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      if (_autoChoiceDone) return;
      // Par défaut: post vocal (le plus accessible si l'utilisateur ne prononce pas "photo")
      _autoChoiceDone = true;
      unawaited(_stop());
      unawaited(_startVoicePost());
    });

    await widget.speech.listen(
      localeId: widget.ttsLangCode() == 'ar' ? 'ar' : 'fr_FR',
      listenMode: stt.ListenMode.confirmation,
      onResult: (res) {
        if (!mounted) return;
        final txt = res.recognizedWords;
        setState(() => _recognized = txt);

        // Dès qu'on détecte une intention claire, on enchaîne sans attendre un clic.
        final isPhoto = _looksLikePhotoIntent(txt);
        final isVocal = _looksLikeVocalIntent(txt);
        if ((isPhoto || isVocal || res.finalResult) && !_autoChoiceDone) {
          _autoChoiceDone = true;
          _choiceTimeout?.cancel();
          _choiceTimeout = null;
          unawaited(_stop());

          if (isPhoto) {
            unawaited(_startVoicePostWithPhoto());
          } else if (isVocal) {
            unawaited(_startVoicePost());
          } else {
            // Si l'utilisateur commence à décrire directement, on considère "vocal".
            unawaited(_startVoicePost());
          }
        }
      },
    );
  }

  Future<void> _startVoicePost() async {
    setState(() {
      _step = 1;
      _recognized = '';
      _wantPhoto = false;
    });
    await widget.speak('Tu veux poster quoi ? Décris le problème.');
    await _listen();
  }

  Future<void> _startVoicePostWithPhoto() async {
    setState(() {
      _step = 1;
      _recognized = '';
      _wantPhoto = true;
    });
    await widget.speak('Décris le problème. Ensuite, je vais ouvrir la caméra.');
    await _listen();
  }

  Future<void> _listen() async {
    if (!_ready) return;
    if (_listening) return;
    setState(() {
      _error = null;
      _listening = true;
    });
    await widget.speech.listen(
      localeId: widget.ttsLangCode() == 'ar' ? 'ar' : 'fr_FR',
      listenMode: stt.ListenMode.dictation,
      onResult: (res) {
        setState(() {
          _recognized = res.recognizedWords;
        });
        if (res.finalResult) {
          setState(() => _listening = false);
        }
      },
    );
  }

  Future<void> _stop() async {
    try {
      await widget.speech.stop();
    } catch (_) {}
    if (!mounted) return;
    setState(() => _listening = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: 16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'M3AK',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _listening ? 'Écoute en cours…' : 'Prêt.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (_step == 0) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Tu veux faire quoi ?',
                style: theme.textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _ready ? _startVoicePost : null,
              icon: const Icon(Icons.edit_note),
              label: const Text('Poster un signalement (vocal)'),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _ready ? _startVoicePostWithPhoto : null,
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('Prendre une photo et publier'),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _recognized.isEmpty ? 'Décrivez le problème…' : _recognized,
                style: theme.textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: _listening ? _stop : _listen,
                    icon: Icon(_listening ? Icons.stop : Icons.mic_none),
                    label: Text(_listening ? 'Stop' : 'Parler'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _recognized.trim().isEmpty
                        ? null
                        : () async {
                            // Confirmation + ouverture de créer-post avec texte pré-rempli.
                            final rootCtx = m3akRootNavigatorKey.currentContext;
                            if (rootCtx != null) {
                              widget.onClose();
                              final content = _recognized.trim();
                              if (_wantPhoto) {
                                GoRouter.of(rootCtx).push(
                                  '/create-post',
                                  extra: M3akCreatePostLaunch(
                                    initialContent: content,
                                    autoOpenCamera: true,
                                    autoPublishAfterCamera: true,
                                  ),
                                );
                              } else {
                                GoRouter.of(rootCtx).push(
                                  '/create-post',
                                  extra: content,
                                );
                              }
                            } else {
                              widget.onClose();
                            }
                          },
                    icon: const Icon(Icons.send),
                    label: const Text('Continuer'),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          FilledButton(
            onPressed: widget.onClose,
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}

class _AssistantOverlay extends StatelessWidget {
  const _AssistantOverlay({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black45,
      child: SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Material(
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

