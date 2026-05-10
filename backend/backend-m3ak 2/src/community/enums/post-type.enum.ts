/**
 * Types de post communauté — alignés sur le modèle Flutter `PostType` (toApiString).
 * Utilisation : `@ApiProperty({ enum: PostTypeCommunity })`, filtres MongoDB, validation DTO.
 */
export enum PostTypeCommunity {
  general = 'general',
  handicapMoteur = 'handicapMoteur',
  handicapVisuel = 'handicapVisuel',
  handicapAuditif = 'handicapAuditif',
  handicapCognitif = 'handicapCognitif',
  conseil = 'conseil',
  temoignage = 'temoignage',
  autre = 'autre',
}

export const POST_TYPE_VALUES = Object.values(PostTypeCommunity) as string[];
