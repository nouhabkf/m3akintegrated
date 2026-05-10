export const PLACE_EXTRACTION_CATEGORY_VALUES = [
  'obstacle',
  'danger',
  'accessibility',
  'information',
] as const;

export type PlaceExtractionCategory =
  (typeof PLACE_EXTRACTION_CATEGORY_VALUES)[number];
