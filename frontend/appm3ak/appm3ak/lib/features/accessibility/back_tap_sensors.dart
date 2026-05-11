import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../core/volume/android_volume_hub.dart';

/// Détection « choc au dos du téléphone » sur [UserAccelerometerEvent].
/// Utilise à la fois la norme et le pic sur un axe (souvent Z ou X selon la prise).
bool userAccelerationLooksLikeBackTap(UserAccelerometerEvent e) {
  final mag = math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
  final peak = math.max(e.x.abs(), math.max(e.y.abs(), e.z.abs()));
  return mag >= _minVectorMag || peak >= _minSingleAxisPeak;
}

/// Variation d’accéléromètre brut entre deux échantillons (m/s²) — utile quand
/// [userAccelerometerEventStream] reste plat sur certains appareils.
bool rawAccelDeltaLooksLikeTap(double dx, double dy, double dz) {
  return math.sqrt(dx * dx + dy * dy + dz * dz) >= _minRawDeltaMag;
}

/// Pic angulaire court (rad/s) souvent présent lors d’un tap sur la coque.
bool gyroLooksLikeTap(GyroscopeEvent e) {
  final g = math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
  return g >= _minGyroMag;
}

/// Seuils bas : beaucoup d’OEM renvoient des pics faibles ; le bouton écran reste le secours fiable.
const double _minVectorMag = 3.8;
const double _minSingleAxisPeak = 5.0;
const double _minRawDeltaMag = 2.6;
const double _minGyroMag = 1.6;

/// Attendre que les vibrations du moteur retombent avant d’écouter le tapotement.
const Duration kBackTapSettleAfterVibration = Duration(milliseconds: 500);

/// Entre deux prises en compte (évite double déclenchement).
const Duration kBackTapDebounce = Duration(milliseconds: 300);

/// Écoute user accel + accel brut (delta) + gyro, échantillonnage le plus rapide possible.
Future<bool> waitForBackTap({
  required Duration window,
  required bool Function() isListening,
}) async {
  await Future<void>.delayed(kBackTapSettleAfterVibration);
  if (!isListening()) return false;

  final completer = Completer<bool>();
  var lastHit = DateTime.fromMillisecondsSinceEpoch(0);

  void hit() {
    if (!isListening()) return;
    final now = DateTime.now();
    if (now.difference(lastHit) < kBackTapDebounce) return;
    lastHit = now;
    if (!completer.isCompleted) {
      HapticFeedback.heavyImpact();
      completer.complete(true);
    }
  }

  double? px;
  double? py;
  double? pz;

  final subs = <StreamSubscription<dynamic>>[
    userAccelerometerEventStream(
      samplingPeriod: SensorInterval.fastestInterval,
    ).listen(
      (UserAccelerometerEvent e) {
        if (!isListening()) return;
        if (userAccelerationLooksLikeBackTap(e)) hit();
      },
      onError: (_) {},
    ),
    accelerometerEventStream(
      samplingPeriod: SensorInterval.fastestInterval,
    ).listen(
      (AccelerometerEvent e) {
        if (!isListening()) return;
        if (px != null) {
          if (rawAccelDeltaLooksLikeTap(e.x - px!, e.y - py!, e.z - pz!)) {
            hit();
          }
        }
        px = e.x;
        py = e.y;
        pz = e.z;
      },
      onError: (_) {},
    ),
    gyroscopeEventStream(
      samplingPeriod: SensorInterval.fastestInterval,
    ).listen(
      (GyroscopeEvent e) {
        if (!isListening()) return;
        if (gyroLooksLikeTap(e)) hit();
      },
      onError: (_) {},
    ),
  ];

  try {
    return await completer.future.timeout(window, onTimeout: () => false);
  } finally {
    for (final s in subs) {
      await s.cancel();
    }
  }
}

/// Confirmer par **volume+** (Android, prioritaire) ou **tap dos** (capteurs).
Future<bool> waitForVolumeOrBackTap({
  required Duration window,
  required bool Function() isListening,
}) async {
  await Future<void>.delayed(kBackTapSettleAfterVibration);
  if (!isListening()) return false;

  final completer = Completer<bool>();
  var lastHit = DateTime.fromMillisecondsSinceEpoch(0);

  void hit() {
    if (!isListening()) return;
    final now = DateTime.now();
    if (now.difference(lastHit) < kBackTapDebounce) return;
    lastHit = now;
    if (!completer.isCompleted) {
      HapticFeedback.heavyImpact();
      completer.complete(true);
    }
  }

  Future<bool> volumePriority() async {
    if (!isListening()) return false;
    hit();
    return true;
  }

  AndroidVolumeHub.ensureInitialized();
  final previous = AndroidVolumeHub.onVolumeUpPriority;
  AndroidVolumeHub.onVolumeUpPriority = volumePriority;

  double? px;
  double? py;
  double? pz;

  final subs = <StreamSubscription<dynamic>>[
    userAccelerometerEventStream(
      samplingPeriod: SensorInterval.fastestInterval,
    ).listen(
      (UserAccelerometerEvent e) {
        if (!isListening()) return;
        if (userAccelerationLooksLikeBackTap(e)) hit();
      },
      onError: (_) {},
    ),
    accelerometerEventStream(
      samplingPeriod: SensorInterval.fastestInterval,
    ).listen(
      (AccelerometerEvent e) {
        if (!isListening()) return;
        if (px != null) {
          if (rawAccelDeltaLooksLikeTap(e.x - px!, e.y - py!, e.z - pz!)) {
            hit();
          }
        }
        px = e.x;
        py = e.y;
        pz = e.z;
      },
      onError: (_) {},
    ),
    gyroscopeEventStream(
      samplingPeriod: SensorInterval.fastestInterval,
    ).listen(
      (GyroscopeEvent e) {
        if (!isListening()) return;
        if (gyroLooksLikeTap(e)) hit();
      },
      onError: (_) {},
    ),
  ];

  try {
    return await completer.future.timeout(window, onTimeout: () => false);
  } finally {
    AndroidVolumeHub.onVolumeUpPriority = previous;
    for (final s in subs) {
      await s.cancel();
    }
  }
}
