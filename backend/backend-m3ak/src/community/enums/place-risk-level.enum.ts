export const PLACE_RISK_LEVEL_VALUES = ['safe', 'caution', 'danger'] as const;
export type PlaceRiskLevel = (typeof PLACE_RISK_LEVEL_VALUES)[number];
