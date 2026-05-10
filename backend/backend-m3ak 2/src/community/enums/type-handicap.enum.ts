import { Role } from '../../user/enums/role.enum';
import { PostTypeCommunity } from './post-type.enum';

/**
 * Valeurs courantes pour `User.typeHandicap` (profil HANDICAPE).
 * Le stockage reste une string pour compatibilité ; l’enum documente les cas couverts par le smart filter.
 */
export enum TypeHandicap {
  VISUEL = 'VISUEL',
  MOTEUR = 'MOTEUR',
  AUDITIF = 'AUDITIF',
  COGNITIF = 'COGNITIF',
}

/** Détecte un handicap visuel (chaînes API variées). */
export function isVisualHandicap(typeHandicap: string | null | undefined): boolean {
  if (!typeHandicap) return false;
  const t = typeHandicap.toLowerCase();
  return (
    t.includes('visuel') ||
    t.includes('visual') ||
    t === 'vis' ||
    t.includes('cécité') ||
    t.includes('cecite')
  );
}

const CROSS_CUTTING: PostTypeCommunity[] = [
  PostTypeCommunity.general,
  PostTypeCommunity.conseil,
  PostTypeCommunity.temoignage,
  PostTypeCommunity.autre,
];

/**
 * Types de posts à privilégier pour le filtre « smart » selon le profil.
 * Retourne [] si pas de filtre ciblé (ex. accompagnant → tout le fil général côté client).
 */
export function postTypesForHandicapProfile(
  role: string | null | undefined,
  typeHandicap: string | null | undefined,
): string[] {
  if (role && String(role).toUpperCase() !== Role.HANDICAPE) {
    return [];
  }
  if (!typeHandicap || !typeHandicap.trim()) {
    return [...CROSS_CUTTING];
  }
  const t = typeHandicap.toLowerCase();
  if (t.includes('visuel') || t.includes('visual') || t === 'vis') {
    return [...CROSS_CUTTING, PostTypeCommunity.handicapVisuel];
  }
  if (t.includes('moteur')) {
    return [...CROSS_CUTTING, PostTypeCommunity.handicapMoteur];
  }
  if (t.includes('auditif')) {
    return [...CROSS_CUTTING, PostTypeCommunity.handicapAuditif];
  }
  if (t.includes('cognitif')) {
    return [...CROSS_CUTTING, PostTypeCommunity.handicapCognitif];
  }
  return [...CROSS_CUTTING];
}
