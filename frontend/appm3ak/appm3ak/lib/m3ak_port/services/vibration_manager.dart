import 'package:vibration/vibration.dart';

class VibrationManager {
  static const int _dotDuration = 100;
  static const int _gapDuration = 50;
  static const int _letterGap = 200;

  Future<bool> _hasVibrator() async {
    return Vibration.hasVibrator();
  }

  Future<void> vibrateBraillePoint(int pointNum) async {
    if (!await _hasVibrator()) return;

    if (pointNum >= 1 && pointNum <= 6) {
      await Vibration.vibrate(duration: _dotDuration);
    }
  }

  Future<void> vibrateBrailleCharacter(String brailleChar) async {
    if (!await _hasVibrator()) return;

    final pattern = _getBrailleVibrationPattern(brailleChar);
    if (pattern.isNotEmpty) {
      await Vibration.vibrate(pattern: pattern);
    }
  }

  Future<void> vibrateBrailleWord(String brailleText) async {
    for (int i = 0; i < brailleText.length; i++) {
      await vibrateBrailleCharacter(brailleText[i]);
      if (i < brailleText.length - 1 && brailleText[i] != ' ') {
        await Future.delayed(Duration(milliseconds: _letterGap));
      }
    }
  }

  Future<void> vibrateSuccess() async {
    if (!await _hasVibrator()) return;
    await Vibration.vibrate(pattern: [0, 100, 50, 100, 50, 200]);
  }

  Future<void> vibrateError() async {
    if (!await _hasVibrator()) return;
    await Vibration.vibrate(pattern: [0, 200, 100, 200]);
  }

  Future<void> cancel() async {
    await Vibration.cancel();
  }

  List<int> _getBrailleVibrationPattern(String brailleChar) {
    return [0, _dotDuration, _gapDuration, _dotDuration];
  }
}