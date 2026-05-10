/**
 * Types for the rule-based Help Priority model (no ML).
 */

export type HelpPriorityLevel = 'low' | 'medium' | 'high' | 'critical';

export type HelpUserProfile =
  | 'visual'
  | 'motor'
  | 'hearing'
  | 'cognitive'
  | 'caregiver';

/** Types de besoin (alignés sur la demande d’aide inclusive). */
export type HelpPriorityHelpType =
  | 'mobility'
  | 'orientation'
  | 'communication'
  | 'medical'
  | 'escort'
  | 'unsafe_access'
  | 'other';

/** Mode de saisie côté client. */
export type HelpPriorityInputMode =
  | 'text'
  | 'voice'
  | 'tap'
  | 'haptic'
  | 'volume_shortcut'
  | 'caregiver';

/** Profil déclaré sur la demande (peut compléter ou préciser userProfile). */
export type HelpPriorityDeclaredProfile =
  | 'visual'
  | 'motor'
  | 'hearing'
  | 'cognitive'
  | 'caregiver'
  | 'unknown';

export interface HelpPriorityInput {
  text: string;
  hasNearbyObstacle?: boolean;
  isAlone?: boolean;
  hasAcceptedHelper?: boolean;
  /** Minutes since the request was created (waiting). */
  waitingMinutes?: number;
  /** Local hour 0–23 (used for night risk). */
  hour?: number;
  /** Profil utilisateur résolu (rôle / typeHandicap) ou depuis la demande. */
  userProfile?: HelpUserProfile;

  /** Champs optionnels — clients legacy : absents. */
  helpType?: HelpPriorityHelpType;
  inputMode?: HelpPriorityInputMode;
  /** Profil coché sur le formulaire d’aide (distinct du profil JWT si besoin). */
  declaredRequesterProfile?: HelpPriorityDeclaredProfile;
  isForAnotherPerson?: boolean;
  needsAudioGuidance?: boolean;
  needsVisualSupport?: boolean;
  needsPhysicalAssistance?: boolean;
  needsSimpleLanguage?: boolean;
}

export interface HelpPriorityResult {
  priority: HelpPriorityLevel;
  /** Aggregated numeric score before level mapping (can be negative; clamped for display if needed). */
  score: number;
  /** Short human-readable explanation of the outcome. */
  reason: string;
  /** Machine-readable tags for what influenced the score. */
  matchedSignals: string[];
}

/**
 * Point d’extension pour une future couche ML : complément de score et signaux
 * additionnels à fusionner avec l’évaluation par règles (`help-priority.scoring-rules`).
 * Même format de préfixe `texte:` / `contexte:` recommandé pour la phrase FR.
 */
export interface HelpPriorityMlContributor {
  contribute(
    input: HelpPriorityInput,
    context: { normalizedText: string },
  ): Promise<{ scoreDelta: number; signals: string[] }> | { scoreDelta: number; signals: string[] };
}
