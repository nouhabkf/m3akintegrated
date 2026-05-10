/**
 * Champs inclusifs pour les demandes d’aide (optionnels, rétrocompatibles).
 */

export const HELP_REQUEST_HELP_TYPES = [
  'mobility',
  'orientation',
  'communication',
  'medical',
  'escort',
  'unsafe_access',
  'other',
] as const;
export type HelpRequestHelpType = (typeof HELP_REQUEST_HELP_TYPES)[number];

export const HELP_REQUEST_INPUT_MODES = [
  'text',
  'voice',
  'tap',
  'haptic',
  'volume_shortcut',
  'caregiver',
] as const;
export type HelpRequestInputMode = (typeof HELP_REQUEST_INPUT_MODES)[number];

export const HELP_REQUEST_REQUESTER_PROFILES = [
  'visual',
  'motor',
  'hearing',
  'cognitive',
  'caregiver',
  'unknown',
] as const;
export type HelpRequestRequesterProfile = (typeof HELP_REQUEST_REQUESTER_PROFILES)[number];
