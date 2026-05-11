import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../core/l10n/app_strings.dart';
import '../../../data/models/user_model.dart';
import '../../../providers/health_providers.dart';
import '../services/health_ai_service.dart';
import '../services/health_voice_lang.dart';
import '../services/health_voice_service.dart';

class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.isUser});

  final String text;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = isUser
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;
    final fg = isUser
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurfaceVariant;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.86,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isUser ? 16 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 16),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: SelectableText(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: fg,
                height: 1.35,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Chatbot santé avec réponses contextuelles et lecture vocale FR/EN.
class HealthAiChatScreen extends ConsumerStatefulWidget {
  const HealthAiChatScreen({
    super.key,
    required this.strings,
    this.initialUserMessage,
    this.userProfile,
  });

  final AppStrings strings;
  final String? initialUserMessage;
  final UserModel? userProfile;

  @override
  ConsumerState<HealthAiChatScreen> createState() => _HealthAiChatScreenState();
}

class _HealthAiChatScreenState extends ConsumerState<HealthAiChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final _voice = HealthVoiceService();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final _ai = const HealthAiService();

  final List<({bool user, String text})> _messages = [];
  late HealthVoiceLang _voiceLang;
  bool _autoSpeak = true;
  bool _listening = false;
  bool _speechReady = false;
  static const _disclaimerBannerFr = HealthAiService.disclaimerFr;
  static const _disclaimerBannerEn = HealthAiService.disclaimerEn;

  @override
  void initState() {
    super.initState();
    final u = widget.userProfile;
    final lang = u?.langue.toLowerCase() ?? '';
    _voiceLang =
        lang == 'en' ? HealthVoiceLang.en : HealthVoiceLang.fr;
    _bootstrapSpeech();
    final seed = widget.initialUserMessage;
    if (seed != null && seed.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _send(seed));
    }
  }

  Future<void> _bootstrapSpeech() async {
    try {
      _speechReady = await _speech.initialize(
        onStatus: (s) {
          if (s == 'done' || s == 'notListening') {
            if (mounted) setState(() => _listening = false);
          }
        },
        onError: (_) {
          if (mounted) setState(() => _listening = false);
        },
      );
    } catch (_) {
      _speechReady = false;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    _speech.stop();
    _voice.stop();
    super.dispose();
  }

  HealthUserContext _profileContext() {
    final u = widget.userProfile;
    final health = ref.read(healthDashboardProvider);
    return HealthUserContext(
      typeHandicap: u?.typeHandicap,
      besoinSpecifique: u?.besoinSpecifique,
      hasRecentGlucoseLog: health.latestGlucose != null,
      fastingForAnalysis: health.fastingForAnalysis,
    );
  }

  Future<void> _send([String? raw]) async {
    final s = widget.strings;
    final text = (raw ?? _controller.text).trim();
    if (text.isEmpty) return;
    _controller.clear();
    setState(() {
      _messages.add((user: true, text: text));
    });
    _scrollBottom();

    final reply = _ai.chatReply(
      text,
      voiceLang: _voiceLang,
      profile: _profileContext(),
    );
    final out = _voiceLang == HealthVoiceLang.fr ? reply.fr : reply.en;

    setState(() {
      _messages.add((user: false, text: out));
    });
    _scrollBottom();

    if (_autoSpeak) {
      final ok = await _voice.speak(out, _voiceLang);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.healthVoiceUnavailable)),
        );
      }
    }
  }

  void _scrollBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _toggleMic() async {
    if (!_speechReady) {
      await _bootstrapSpeech();
      if (!_speechReady && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.strings.locale == 'ar'
                  ? 'الميكروفون غير متاح'
                  : 'Microphone indisponible',
            ),
          ),
        );
      }
      return;
    }
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      return;
    }
    setState(() => _listening = true);
    await _speech.listen(
      localeId: _voiceLang == HealthVoiceLang.fr ? 'fr_FR' : 'en_US',
      listenMode: stt.ListenMode.dictation,
      onResult: (res) {
        if (res.finalResult) {
          setState(() {
            _listening = false;
            _controller.text = res.recognizedWords;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = widget.strings;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.healthChatTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                Text(
                  s.healthVoiceLang,
                  style: theme.textTheme.labelSmall,
                ),
                const SizedBox(width: 4),
                SegmentedButton<HealthVoiceLang>(
                  segments: const [
                    ButtonSegment(
                      value: HealthVoiceLang.fr,
                      label: Text('FR'),
                    ),
                    ButtonSegment(
                      value: HealthVoiceLang.en,
                      label: Text('EN'),
                    ),
                  ],
                  selected: {_voiceLang},
                  onSelectionChanged: (set) {
                    setState(() => _voiceLang = set.first);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Material(
            color: theme.colorScheme.surfaceContainerLow,
            child: SwitchListTile(
              title: Text(s.healthVoiceAuto),
              subtitle: Text(
                _voiceLang == HealthVoiceLang.fr
                    ? 'Réponse lue automatiquement en français'
                    : 'Reply read aloud automatically in English',
              ),
              value: _autoSpeak,
              onChanged: (v) => setState(() => _autoSpeak = v),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      widget.strings.isAr
                          ? 'معلومات عامة فقط — استشر طبيباً.'
                          : (_voiceLang == HealthVoiceLang.fr
                              ? _disclaimerBannerFr
                              : _disclaimerBannerEn),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  );
                }
                final m = _messages[i - 1];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _Bubble(text: m.text, isUser: m.user),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton.filledTonal(
                    onPressed: _toggleMic,
                    icon: Icon(_listening ? Icons.stop : Icons.mic_none),
                    tooltip: _listening ? s.healthMicStop : s.healthMicListen,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: s.healthChatHint,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => _send(),
                    child: Text(s.healthChatSend),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
