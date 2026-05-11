import 'package:flutter/foundation.dart';

import '../../../core/l10n/app_strings.dart';

/// Préréglages rapides pour une demande d’aide (alignés backend + message builder).
///
/// Chaque valeur correspond à une puce ; [HelpRequestQuickPresetMapping.forPreset]
/// fournit `helpType`, `presetMessageKey`, `requesterProfile` et des drapeaux
/// d’accessibilité par défaut cohérents avec le cas d’usage.
enum HelpRequestQuickPreset {
  /// Je suis bloqué
  blocked,

  /// Je suis perdu
  lost,

  /// Je ne trouve pas l’entrée
  cannotFindEntrance,

  /// J’ai besoin d’aide pour me déplacer
  mobilityHelp,

  /// J’ai besoin d’aide pour m’orienter
  orientationHelp,

  /// J’ai besoin d’aide pour communiquer
  communicationHelp,

  /// Je demande de l’aide pour une autre personne
  forAnotherPerson,

  /// Situation dangereuse
  danger,
}

/// Cartographie locale → champs API (`CreateHelpRequestInput`).
@immutable
class HelpRequestQuickPresetMapping {
  const HelpRequestQuickPresetMapping({
    required this.helpType,
    this.presetMessageKey,
    this.requesterProfile,
    this.needsAudioGuidance = false,
    this.needsVisualSupport = false,
    this.needsPhysicalAssistance = false,
    this.needsSimpleLanguage = false,
    this.isForAnotherPerson = false,
    this.forceCaregiverInputMode = false,
  });

  /// `mobility` | `orientation` | `communication` | `medical` | `escort` | `unsafe_access` | `other`
  final String helpType;

  /// `blocked` | `lost` | `cannot_reach` | `medical_urgent` | `escort` — voir backend `HELP_REQUEST_PRESET_MESSAGES_FR`
  final String? presetMessageKey;

  /// `visual` | `motor` | `hearing` | `cognitive` | `caregiver` | `unknown`
  final String? requesterProfile;

  final bool needsAudioGuidance;
  final bool needsVisualSupport;
  final bool needsPhysicalAssistance;
  final bool needsSimpleLanguage;
  final bool isForAnotherPerson;

  /// Passe l’UI en mode accompagnant (aligné `inputMode: caregiver`).
  final bool forceCaregiverInputMode;

  static HelpRequestQuickPresetMapping forPreset(HelpRequestQuickPreset p) {
    switch (p) {
      case HelpRequestQuickPreset.blocked:
        return const HelpRequestQuickPresetMapping(
          helpType: 'unsafe_access',
          presetMessageKey: 'blocked',
          requesterProfile: 'motor',
          needsPhysicalAssistance: true,
        );
      case HelpRequestQuickPreset.lost:
        return const HelpRequestQuickPresetMapping(
          helpType: 'orientation',
          presetMessageKey: 'lost',
          requesterProfile: 'visual',
          needsAudioGuidance: true,
        );
      case HelpRequestQuickPreset.cannotFindEntrance:
        return const HelpRequestQuickPresetMapping(
          helpType: 'orientation',
          presetMessageKey: 'cannot_reach',
          requesterProfile: 'visual',
          needsVisualSupport: true,
          needsAudioGuidance: true,
        );
      case HelpRequestQuickPreset.mobilityHelp:
        return const HelpRequestQuickPresetMapping(
          helpType: 'mobility',
          presetMessageKey: 'escort',
          requesterProfile: 'motor',
          needsPhysicalAssistance: true,
        );
      case HelpRequestQuickPreset.orientationHelp:
        return const HelpRequestQuickPresetMapping(
          helpType: 'orientation',
          presetMessageKey: 'lost',
          requesterProfile: 'visual',
          needsAudioGuidance: true,
          needsVisualSupport: true,
        );
      case HelpRequestQuickPreset.communicationHelp:
        return const HelpRequestQuickPresetMapping(
          helpType: 'communication',
          requesterProfile: 'hearing',
          needsSimpleLanguage: true,
        );
      case HelpRequestQuickPreset.forAnotherPerson:
        return const HelpRequestQuickPresetMapping(
          helpType: 'other',
          requesterProfile: 'caregiver',
          isForAnotherPerson: true,
          forceCaregiverInputMode: true,
        );
      case HelpRequestQuickPreset.danger:
        return const HelpRequestQuickPresetMapping(
          helpType: 'medical',
          presetMessageKey: 'medical_urgent',
        );
    }
  }
}

extension HelpRequestQuickPresetL10n on HelpRequestQuickPreset {
  String label(AppStrings s) {
    switch (this) {
      case HelpRequestQuickPreset.blocked:
        return s.helpCreateQuickBlocked;
      case HelpRequestQuickPreset.lost:
        return s.helpCreateQuickLost;
      case HelpRequestQuickPreset.cannotFindEntrance:
        return s.helpCreateQuickCannotFindEntrance;
      case HelpRequestQuickPreset.mobilityHelp:
        return s.helpCreateQuickMobilityHelp;
      case HelpRequestQuickPreset.orientationHelp:
        return s.helpCreateQuickOrientationHelp;
      case HelpRequestQuickPreset.communicationHelp:
        return s.helpCreateQuickCommunicationHelp;
      case HelpRequestQuickPreset.forAnotherPerson:
        return s.helpCreateQuickForAnotherPerson;
      case HelpRequestQuickPreset.danger:
        return s.helpCreateQuickDanger;
    }
  }

  /// Phrase affichée dans l’aperçu (cohérente avec le générateur côté serveur).
  String previewSentence(AppStrings s) {
    switch (this) {
      case HelpRequestQuickPreset.blocked:
        return s.helpCreateQuickPreviewBlocked;
      case HelpRequestQuickPreset.lost:
        return s.helpCreateQuickPreviewLost;
      case HelpRequestQuickPreset.cannotFindEntrance:
        return s.helpCreateQuickPreviewCannotFindEntrance;
      case HelpRequestQuickPreset.mobilityHelp:
        return s.helpCreateQuickPreviewMobilityHelp;
      case HelpRequestQuickPreset.orientationHelp:
        return s.helpCreateQuickPreviewOrientationHelp;
      case HelpRequestQuickPreset.communicationHelp:
        return s.helpCreateQuickPreviewCommunicationHelp;
      case HelpRequestQuickPreset.forAnotherPerson:
        return s.helpCreateQuickPreviewForAnotherPerson;
      case HelpRequestQuickPreset.danger:
        return s.helpCreateQuickPreviewDanger;
    }
  }
}
