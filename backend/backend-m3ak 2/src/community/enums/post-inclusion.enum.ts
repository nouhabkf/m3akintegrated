/**
 * Champs inclusifs optionnels pour la création de posts (rétrocompatibles).
 */

export const POST_NATURE_VALUES = [
  'signalement',
  'conseil',
  'temoignage',
  'information',
  'alerte',
] as const;
export type PostNature = (typeof POST_NATURE_VALUES)[number];

export const POST_TARGET_AUDIENCE_VALUES = [
  'all',
  'motor',
  'visual',
  'hearing',
  'cognitive',
  'caregiver',
] as const;
export type PostTargetAudience = (typeof POST_TARGET_AUDIENCE_VALUES)[number];

export const POST_INPUT_MODE_VALUES = [
  'keyboard',
  'voice',
  'headEyes',
  'vibration',
  'deafBlind',
  'caregiver',
] as const;
export type PostInputMode = (typeof POST_INPUT_MODE_VALUES)[number];

export const POST_LOCATION_SHARING_MODE_VALUES = [
  'none',
  'approximate',
  'precise',
] as const;
export type PostLocationSharingMode =
  (typeof POST_LOCATION_SHARING_MODE_VALUES)[number];
