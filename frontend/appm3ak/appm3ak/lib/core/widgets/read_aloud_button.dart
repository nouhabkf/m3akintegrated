import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Bouton lecture vocale simple pour non-voyants.
class ReadAloudButton extends StatefulWidget {
  const ReadAloudButton({
    super.key,
    required this.textBuilder,
    required this.readLabel,
    required this.stopLabel,
  });

  final FutureOr<String> Function() textBuilder;
  final String readLabel;
  final String stopLabel;

  @override
  State<ReadAloudButton> createState() => _ReadAloudButtonState();
}

class _ReadAloudButtonState extends State<ReadAloudButton> {
  final FlutterTts _tts = FlutterTts();
  bool _speaking = false;

  @override
  void initState() {
    super.initState();
    _configure();
  }

  Future<void> _configure() async {
    try {
      await _tts.setLanguage('fr-FR');
      await _tts.setSpeechRate(0.47);
      await _tts.awaitSpeakCompletion(true);
      _tts.setCompletionHandler(() {
        if (mounted) setState(() => _speaking = false);
      });
      _tts.setCancelHandler(() {
        if (mounted) setState(() => _speaking = false);
      });
      _tts.setErrorHandler((_) {
        if (mounted) setState(() => _speaking = false);
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    unawaited(_tts.stop());
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_speaking) {
      await _tts.stop();
      if (mounted) setState(() => _speaking = false);
      return;
    }
    final text = await widget.textBuilder();
    if (text.trim().isEmpty) return;
    if (mounted) setState(() => _speaking = true);
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {
      if (mounted) setState(() => _speaking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: _speaking ? widget.stopLabel : widget.readLabel,
      onPressed: _toggle,
      icon: Icon(_speaking ? Icons.stop_circle_outlined : Icons.volume_up_outlined),
    );
  }
}
