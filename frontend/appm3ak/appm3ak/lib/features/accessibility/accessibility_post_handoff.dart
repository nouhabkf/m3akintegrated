import 'package:image_picker/image_picker.dart';

import '../../data/models/post_model.dart';

/// Passé en `extra` vers `/create-post` après un flux accessibilité (tête / vibrations).
class AccessibilityPostHandoff {
  const AccessibilityPostHandoff({
    required this.content,
    this.images = const [],
    this.suggestedPostType,
    this.autoPublish = false,
    this.latitude,
    this.longitude,
    this.locationSharingMode,
  });

  final String content;
  final List<XFile> images;
  final PostType? suggestedPostType;

  /// Si vrai, [CreatePostScreen] envoie le post sans toucher au bouton Publier
  /// (indispensable pour handicap moteur lourd).
  final bool autoPublish;

  /// Localisation optionnelle récupérée dans un flux accessibilité (tête/yeux).
  final double? latitude;
  final double? longitude;

  /// `precise` ou `approximate` quand une position est jointe.
  final String? locationSharingMode;
}
