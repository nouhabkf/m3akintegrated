import 'create_help_request_input.dart';
import 'create_post_input.dart';

class CommunityActionPlanResult {
  const CommunityActionPlanResult({
    required this.action,
    this.postNature,
    this.targetAudience,
    this.postInputMode,
    this.locationSharingMode,
    this.dangerLevel,
    this.legacyType,
    this.generatedContent,
    this.helpType,
    this.requesterProfile,
    this.helpInputMode,
    this.presetMessageKey,
    this.generatedDescription,
    required this.needsAudioGuidance,
    required this.needsVisualSupport,
    required this.needsPhysicalAssistance,
    required this.needsSimpleLanguage,
    required this.isForAnotherPerson,
    this.predictedPriority,
    this.recommendedRoute,
    this.routeReason,
    this.confidence,
    this.routeConfidence,
    this.decisionStrength,
    this.requiresConfirmation,
    this.decisionSummary,
  });

  final String action;

  final String? postNature;
  final String? targetAudience;
  final String? postInputMode;
  final String? locationSharingMode;
  final String? dangerLevel;
  final String? legacyType;
  final String? generatedContent;

  final String? helpType;
  final String? requesterProfile;
  final String? helpInputMode;
  final String? presetMessageKey;
  final String? generatedDescription;

  final bool needsAudioGuidance;
  final bool needsVisualSupport;
  final bool needsPhysicalAssistance;
  final bool needsSimpleLanguage;
  final bool isForAnotherPerson;

  final String? predictedPriority;
  final String? recommendedRoute;
  final String? routeReason;
  final double? confidence;

  /// Heuristic: fit of [recommendedRoute] given modes + wording (not calibrated probability).
  final double? routeConfidence;

  /// How clear the resolved action is (wording + model agreement).
  final double? decisionStrength;

  /// When true, prefer confirming with the user instead of auto-navigation.
  final bool? requiresConfirmation;

  /// Short French explanation for UI (non-clinical wording).
  final String? decisionSummary;

  factory CommunityActionPlanResult.fromJson(Map<String, dynamic> json) {
    return CommunityActionPlanResult(
      action: json['action'] as String? ?? 'create_post',
      postNature: json['postNature'] as String?,
      targetAudience: json['targetAudience'] as String?,
      postInputMode: json['postInputMode'] as String?,
      locationSharingMode: json['locationSharingMode'] as String?,
      dangerLevel: json['dangerLevel'] as String?,
      legacyType: json['legacyType'] as String?,
      generatedContent: json['generatedContent'] as String?,
      helpType: json['helpType'] as String?,
      requesterProfile: json['requesterProfile'] as String?,
      helpInputMode: json['helpInputMode'] as String?,
      presetMessageKey: json['presetMessageKey'] as String?,
      generatedDescription: json['generatedDescription'] as String?,
      needsAudioGuidance: json['needsAudioGuidance'] == true,
      needsVisualSupport: json['needsVisualSupport'] == true,
      needsPhysicalAssistance: json['needsPhysicalAssistance'] == true,
      needsSimpleLanguage: json['needsSimpleLanguage'] == true,
      isForAnotherPerson: json['isForAnotherPerson'] == true,
      predictedPriority: json['predictedPriority'] as String?,
      recommendedRoute: json['recommendedRoute'] as String?,
      routeReason: json['routeReason'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
      routeConfidence: (json['routeConfidence'] as num?)?.toDouble(),
      decisionStrength: (json['decisionStrength'] as num?)?.toDouble(),
      requiresConfirmation: json['requiresConfirmation'] as bool?,
      decisionSummary: json['decisionSummary'] as String?,
    );
  }

  bool shouldAutoNavigate({double minConfidence = 0.85}) {
    if (requiresConfirmation == true) return false;
    final route = recommendedRoute?.trim();
    final conf = confidence;
    return route != null && route.isNotEmpty && conf != null && conf >= minConfidence;
  }

  /// Comme [shouldAutoNavigate] sans tenir compte de [requiresConfirmation],
  /// pour décider si le seuil de confiance suffit à une ouverture directe (écran d’entrée IA).
  bool shouldAutoNavigateForEntryScreen({double minConfidence = 0.85}) {
    final route = recommendedRoute?.trim();
    final conf = confidence;
    return route != null && route.isNotEmpty && conf != null && conf >= minConfidence;
  }

  CreatePostInput toCreatePostInput() {
    return CreatePostInput(
      contenu: generatedContent ?? '',
      type: legacyType ?? 'general',
      postNature: postNature,
      targetAudience: targetAudience,
      inputMode: postInputMode,
      isForAnotherPerson: isForAnotherPerson,
      needsAudioGuidance: needsAudioGuidance,
      needsVisualSupport: needsVisualSupport,
      needsPhysicalAssistance: needsPhysicalAssistance,
      needsSimpleLanguage: needsSimpleLanguage,
      locationSharingMode: locationSharingMode,
      dangerLevel: dangerLevel,
    );
  }

  CreateHelpRequestInput toCreateHelpRequestInput({
    required double latitude,
    required double longitude,
  }) {
    return CreateHelpRequestInput(
      description: generatedDescription,
      latitude: latitude,
      longitude: longitude,
      helpType: helpType,
      inputMode: helpInputMode,
      requesterProfile: requesterProfile,
      needsAudioGuidance: needsAudioGuidance,
      needsVisualSupport: needsVisualSupport,
      needsPhysicalAssistance: needsPhysicalAssistance,
      needsSimpleLanguage: needsSimpleLanguage,
      isForAnotherPerson: isForAnotherPerson,
      presetMessageKey: presetMessageKey,
    );
  }
}

/// Extrait le chemin seul (sans query) depuis une route GoRouter ou une URL complète.
String communityActionPlanPathOnly(String? recommendedRoute) {
  final raw = recommendedRoute?.trim() ?? '';
  if (raw.isEmpty) return '';
  if (raw.contains('://')) {
    return Uri.parse(raw).path;
  }
  final q = raw.indexOf('?');
  final pathPart = q >= 0 ? raw.substring(0, q) : raw;
  return pathPart.isEmpty ? '/' : pathPart;
}

String _trimTrailingSlash(String p) {
  if (p.length > 1 && p.endsWith('/')) {
    return p.substring(0, p.length - 1);
  }
  return p;
}

/// Indique si la route IA pointe vers le même écran que [locationPath] (GoRouter).
bool communityActionRecommendedRouteMatchesLocation(
  String? recommendedRoute,
  String locationPath,
) {
  final a = _trimTrailingSlash(communityActionPlanPathOnly(recommendedRoute));
  final b = _trimTrailingSlash(locationPath.trim());
  return a.isNotEmpty && b.isNotEmpty && a == b;
}

