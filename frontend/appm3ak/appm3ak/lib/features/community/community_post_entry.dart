import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../accessibility/accessibility_post_handoff.dart';
import '../accessibility/accessibility_post_prefs.dart';

/// Point d’entrée unique pour « créer un post » depuis la communauté (raccourci Profil).
class CommunityPostEntry {
  CommunityPostEntry._();

  /// Ouvre le flux adapté (tête & yeux, vibrations ou formulaire).
  /// Si l’utilisateur ferme le flux sans valider, on ouvre quand même le formulaire.
  static Future<void> open(BuildContext context) async {
    if (kIsWeb) {
      if (context.mounted) await context.push('/create-post');
      return;
    }
    final shortcut = await AccessibilityPostPrefs.getPostCreationShortcut();
    if (!context.mounted) return;

    if (shortcut == PostCreationShortcut.headGesture) {
      final handoff =
          await context.push<AccessibilityPostHandoff?>('/create-post-head-gesture');
      if (!context.mounted) return;
      if (handoff != null) {
        await context.push('/create-post', extra: handoff);
      } else {
        await context.push('/create-post');
      }
      return;
    }
    if (shortcut == PostCreationShortcut.vibration) {
      await context.push<void>('/create-post-vibration');
      return;
    }
    if (shortcut == PostCreationShortcut.voiceVibration) {
      final handoff = await context
          .push<AccessibilityPostHandoff?>('/create-post-voice-vibration');
      if (!context.mounted) return;
      if (handoff != null) {
        await context.push('/create-post', extra: handoff);
      } else {
        await context.push('/create-post');
      }
      return;
    }
    await context.push('/create-post');
  }
}
