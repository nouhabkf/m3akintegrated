import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';

/// Paramètres pour `POST /community/posts` (multipart). Champs inclusifs optionnels.
class CreatePostInput extends Equatable {
  const CreatePostInput({
    required this.contenu,
    required this.type,
    this.images,
    this.latitude,
    this.longitude,
    this.dangerLevel,
    this.postNature,
    this.targetAudience,
    this.inputMode,
    this.isForAnotherPerson,
    this.needsAudioGuidance,
    this.needsVisualSupport,
    this.needsPhysicalAssistance,
    this.needsSimpleLanguage,
    this.locationSharingMode,
  });

  final String contenu;

  /// Valeur API existante (`PostType.toApiString()`).
  final String type;

  final List<XFile>? images;

  final double? latitude;
  final double? longitude;
  final String? dangerLevel;

  final String? postNature;
  final String? targetAudience;
  final String? inputMode;
  final bool? isForAnotherPerson;
  final bool? needsAudioGuidance;
  final bool? needsVisualSupport;
  final bool? needsPhysicalAssistance;
  final bool? needsSimpleLanguage;
  final String? locationSharingMode;

  /// Rétrocompat : uniquement `contenu` + `type` (+ médias / géoloc hérités).
  factory CreatePostInput.legacy({
    required String contenu,
    required String type,
    List<XFile>? images,
    double? latitude,
    double? longitude,
    String? dangerLevel,
  }) =>
      CreatePostInput(
        contenu: contenu,
        type: type,
        images: images,
        latitude: latitude,
        longitude: longitude,
        dangerLevel: dangerLevel,
      );

  @override
  List<Object?> get props => [
        contenu,
        type,
        latitude,
        longitude,
        dangerLevel,
        postNature,
        targetAudience,
        inputMode,
        isForAnotherPerson,
        needsAudioGuidance,
        needsVisualSupport,
        needsPhysicalAssistance,
        needsSimpleLanguage,
        locationSharingMode,
      ];
}
