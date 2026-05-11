/// Implémentation web / sans `dart:io` : pas de canal volume matériel.
class AndroidVolumeHub {
  AndroidVolumeHub._();

  static Future<bool> Function()? onVolumeUpPriority;
  static Future<void> Function()? onVolumeUpHelpTab;

  static void ensureInitialized() {}
}
