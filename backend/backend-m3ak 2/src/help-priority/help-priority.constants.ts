/**
 * Keyword groups and scoring weights for {@link HelpPriorityService}.
 * All logic is explicit and auditable (business rules only).
 */

/** Strong urgency cues in free text (French). */
export const URGENT_KEYWORDS = [
  'urgent',
  'bloqué',
  'impossible',
  'secours',
  'danger',
  'coincé',
  'perdu',
  'panique',
  'chute',
  'je ne peux pas',
] as const;

/** General help / access vocabulary (moderate signal). */
export const MEDIUM_KEYWORDS = [
  'aide',
  'besoin',
  'entrée',
  'passage',
  'accès',
  'sortir',
  'trouver',
  'accompagner',
] as const;

/** Explicit de-prioritization phrases. */
export const LOW_URGENCY_KEYWORDS = [
  'plus tard',
  'quand possible',
  'pas urgent',
  'plus tard svp',
  "ce n'est pas urgent",
  "ce n’est pas urgent",
] as const;

/** Text keyword contributions. */
export const URGENT_KEYWORD_SCORE = 3;
export const MEDIUM_KEYWORD_SCORE = 1;
export const LOW_URGENCY_SCORE = -2;

/** Context signals (non-text). */
export const NEARBY_OBSTACLE_SCORE = 3;
export const ALONE_SCORE = 2;
/** Applied when no helper has accepted yet (still waiting for someone). */
export const NO_ACCEPTED_HELPER_SCORE = 2;

/** Escalation by time already waited. */
export const WAITING_15_SCORE = 2;
export const WAITING_30_SCORE = 3;

/** Night window risk bump (see service: heures 21 → 6 inclus). */
export const NIGHT_SCORE = 1;

/** Profil moteur : indices d’accès / mobilité dans le texte (+1 si correspondance). */
export const MOTOR_ACCESS_HINTS = [
  'access',
  'stairs',
  'ramp',
  'passage',
  'accès',
  'escalier',
  'rampe',
] as const;

/** Profil visuel : indices de désorientation ou risque (+1 si correspondance). */
export const VISUAL_CONTEXT_HINTS = [
  'lost',
  'blocked',
  'cannot find',
  'danger',
  'perdu',
  'bloqué',
  'je ne trouve pas',
  'impossible de trouver',
] as const;

/** Bonus contextuel lié au profil + mots-clés ciblés. */
export const PROFILE_CONTEXT_BONUS = 1;

/** Métadonnées inclusives (formulaire / modes de saisie). */
export const INCLUSIVE_MOBILITY_UNSAFE_ACCESS_SCORE = 2;
export const INCLUSIVE_VISUAL_ORIENTATION_SCORE = 2;
export const INCLUSIVE_CAREGIVER_FOR_OTHER_SCORE = 1;
export const INCLUSIVE_PHYSICAL_ASSISTANCE_SCORE = 2;
export const INCLUSIVE_COMMUNICATION_MODERATE_SCORE = 1;
export const INCLUSIVE_ACCESSIBILITY_NEED_SCORE = 1;
/** Modes de saisie « rapides » (volume, haptique) : léger relèvement de risque. */
export const INCLUSIVE_INPUT_ESCALATION_SCORE = 1;

/**
 * Map total score → discrete level (inclusive upper bounds).
 * Below or equal LOW_MAX → low; above LOW_MAX and ≤ MEDIUM_MAX → medium; etc.
 */
export const LOW_MAX = 2;
export const MEDIUM_MAX = 5;
export const HIGH_MAX = 8;
