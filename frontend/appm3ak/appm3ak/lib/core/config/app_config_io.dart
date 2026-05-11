import 'dart:io';

/// Sur Android, localhost du PC = 10.0.2.2 pour l'émulateur.
String getDefaultApiBaseUrl() {
  // IMPORTANT:
  // - 10.0.2.2 marche uniquement sur l’ÉMULATEUR Android.
  // - Sur un téléphone physique, il faut utiliser l’IP du PC (même Wi‑Fi),
  //   via `--dart-define=API_BASE_URL=http://<IP_PC>:3000`.
  if (Platform.isAndroid) return 'http://10.0.2.2:3000';
  return 'http://localhost:3000';
}
