import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/volume/android_volume_hub.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AndroidVolumeHub.ensureInitialized();
  runApp(
    const ProviderScope(
      child: Ma3akApp(),
    ),
  );
}
