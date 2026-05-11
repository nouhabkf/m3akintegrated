import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:appm3ak/m3ak_port/screens/gesture_illustrations.dart';
import 'package:appm3ak/m3ak_port/services/sign_chatbot_service.dart';
import 'package:video_player/video_player.dart';

class SignChatbotScreen extends StatefulWidget {
  const SignChatbotScreen({super.key});

  @override
  State<SignChatbotScreen> createState() => _SignChatbotScreenState();
}

class _SignChatbotScreenState extends State<SignChatbotScreen> {
  final SignChatbotService _chatbotService = const SignChatbotService();
  final FlutterTts _tts = FlutterTts();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<_ChatMessage> _messages = [];
  bool _isBotTyping = false;
  bool _voiceEnabled = true;
  List<String> _currentBotGestures = ['Bonjour'];
  int _gestureIndex = 0;
  Timer? _gestureTimer;

  @override
  void initState() {
    super.initState();
    _initTts();
    _messages.add(const _ChatMessage(
      author: ChatAuthor.bot,
      text:
          'Salut ! Je suis ton assistant IA en langue des signes. Pose-moi une question (urgence, transport, medecin...)',
    ));
    _startGestureLoop();
    _speakBotText(_messages.first.text);
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('fr-FR');
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.0);
    } catch (_) {
      // Keep silent fallback if TTS is not available.
      _voiceEnabled = false;
    }
  }

  void _startGestureLoop() {
    _gestureTimer?.cancel();
    _gestureTimer = Timer.periodic(const Duration(milliseconds: 1100), (_) {
      if (!mounted || _currentBotGestures.isEmpty) return;
      setState(() {
        _gestureIndex = (_gestureIndex + 1) % _currentBotGestures.length;
      });
    });
  }

  Future<void> _sendMessage() async {
    final raw = _inputController.text.trim();
    if (raw.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(author: ChatAuthor.user, text: raw));
      _isBotTyping = true;
    });
    _inputController.clear();
    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 650));

    final reply = _chatbotService.replyTo(raw);
    if (!mounted) return;
    setState(() {
      _isBotTyping = false;
      _messages.add(_ChatMessage(author: ChatAuthor.bot, text: reply.text));
      _currentBotGestures = reply.gestures.isEmpty ? ['Bonjour'] : reply.gestures;
      _gestureIndex = 0;
    });
    _speakBotText(reply.text);
    _scrollToBottom();
  }

  Future<void> _speakBotText(String text) async {
    if (!_voiceEnabled || text.trim().isEmpty) return;
    try {
      await _tts.stop();
      await Future.delayed(const Duration(milliseconds: 100)); // Délai pour éviter les conflits
      await _tts.speak(text);
    } catch (e) {
      // Ignorer les erreurs TTS pour garder l'UI responsive
      print('TTS Error: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _gestureTimer?.cancel();
    _tts.stop();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentGesture = _currentBotGestures[_gestureIndex % _currentBotGestures.length];
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A2E)),
        title: const Text(
          'IA Chat Signes',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.bold,
            fontSize: 19,
          ),
        ),
        actions: [
          IconButton(
            tooltip: _voiceEnabled ? 'Désactiver la voix' : 'Activer la voix',
            onPressed: () {
              setState(() => _voiceEnabled = !_voiceEnabled);
              if (!_voiceEnabled) {
                _tts.stop();
              }
            },
            icon: Icon(
              _voiceEnabled ? Icons.record_voice_over : Icons.volume_off,
              color: const Color(0xFF1A1A2E),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: _GestureVideoAvatar(
                      gestureName: currentGesture,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Personne virtuelle',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Geste en cours: $currentGesture',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _currentBotGestures.join('  →  '),
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
              itemCount: _messages.length + (_isBotTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isBotTyping && index == _messages.length) {
                  return const _TypingBubble();
                }
                final message = _messages[index];
                final isUser = message.author == ChatAuthor.user;
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    constraints: const BoxConstraints(maxWidth: 320),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF2563EB) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: isUser
                          ? null
                          : Border.all(color: Colors.black.withValues(alpha: 0.06)),
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(
                        color: isUser ? Colors.white : const Color(0xFF1A1A2E),
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 14),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Ecris ton message...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _sendMessage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum ChatAuthor { user, bot }

class _ChatMessage {
  final ChatAuthor author;
  final String text;

  const _ChatMessage({required this.author, required this.text});
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text(
              'IA en train de repondre...',
              style: TextStyle(fontSize: 12, color: Color(0xFF1A1A2E)),
            ),
          ],
        ),
      ),
    );
  }
}

class _GestureVideoAvatar extends StatefulWidget {
  const _GestureVideoAvatar({
    required this.gestureName,
    required this.color,
  });

  final String gestureName;
  final Color color;

  @override
  State<_GestureVideoAvatar> createState() => _GestureVideoAvatarState();
}

class _GestureVideoAvatarState extends State<_GestureVideoAvatar> {
  VideoPlayerController? _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBestVideo();
  }

  @override
  void didUpdateWidget(covariant _GestureVideoAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gestureName != widget.gestureName) {
      _loadBestVideo();
    }
  }

  List<String> _candidateAssets(String gestureName) {
    final key = _normalize(gestureName);
    final noAccent = _stripAccents(key).replaceAll(' ', '_').replaceAll('-', '_');
    return [
      'assets/videos/gestures/$noAccent.mp4',
      'assets/videos/$noAccent.mp4',
      'assets/videos/$noAccent.mp4.mp4',
    ];
  }

  String _normalize(String text) => text.trim().toLowerCase();

  String _stripAccents(String text) {
    return text
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('à', 'a')
        .replaceAll('ù', 'u')
        .replaceAll('ô', 'o')
        .replaceAll('ï', 'i')
        .replaceAll('ç', 'c');
  }

  Future<void> _loadBestVideo() async {
    setState(() {
      _isLoading = true;
    });
    await _controller?.dispose();
    _controller = null;

    for (final asset in _candidateAssets(widget.gestureName)) {
      try {
        final candidate = VideoPlayerController.asset(asset);
        await candidate.initialize();
        await candidate.setLooping(true);
        await candidate.setVolume(0);
        await candidate.play();
        if (!mounted) {
          await candidate.dispose();
          return;
        }
        setState(() {
          _controller = candidate;
          _isLoading = false;
        });
        return;
      } catch (_) {
        // Try next candidate path.
      }
    }

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        width: 66,
        height: 66,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          ),
        ),
      );
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return GestureIllustration(
        gestureName: widget.gestureName,
        color: widget.color,
        size: 66,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 66,
        height: 66,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _controller!.value.size.width,
            height: _controller!.value.size.height,
            child: VideoPlayer(_controller!),
          ),
        ),
      ),
    );
  }
}

