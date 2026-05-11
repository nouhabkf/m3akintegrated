import 'package:shared_preferences/shared_preferences.dart';

/// Raccourci quand on appuie sur « créer un post » (communauté ou ouverture auto du formulaire).
enum PostCreationShortcut {
  /// Écran de création habituel (tactile / clavier / vocal puis validation).
  form,

  /// Caméra + ML Kit : tête & yeux (handicap moteur lourd).
  headGesture,

  /// Menu codé par vibrations (ex. sourd-aveugle).
  vibration,

  /// Dictée vocale + vibrations + validation au dos.
  voiceVibration,
}

/// Préférences locales pour l’accès aux posts sans toucher l’écran du formulaire.
class AccessibilityPostPrefs {
  AccessibilityPostPrefs._();

  static const _keyShortcut = 'post_creation_shortcut_v1';
  static const _keyLegacyHead = 'open_head_gesture_first_for_posts';
  /// Lecture vocale automatique à l’ouverture du détail post (valeur utilisateur ou défaut profil).
  static const _keyPostDetailAutoRead = 'post_detail_auto_read_enabled_v1';
  /// Débit TTS sur l’écran détail : 0 lent, 1 normal, 2 rapide.
  static const _keyPostDetailTtsRate = 'post_detail_tts_rate_index_v1';
  /// Interface simplifiée (texte plus grand, moins de détails).
  static const _keyPostDetailSimplifiedUi = 'post_detail_simplified_ui_v1';

  static PostCreationShortcut _parseShortcut(String? raw) {
    if (raw == null || raw.isEmpty) return PostCreationShortcut.form;
    for (final e in PostCreationShortcut.values) {
      if (e.name == raw) return e;
    }
    return PostCreationShortcut.form;
  }

  /// Raccourci pour le bouton + et l’ouverture auto du formulaire (hors web).
  static Future<PostCreationShortcut> getPostCreationShortcut() async {
    final p = await SharedPreferences.getInstance();
    final stored = p.getString(_keyShortcut);
    if (stored != null) {
      return _parseShortcut(stored);
    }
    if (p.getBool(_keyLegacyHead) == true) {
      await p.setString(_keyShortcut, PostCreationShortcut.headGesture.name);
      return PostCreationShortcut.headGesture;
    }
    return PostCreationShortcut.form;
  }

  static Future<void> setPostCreationShortcut(PostCreationShortcut value) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyShortcut, value.name);
    await p.setBool(
      _keyLegacyHead,
      value == PostCreationShortcut.headGesture,
    );
  }

  /// Préférence explicite uniquement (`null` si jamais modifiée dans les réglages).
  static Future<bool?> getPostDetailAutoReadExplicit() async {
    final p = await SharedPreferences.getInstance();
    if (!p.containsKey(_keyPostDetailAutoRead)) return null;
    return p.getBool(_keyPostDetailAutoRead);
  }

  /// Effet combiné : choix utilisateur sinon [visualProfileDefault] (ex. handicap visuel).
  static Future<bool> effectivePostDetailAutoRead({
    required bool visualProfileDefault,
  }) async {
    final explicit = await getPostDetailAutoReadExplicit();
    return explicit ?? visualProfileDefault;
  }

  static Future<void> setPostDetailAutoReadEnabled(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_keyPostDetailAutoRead, value);
  }

  /// 0 = lent, 1 = normal, 2 = rapide.
  static Future<int> postDetailTtsRateIndex() async {
    final p = await SharedPreferences.getInstance();
    return (p.getInt(_keyPostDetailTtsRate) ?? 1).clamp(0, 2);
  }

  static Future<void> setPostDetailTtsRateIndex(int index) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_keyPostDetailTtsRate, index.clamp(0, 2));
  }

  static double speechRateForTtsIndex(int index) {
    switch (index.clamp(0, 2)) {
      case 0:
        return 0.36;
      case 2:
        return 0.58;
      default:
        return 0.45;
    }
  }

  static Future<bool> postDetailSimplifiedUi() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_keyPostDetailSimplifiedUi) ?? false;
  }

  static Future<void> setPostDetailSimplifiedUi(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_keyPostDetailSimplifiedUi, value);
  }

}
