/**
 * Messages prédéfinis (FR) pour demandes d’aide rapides ou modes accessibilité.
 * Clés utilisées par {@link HelpRequestMessageBuilderService}.
 */

/** Phrases complètes pour presetMessageKey (prioritaires si pas de texte libre significatif). */
export const HELP_REQUEST_PRESET_MESSAGES_FR: Record<string, string> = {
  blocked:
    'Je suis bloqué. L’accès semble difficile ou inaccessible. J’ai besoin d’aide sur place.',
  lost: 'Je suis perdu et j’ai besoin d’aide pour m’orienter.',
  cannot_reach: "Je n’arrive pas à accéder ou à joindre quelqu’un. J’ai besoin d’aide.",
  medical_urgent: "J’ai besoin d’aide liée à un problème de santé ou de confort immédiat.",
  escort: "J’ai besoin d’être accompagné·e pour me déplacer ou pour communiquer.",
};

/** Phrases par type d’aide (sans préréglage clé), 1re personne. */
export const HELP_TYPE_SENTENCES_FR: Record<
  string,
  string
> = {
  mobility: "J’ai besoin d’aide pour me déplacer ou pour une assistance de mobilité.",
  orientation: 'Je suis perdu·e et j’ai besoin d’aide pour m’orienter.',
  communication: "J’ai besoin d’aide pour communiquer ou me faire comprendre.",
  medical: "J’ai besoin d’aide pour un problème de santé ou de bien-être immédiat.",
  escort: "J’ai besoin d’être accompagné·e.",
  unsafe_access:
    'L’accès semble difficile ou dangereux. J’ai besoin d’aide sur place.',
  other: "J’ai besoin d’aide.",
};

/** Variantes accompagnant / tiers (isForAnotherPerson). */
export const HELP_TYPE_SENTENCES_CAREGIVER_FR: Record<string, string> = {
  mobility:
    'Je demande de l’aide pour une personne ayant besoin d’une assistance de mobilité.',
  orientation:
    'Je demande de l’aide pour une personne qui a besoin de s’orienter ou de se repérer.',
  communication:
    'Je demande de l’aide pour une personne qui a besoin d’aide pour communiquer.',
  medical:
    'Je demande de l’aide pour une personne ayant un besoin médical ou de confort immédiat.',
  escort: 'Je demande un accompagnement pour une personne.',
  unsafe_access:
    'Je signale un accès difficile ou dangereux pour une personne qui a besoin d’aide sur place.',
  other: 'Je demande de l’aide pour une personne.',
};

/** Longueur minimale (caractères) pour considérer le texte libre comme « significatif ». */
export const MEANINGFUL_DESCRIPTION_MIN_LENGTH = 5;
