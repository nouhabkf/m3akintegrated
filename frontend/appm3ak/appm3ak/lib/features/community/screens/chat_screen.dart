import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../core/location/current_position.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/community_providers.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    required this.userId,
    this.userName,
    super.key,
  });

  final String userId;
  final String? userName;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _ctrl = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final ImagePicker _imagePicker = ImagePicker();
  bool _listening = false;
  int _lastReadCount = 0;
  bool _introRead = false;

  static const Color _kBg = Color(0xFF2E2A3D);
  static const Color _kCard = Color(0xFF3A3550);
  static const LinearGradient _kBubbleGradient = LinearGradient(
    colors: [Color(0xFFFF4D8D), Color(0xFFC95CF4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.awaitSpeakCompletion(true);
    await _tts.setLanguage('fr-FR');
    await _tts.setSpeechRate(0.45);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  Future<void> _toggleDictation() async {
    if (_listening) {
      await _speech.stop();
      if (!mounted) return;
      setState(() => _listening = false);
      return;
    }
    final ok = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() => _listening = false);
        }
      },
      onError: (_) {
        if (mounted) setState(() => _listening = false);
      },
    );
    if (!ok) return;
    setState(() => _listening = true);
    await _speech.listen(
      localeId: 'fr_FR',
      listenMode: stt.ListenMode.dictation,
      onResult: (result) {
        if (!mounted) return;
        setState(() => _ctrl.text = result.recognizedWords);
      },
    );
  }

  Future<void> _sendRawText(String text) async {
    final me = ref.read(authStateProvider).valueOrNull;
    final meId = me?.id ?? 'me';
    if (text.isEmpty) return;
    ref.read(communityMessagesProvider.notifier).sendMessage(
          currentUserId: meId,
          otherUserId: widget.userId,
          text: text,
        );
    _ctrl.clear();

    // Réponse mock pour MVP démo.
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 700), () {
        if (!mounted) return;
        ref.read(communityMessagesProvider.notifier).receiveMockMessage(
              currentUserId: meId,
              otherUserId: widget.userId,
              text: 'Merci pour votre message.',
            );
      }),
    );
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    await _sendRawText(text);
    _ctrl.clear();
  }

  Future<void> _sendPhoto() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
      );
      if (picked == null) return;
      final path = picked.path.trim();
      if (path.isEmpty) return;
      await _sendRawText('image:$path');
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Photo envoyée.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Envoi photo impossible.')),
      );
    }
  }

  Future<void> _sendLocation() async {
    try {
      final pos = await getCurrentPositionOrNull();
      if (pos == null) {
        if (!mounted) return;
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(content: Text('Localisation indisponible ou permission refusée.')),
        );
        return;
      }
      final text = 'position:${pos.latitude.toStringAsFixed(5)},${pos.longitude.toStringAsFixed(5)}';
      await _sendRawText(text);
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Position envoyée.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Envoi localisation impossible.')),
      );
    }
  }

  Future<void> _readIncoming(List<CommunityChatMessage> items, String meId) async {
    if (items.length <= _lastReadCount) return;
    final newItems = items.skip(_lastReadCount);
    _lastReadCount = items.length;
    for (final m in newItems) {
      if (m.senderId == meId) continue;
      await _tts.stop();
      await _tts.speak('Nouveau message: ${m.text}');
    }
  }

  Future<void> _readConversationSummary(
    List<CommunityChatMessage> messages,
    String meId,
  ) async {
    final otherName = widget.userName?.trim().isNotEmpty == true
        ? widget.userName!.trim()
        : 'utilisateur';
    await _tts.stop();
    await _tts.speak('Conversation avec $otherName. ${messages.length} messages.');
    for (final m in messages.take(6)) {
      final who = m.senderId == meId ? 'Vous' : otherName;
      await _tts.stop();
      await _tts.speak('$who: ${m.text}');
    }
  }

  void _appendTextToInput(String text) {
    final existing = _ctrl.text.trim();
    setState(() {
      _ctrl.text = existing.isEmpty ? text : '$existing $text';
      _ctrl.selection = TextSelection.fromPosition(
        TextPosition(offset: _ctrl.text.length),
      );
    });
  }

  _ParsedChatContent _parseContent(String rawText) {
    final text = rawText.trim();
    final lower = text.toLowerCase();
    if (lower.startsWith('image:') || lower.startsWith('photo:')) {
      final parts = text.split(':');
      final url = parts.length > 1 ? parts.sublist(1).join(':').trim() : '';
      if (url.isNotEmpty) return _ParsedChatContent.image(url: url);
    }
    if (lower.startsWith('position:') || lower.startsWith('location:')) {
      final content = text.split(':').skip(1).join(':').trim();
      return _ParsedChatContent.location(value: content.isEmpty ? 'Position partagée' : content);
    }
    return _ParsedChatContent.text(value: text);
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(authStateProvider).valueOrNull;
    final meId = me?.id ?? 'me';
    final all = ref.watch(communityMessagesProvider);
    final messages = all.where((m) => m.otherUserId == widget.userId).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _readIncoming(messages, meId);
      if (!_introRead) {
        _introRead = true;
        unawaited(_readConversationSummary(messages, meId));
      }
    });

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            _AccessibleHeader(
              userName: widget.userName,
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final m = messages[index];
                  final mine = m.senderId == meId;
                  final parsed = _parseContent(m.text);
                  return MessageBubble(
                    parsed: parsed,
                    mine: mine,
                    gradient: _kBubbleGradient,
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                child: Column(
                  children: [
                    _HugeButton(
                      label: 'Lire la conversation',
                      icon: Icons.record_voice_over_rounded,
                      onTap: () => unawaited(_readConversationSummary(messages, meId)),
                    ),
                    const SizedBox(height: 12),
                    _HugeButton(
                      label: _listening ? 'Arrêter la dictée' : 'Parler pour répondre',
                      icon: _listening ? Icons.hearing_disabled : Icons.mic_rounded,
                      onTap: () => unawaited(_toggleDictation()),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _HugeButton(
                            label: '📷 Ajouter photo',
                            icon: Icons.add_a_photo_rounded,
                            onTap: () => unawaited(_sendPhoto()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _HugeButton(
                            label: '📍 Envoyer localisation',
                            icon: Icons.location_pin,
                            onTap: () => unawaited(_sendLocation()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ChatInputBar(
                      controller: _ctrl,
                      onSend: _send,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccessibleHeader extends StatelessWidget {
  const _AccessibleHeader({
    required this.userName,
    required this.onBack,
  });

  final String? userName;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final shown = userName?.trim().isNotEmpty == true ? userName!.trim() : 'Utilisateur';
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: _ChatScreenState._kCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _LargeRoundButton(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Discussion',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                  ),
                ),
                Text(
                  shown,
                  style: const TextStyle(
                    color: Color(0xFFDFCFFF),
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: Color(0xFFFF4D8D), size: 26),
          ),
          const SizedBox(width: 8),
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: Color(0xFF00D17B),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _LargeRoundButton extends StatelessWidget {
  const _LargeRoundButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0x22FFFFFF),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    required this.parsed,
    required this.mine,
    required this.gradient,
    super.key,
  });

  final _ParsedChatContent parsed;
  final bool mine;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        constraints: const BoxConstraints(maxWidth: 360),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(28),
            topRight: const Radius.circular(28),
            bottomLeft: Radius.circular(mine ? 28 : 8),
            bottomRight: Radius.circular(mine ? 8 : 28),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x44000000),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: _MessageContent(parsed: parsed),
      ),
    );
  }
}

class _MessageContent extends StatelessWidget {
  const _MessageContent({required this.parsed});
  final _ParsedChatContent parsed;

  @override
  Widget build(BuildContext context) {
    switch (parsed.kind) {
      case _MessageKind.image:
        final value = parsed.value.trim();
        final isRemote = value.startsWith('http://') || value.startsWith('https://');
        final isFileUri = value.startsWith('file://');
        final localPath = isFileUri ? Uri.parse(value).toFilePath() : value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Image envoyée',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: isRemote
                    ? Image.network(
                        value,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Text(
                            'Impossible de charger l image',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      )
                    : Image.file(
                        File(localPath),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Text(
                            'Impossible de charger l image',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ),
              ),
            ),
          ],
        );
      case _MessageKind.location:
        final parts = parsed.value.split(',');
        final lat = parts.isNotEmpty ? parts.first.trim() : '';
        final lng = parts.length > 1 ? parts[1].trim() : '';
        final hasCoords = lat.isNotEmpty && lng.isNotEmpty;
        final mapsUrl = hasCoords
            ? 'https://www.google.com/maps/search/?api=1&query=$lat,$lng'
            : null;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0x33FFFFFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x66FFFFFF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Position envoyée',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                hasCoords ? '$lat, $lng' : parsed.value,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              if (mapsUrl != null) ...[
                const SizedBox(height: 8),
                Text(
                  mapsUrl,
                  style: const TextStyle(
                    color: Color(0xFFE6D9FF),
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ],
          ),
        );
      case _MessageKind.text:
        return Text(
          parsed.value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        );
    }
  }
}

class _HugeButton extends StatelessWidget {
  const _HugeButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _ChatScreenState._kCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x77FFFFFF)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatInputBar extends StatelessWidget {
  const ChatInputBar({
    required this.controller,
    required this.onSend,
    super.key,
  });

  final TextEditingController controller;
  final Future<void> Function() onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: _ChatScreenState._kCard,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
              decoration: const InputDecoration(
                hintText: 'Écrire un message...',
                hintStyle: TextStyle(color: Color(0xFFDEC7FF)),
                border: InputBorder.none,
                isCollapsed: true,
              ),
            ),
          ),
          const SizedBox(width: 12),
          _CircleActionButton(
            icon: Icons.send_rounded,
            semantics: 'Envoyer',
            onTap: () => unawaited(onSend()),
          ),
        ],
      ),
    );
  }
}

enum _MessageKind { text, image, location }

class _ParsedChatContent {
  const _ParsedChatContent._(this.kind, this.value);
  final _MessageKind kind;
  final String value;

  factory _ParsedChatContent.text({required String value}) =>
      _ParsedChatContent._(_MessageKind.text, value);
  factory _ParsedChatContent.image({required String url}) =>
      _ParsedChatContent._(_MessageKind.image, url);
  factory _ParsedChatContent.location({required String value}) =>
      _ParsedChatContent._(_MessageKind.location, value);
}

class _CircleActionButton extends StatelessWidget {
  const _CircleActionButton({
    required this.icon,
    required this.semantics,
    required this.onTap,
  });
  final IconData icon;
  final String semantics;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semantics,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF4D8D), Color(0xFFC95CF4)],
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}

