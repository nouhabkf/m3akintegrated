export interface CommunityActionPlanResponseDto {
  action: 'create_post' | 'create_help_request';

  postNature?:
    | 'signalement'
    | 'conseil'
    | 'temoignage'
    | 'information'
    | 'alerte'
    | null;
  targetAudience?:
    | 'all'
    | 'motor'
    | 'visual'
    | 'hearing'
    | 'cognitive'
    | 'caregiver'
    | null;
  postInputMode?:
    | 'keyboard'
    | 'voice'
    | 'headEyes'
    | 'vibration'
    | 'deafBlind'
    | 'caregiver'
    | null;
  locationSharingMode?: 'none' | 'approximate' | 'precise' | null;
  dangerLevel?: 'none' | 'low' | 'medium' | 'critical' | null;
  legacyType?:
    | 'general'
    | 'handicapMoteur'
    | 'handicapVisuel'
    | 'handicapAuditif'
    | 'handicapCognitif'
    | 'conseil'
    | 'temoignage'
    | 'autre'
    | null;
  generatedContent?: string | null;

  helpType?:
    | 'mobility'
    | 'orientation'
    | 'communication'
    | 'medical'
    | 'escort'
    | 'unsafe_access'
    | 'other'
    | null;
  requesterProfile?:
    | 'visual'
    | 'motor'
    | 'hearing'
    | 'cognitive'
    | 'caregiver'
    | 'unknown'
    | null;
  helpInputMode?:
    | 'text'
    | 'voice'
    | 'tap'
    | 'haptic'
    | 'volume_shortcut'
    | 'caregiver'
    | null;
  presetMessageKey?:
    | 'blocked'
    | 'lost'
    | 'cannot_reach'
    | 'medical_urgent'
    | 'escort'
    | null;
  generatedDescription?: string | null;

  needsAudioGuidance: boolean;
  needsVisualSupport: boolean;
  needsPhysicalAssistance: boolean;
  needsSimpleLanguage: boolean;
  isForAnotherPerson: boolean;

  predictedPriority?: 'low' | 'medium' | 'high' | 'critical' | null;
  recommendedRoute?: string | null;
  routeReason?: string | null;
  confidence?: number | null;
  routeConfidence?: number | null;
  decisionStrength?: number | null;
  requiresConfirmation?: boolean | null;
  decisionSummary?: string | null;
}
