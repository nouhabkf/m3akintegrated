import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

/// Android : [MethodChannel] volume+ (vibrations / demandes d'aide).
class AndroidVolumeHub {
  AndroidVolumeHub._();

  static const MethodChannel _channel =
      MethodChannel('com.appm3ak.appm3ak/volume');

  static bool _initialized = false;

  static Future<bool> Function()? onVolumeUpPriority;
  static Future<void> Function()? onVolumeUpHelpTab;

  static Future<void> _dispatch(MethodCall call) async {
    if (call.method != 'volumeUp') return;
    final priority = onVolumeUpPriority;
    if (priority != null) {
      try {
        final consumed = await priority();
        if (consumed) return;
      } catch (_) {}
    }
    final help = onVolumeUpHelpTab;
    if (help != null) {
      try {
        await help();
      } catch (_) {}
    }
  }

  static void ensureInitialized() {
    if (kIsWeb) return;
    if (_initialized || !Platform.isAndroid) return;
    _initialized = true;
    _channel.setMethodCallHandler(_dispatch);
  }
}
