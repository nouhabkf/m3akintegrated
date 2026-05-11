import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:camera/camera.dart';

import '../../../data/models/create_post_input.dart';
import '../../../providers/community_providers.dart';

class CommunityLiveScreen extends ConsumerStatefulWidget {
  const CommunityLiveScreen({
    this.postId,
    this.isHost = false,
    super.key,
  });

  final String? postId;
  final bool isHost;

  @override
  ConsumerState<CommunityLiveScreen> createState() => _CommunityLiveScreenState();
}

class _CommunityLiveScreenState extends ConsumerState<CommunityLiveScreen> {
  final List<_LiveMessage> _messages = <_LiveMessage>[
    _LiveMessage(author: 'Modérateur', text: 'Bienvenue dans le live.', mine: false),
  ];
  final TextEditingController _messageCtrl = TextEditingController();
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isListening = false;
  bool _ttsEnabled = true;
  bool _endingLive = false;
  final List<String> _liveTtsQueue = <String>[];
  bool _liveTtsBusy = false;
  CameraController? _liveCamera;
  bool _liveCameraReady = false;
  String? _liveCameraError;

  @override
  void initState() {
    super.initState();
    _initAudio();
    _initLiveCamera();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _messages.isEmpty) return;
      _enqueueLiveMessageRead(_messages.first);
    });
  }

  Future<void> _initAudio() async {
    await _tts.awaitSpeakCompletion(true);
    await _tts.setLanguage('fr-FR');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _tts.stop();
    _speech.stop();
    _liveCamera?.dispose();
    super.dispose();
  }

  Future<void> _initLiveCamera() async {
    try {
      final cams = await availableCameras();
      if (cams.isEmpty) {
        if (!mounted) return;
        setState(() => _liveCameraError = 'Aucune caméra disponible.');
        return;
      }
      final preferred = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cams.first,
      );
      final controller = CameraController(
        preferred,
        ResolutionPreset.medium,
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _liveCamera = controller;
        _liveCameraReady = true;
        _liveCameraError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _liveCameraError = 'Caméra indisponible: $e');
    }
  }

  Future<void> _speak(String text) async {
    if (!_ttsEnabled) return;
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> _toggleVoiceInput() async {
    if (_isListening) {
      await _speech.stop();
      if (!mounted) return;
      setState(() => _isListening = false);
      return;
    }
    final ok = await _speech.initialize(
      onStatus: (status) async {
        if (status == 'done' || status == 'notListening') {
          if (!mounted) return;
          setState(() => _isListening = false);
        }
      },
      onError: (_) {
        if (!mounted) return;
        setState(() => _isListening = false);
      },
    );
    if (!ok) return;
    if (!mounted) return;
    setState(() => _isListening = true);
    await _speech.listen(
      localeId: 'fr_FR',
      listenMode: stt.ListenMode.dictation,
      onResult: (r) {
        if (!mounted) return;
        setState(() => _messageCtrl.text = r.recognizedWords);
      },
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty) return;
    final msg = _LiveMessage(author: 'Vous', text: text, mine: true);
    setState(() {
      _messages.add(msg);
      _messageCtrl.clear();
    });
    _enqueueLiveMessageRead(msg);
  }

  Future<void> _drainLiveTtsQueue() async {
    if (_liveTtsBusy || !_ttsEnabled) return;
    _liveTtsBusy = true;
    try {
      while (_liveTtsQueue.isNotEmpty && mounted && _ttsEnabled) {
        final next = _liveTtsQueue.removeAt(0);
        await _tts.stop();
        await _tts.speak(next);
      }
    } finally {
      _liveTtsBusy = false;
    }
  }

  void _enqueueLiveMessageRead(_LiveMessage message) {
    final clean = message.text.trim();
    if (clean.isEmpty || !_ttsEnabled) return;
    _liveTtsQueue.add('${message.author} dit: $clean');
    _drainLiveTtsQueue();
  }

  Future<void> _endLiveAndCreateReplay() async {
    if (_endingLive) return;
    setState(() => _endingLive = true);
    try {
      final summary = _messages
          .where((m) => m.text.trim().isNotEmpty)
          .take(5)
          .map((m) => '${m.author}: ${m.text}')
          .join(' | ');
      final contenu = summary.isEmpty
          ? 'Replay du live terminé.'
          : 'Replay du live: $summary';
      await ref.read(communityRepositoryProvider).createPost(
            CreatePostInput(
              contenu: contenu,
              type: 'general',
              postNature: 'replay',
              inputMode: 'voice',
              needsAudioGuidance: true,
            ),
          );
      if (!mounted) return;
      await _speak('Live terminé. Replay publié comme post.');
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Live terminé: replay publié.')),
      );
      context.pop();
    } finally {
      if (mounted) setState(() => _endingLive = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live communauté'),
        actions: [
          IconButton(
            tooltip: _ttsEnabled ? 'Couper la lecture' : 'Activer la lecture',
            onPressed: () {
              setState(() => _ttsEnabled = !_ttsEnabled);
              if (_ttsEnabled) {
                _drainLiveTtsQueue();
              } else {
                _liveTtsQueue.clear();
                _tts.stop();
              }
            },
            icon: Icon(_ttsEnabled ? Icons.volume_up : Icons.volume_off),
          ),
          if (widget.isHost)
            TextButton.icon(
              onPressed: _endingLive ? null : _endLiveAndCreateReplay,
              icon: const Icon(Icons.stop_circle_outlined),
              label: const Text('Terminer'),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                width: double.infinity,
                height: 190,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF191919), Color(0xFF313131)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: _liveCameraReady && _liveCamera != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CameraPreview(_liveCamera!),
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.videocam, size: 58, color: Colors.white),
                            const SizedBox(height: 8),
                            Text(
                              _liveCameraError ?? 'Initialisation de la caméra...',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _messages.length,
                itemBuilder: (context, i) {
                  final m = _messages[i];
                  return Align(
                    alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      constraints: const BoxConstraints(maxWidth: 320),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: m.mine
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.author,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(m.text),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                children: [
                  TextField(
                    controller: _messageCtrl,
                    minLines: 1,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Écrire un message live...',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _toggleVoiceInput,
                          icon: Icon(_isListening ? Icons.hearing : Icons.mic_none),
                          label: Text(
                            _isListening ? 'Arrêter dictée' : 'Dicter message',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _sendMessage,
                          icon: const Icon(Icons.send),
                          label: const Text('Envoyer'),
                        ),
                      ),
                    ],
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

class _LiveMessage {
  const _LiveMessage({
    required this.author,
    required this.text,
    required this.mine,
  });

  final String author;
  final String text;
  final bool mine;
}
