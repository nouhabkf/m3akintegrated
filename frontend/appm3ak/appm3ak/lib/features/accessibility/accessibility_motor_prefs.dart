import 'package:shared_preferences/shared_preferences.dart';

/// Préférences d'assistance motrice (MVP) pour limiter les faux clics.
class AccessibilityMotorPrefs {
  AccessibilityMotorPrefs._();

  static const _keyMagneticEnabled = 'a11y_motor_magnetic_enabled_v1';
  static const _keyMagneticPadding = 'a11y_motor_magnetic_padding_v1';
  static const _keyDwellEnabled = 'a11y_motor_dwell_enabled_v1';
  static const _keyDwellMs = 'a11y_motor_dwell_ms_v1';
  static const _keyLargeButtons = 'a11y_motor_large_buttons_v1';

  static const bool defaultMagneticEnabled = true;
  static const double defaultMagneticPadding = 10;
  static const bool defaultDwellEnabled = false;
  static const int defaultDwellMs = 900;
  static const bool defaultLargeButtons = true;

  static Future<bool> magneticEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_keyMagneticEnabled) ?? defaultMagneticEnabled;
  }

  static Future<double> magneticPadding() async {
    final p = await SharedPreferences.getInstance();
    return p.getDouble(_keyMagneticPadding) ?? defaultMagneticPadding;
  }

  static Future<bool> dwellEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_keyDwellEnabled) ?? defaultDwellEnabled;
  }

  static Future<int> dwellMs() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_keyDwellMs) ?? defaultDwellMs;
  }

  static Future<bool> largeButtons() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_keyLargeButtons) ?? defaultLargeButtons;
  }
}
