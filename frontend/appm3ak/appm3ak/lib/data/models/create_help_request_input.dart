import 'package:equatable/equatable.dart';

/// Paramètres pour `POST /community/help-requests` (champs optionnels alignés sur le backend).
class CreateHelpRequestInput extends Equatable {
  const CreateHelpRequestInput({
    this.description,
    required this.latitude,
    required this.longitude,
    this.helpType,
    this.inputMode,
    this.requesterProfile,
    this.needsAudioGuidance,
    this.needsVisualSupport,
    this.needsPhysicalAssistance,
    this.needsSimpleLanguage,
    this.isForAnotherPerson,
    this.presetMessageKey,
  });

  /// Texte libre ; peut être vide si le serveur génère via [helpType] / [presetMessageKey].
  final String? description;
  final double latitude;
  final double longitude;

  /// Valeurs API : mobility | orientation | communication | medical | escort | unsafe_access | other
  final String? helpType;

  /// text | voice | tap | haptic | volume_shortcut | caregiver
  final String? inputMode;

  /// visual | motor | hearing | cognitive | caregiver | unknown
  final String? requesterProfile;

  final bool? needsAudioGuidance;
  final bool? needsVisualSupport;
  final bool? needsPhysicalAssistance;
  final bool? needsSimpleLanguage;
  final bool? isForAnotherPerson;

  /// blocked | lost | cannot_reach | medical_urgent | escort
  final String? presetMessageKey;

  factory CreateHelpRequestInput.legacy({
    required String description,
    required double latitude,
    required double longitude,
  }) =>
      CreateHelpRequestInput(
        description: description,
        latitude: latitude,
        longitude: longitude,
      );

  @override
  List<Object?> get props => [
        description,
        latitude,
        longitude,
        helpType,
        inputMode,
        requesterProfile,
        needsAudioGuidance,
        needsVisualSupport,
        needsPhysicalAssistance,
        needsSimpleLanguage,
        isForAnotherPerson,
        presetMessageKey,
      ];
}
