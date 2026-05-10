import type { HelpPriorityLevel } from './help-priority.types';

const NIVEAU: Record<HelpPriorityLevel, string> = {
  low: 'faible',
  medium: 'modérée',
  high: 'élevée',
  critical: 'critique',
};

/**
 * Phrase lisible en français pour expliquer le résultat (règles métier).
 * Réutilisable si une couche ML ajoute des signaux supplémentaires au même format.
 */
export function buildFrenchHelpPriorityReason(
  priority: HelpPriorityLevel,
  score: number,
  signals: string[],
): string {
  const intro = `La priorité estimée est ${NIVEAU[priority]} (score total : ${score}).`;

  if (signals.length === 0) {
    return `${intro} Aucun indicateur fort n’a été détecté dans le message ni le contexte.`;
  }

  const detail = signals
    .slice(0, 12)
    .map((s) => signalToFrenchFragment(s))
    .join(' ');

  return `${intro} Éléments retenus : ${detail}`;
}

/** Traduit un signal technique en fragment court pour la phrase finale. */
function signalToFrenchFragment(signal: string): string {
  if (signal.startsWith('texte:mots_urgents'))
    return 'le message contient des termes urgents ;';
  if (signal.startsWith('texte:mots_modérés'))
    return 'le message évoque un besoin d’aide ou d’accès ;';
  if (signal.startsWith('texte:faible_urgence'))
    return 'le message indique que ce n’est pas urgent ;';
  if (signal.startsWith('contexte:obstacle_proche'))
    return 'un obstacle a été signalé à proximité ;';
  if (signal === 'contexte:seul') return 'la personne est seule ;';
  if (signal.startsWith('contexte:pas_daidant_accepté'))
    return 'aucun aidant n’a encore accepté la demande ;';
  if (signal.startsWith('temps:attente_30'))
    return 'l’attente dépasse trente minutes ;';
  if (signal.startsWith('temps:attente_15'))
    return 'l’attente dépasse quinze minutes ;';
  if (signal.startsWith('temps:fenêtre_nocturne'))
    return 'la demande tombe dans une plage horaire à risque (nuit) ;';
  if (signal.startsWith('profil_moteur:'))
    return 'le profil moteur et le texte évoquent l’accès (escalier, rampe, etc.) ;';
  if (signal.startsWith('profil_visuel:'))
    return 'le profil visuel et le texte évoquent le risque ou la perte de repères ;';
  if (signal.startsWith('inclusif:mobilité_accès_difficile'))
    return 'la demande concerne la mobilité ou un accès difficile ;';
  if (signal.startsWith('inclusif:visuel_orientation_ou_perdu'))
    return 'le besoin d’orientation ou de repérage est signalé (profil visuel ou texte) ;';
  if (signal.startsWith('inclusif:accompagnant_pour_tiers'))
    return 'un accompagnant demande de l’aide pour une autre personne ;';
  if (signal.startsWith('inclusif:besoin_aide_physique'))
    return 'une aide physique sur place est nécessaire ;';
  if (signal.startsWith('inclusif:communication_modérée'))
    return 'la demande porte sur la communication, sans mot urgent dans le texte ;';
  if (signal.startsWith('inclusif:mode_saisie_rapide'))
    return 'la demande a été lancée via un mode de saisie rapide (volume ou haptique) ;';
  if (signal.startsWith('inclusif:besoins_accessibilité'))
    return 'des besoins d’accessibilité (audio, visuel ou langage simple) sont indiqués ;';
  if (signal.startsWith('inclusif:')) return 'un critère inclusif du formulaire augmente la priorité ;';
  return `${signal} ;`;
}
