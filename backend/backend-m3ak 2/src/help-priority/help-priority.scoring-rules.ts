import {
  ALONE_SCORE,
  HIGH_MAX,
  INCLUSIVE_ACCESSIBILITY_NEED_SCORE,
  INCLUSIVE_CAREGIVER_FOR_OTHER_SCORE,
  INCLUSIVE_COMMUNICATION_MODERATE_SCORE,
  INCLUSIVE_INPUT_ESCALATION_SCORE,
  INCLUSIVE_MOBILITY_UNSAFE_ACCESS_SCORE,
  INCLUSIVE_PHYSICAL_ASSISTANCE_SCORE,
  INCLUSIVE_VISUAL_ORIENTATION_SCORE,
  LOW_MAX,
  LOW_URGENCY_KEYWORDS,
  LOW_URGENCY_SCORE,
  MEDIUM_KEYWORDS,
  MEDIUM_MAX,
  MEDIUM_KEYWORD_SCORE,
  MOTOR_ACCESS_HINTS,
  NEARBY_OBSTACLE_SCORE,
  NIGHT_SCORE,
  NO_ACCEPTED_HELPER_SCORE,
  PROFILE_CONTEXT_BONUS,
  URGENT_KEYWORDS,
  URGENT_KEYWORD_SCORE,
  VISUAL_CONTEXT_HINTS,
  WAITING_15_SCORE,
  WAITING_30_SCORE,
} from './help-priority.constants';
import type { HelpPriorityInput, HelpPriorityLevel, HelpUserProfile } from './help-priority.types';

/** Fenêtre « nuit » : 21h → 6h (locales), inclusive. */
export function isNightWindow(hour: number | undefined): boolean {
  if (hour === undefined || !Number.isFinite(hour)) return false;
  const h = Math.floor(hour);
  if (h < 0 || h > 23) return false;
  return h >= 21 || h <= 6;
}

export function scoreToLevel(score: number): HelpPriorityLevel {
  if (score <= LOW_MAX) return 'low';
  if (score <= MEDIUM_MAX) return 'medium';
  if (score <= HIGH_MAX) return 'high';
  return 'critical';
}

/**
 * Déduplique les signaux en conservant l’ordre d’insertion (première occurrence gardée).
 */
export function dedupeSignalsPreserveOrder(signals: string[]): string[] {
  const out: string[] = [];
  const seen = new Set<string>();
  for (const s of signals) {
    if (seen.has(s)) continue;
    seen.add(s);
    out.push(s);
  }
  return out;
}

function appendSignalUnique(signals: string[], signal: string): void {
  if (!signals.includes(signal)) signals.push(signal);
}

/**
 * Un groupe de mots-clés : score fixe si au moins une correspondance, signal agrégé.
 */
function applyKeywordGroup(
  text: string,
  keywords: readonly string[],
  scoreIfAnyHit: number,
  signalLabel: 'urgent' | 'moderate' | 'low',
): { scoreDelta: number; signal: string | null } {
  const hits = keywords.filter((k) => text.includes(k));
  if (hits.length === 0) {
    return { scoreDelta: 0, signal: null };
  }
  const joined = hits.join(',');
  const signal =
    signalLabel === 'urgent'
      ? `texte:mots_urgents(${joined})`
      : signalLabel === 'moderate'
        ? `texte:mots_modérés(${joined})`
        : `texte:faible_urgence(${joined})`;
  return { scoreDelta: scoreIfAnyHit, signal };
}

/** Détecte les indices « accès / mobilité » pour profil moteur (FR + EN). */
export function findMotorAccessHits(text: string): string[] {
  return MOTOR_ACCESS_HINTS.filter((hint) => text.includes(hint.toLowerCase())).map((h) =>
    h.toLowerCase(),
  );
}

/** Détecte les indices pertinents pour profil visuel (phrases + mots). */
export function findVisualContextHits(text: string): string[] {
  const hits: string[] = [];
  for (const hint of VISUAL_CONTEXT_HINTS) {
    const h = hint.toLowerCase();
    if (text.includes(h)) hits.push(h);
  }
  return [...new Set(hits)];
}

/**
 * Évaluation déterministe (règles métier). Même ordre de signaux et mêmes seuils que l’historique.
 * Pour une extension ML : combiner le score retourné ici avec un delta issu d’un autre module,
 * puis fusionner / dédupliquer les signaux côté orchestration.
 */
export function evaluateRuleBasedHelpPriority(
  input: HelpPriorityInput,
  normalizedText: string,
): { score: number; signals: string[] } {
  const signals: string[] = [];
  let score = 0;

  const urgent = applyKeywordGroup(normalizedText, URGENT_KEYWORDS, URGENT_KEYWORD_SCORE, 'urgent');
  const hadUrgentKeywords = urgent.signal !== null;
  if (urgent.signal) {
    score += urgent.scoreDelta;
    appendSignalUnique(signals, urgent.signal);
  }

  const medium = applyKeywordGroup(normalizedText, MEDIUM_KEYWORDS, MEDIUM_KEYWORD_SCORE, 'moderate');
  if (medium.signal) {
    score += medium.scoreDelta;
    appendSignalUnique(signals, medium.signal);
  }

  const low = applyKeywordGroup(normalizedText, LOW_URGENCY_KEYWORDS, LOW_URGENCY_SCORE, 'low');
  if (low.signal) {
    score += low.scoreDelta;
    appendSignalUnique(signals, low.signal);
  }

  if (input.hasNearbyObstacle === true) {
    score += NEARBY_OBSTACLE_SCORE;
    appendSignalUnique(signals, 'contexte:obstacle_proche');
  }

  if (input.isAlone === true) {
    score += ALONE_SCORE;
    appendSignalUnique(signals, 'contexte:seul');
  }

  if (input.hasAcceptedHelper === false) {
    score += NO_ACCEPTED_HELPER_SCORE;
    appendSignalUnique(signals, 'contexte:pas_daidant_accepté');
  }

  const w = input.waitingMinutes;
  if (w !== undefined && Number.isFinite(w) && w >= 0) {
    if (w >= 30) {
      score += WAITING_30_SCORE;
      appendSignalUnique(signals, 'temps:attente_30min_ou_plus');
    } else if (w >= 15) {
      score += WAITING_15_SCORE;
      appendSignalUnique(signals, 'temps:attente_15min_ou_plus');
    }
  }

  if (isNightWindow(input.hour)) {
    score += NIGHT_SCORE;
    appendSignalUnique(signals, `temps:fenêtre_nocturne(heure=${input.hour})`);
  }

  applyProfileBonuses(input.userProfile, normalizedText, signals, (delta) => {
    score += delta;
  });

  applyInclusiveFieldRules(input, normalizedText, signals, hadUrgentKeywords, (delta) => {
    score += delta;
  });

  return { score, signals };
}

/**
 * Règles métier liées aux champs inclusifs (formulaire, profil déclaré, besoins).
 * Les clients qui n’envoient pas ces champs ne modifient pas le score.
 */
function applyInclusiveFieldRules(
  input: HelpPriorityInput,
  normalizedText: string,
  signals: string[],
  hadUrgentKeywords: boolean,
  addScore: (delta: number) => void,
): void {
  const d = input.declaredRequesterProfile;
  const ht = input.helpType;
  const isVisual =
    d === 'visual' || input.userProfile === 'visual';

  // Mobilité / accès difficile (unsafe_access ou mobilité + profil moteur ou aide physique combinée)
  const mobilityUnsafeCombo =
    ht === 'unsafe_access' ||
    (ht === 'mobility' && d === 'motor') ||
    (ht === 'mobility' && input.needsPhysicalAssistance === true);
  if (mobilityUnsafeCombo) {
    addScore(INCLUSIVE_MOBILITY_UNSAFE_ACCESS_SCORE);
    appendSignalUnique(signals, 'inclusif:mobilité_accès_difficile');
  }

  // Visuel + orientation ou indices « perdu » dans le texte (contexte orientation)
  const orientationType = ht === 'orientation';
  const lostInText =
    normalizedText.includes('perdu') ||
    normalizedText.includes('perdue') ||
    normalizedText.includes('orientation');
  if (isVisual && (orientationType || lostInText)) {
    addScore(INCLUSIVE_VISUAL_ORIENTATION_SCORE);
    appendSignalUnique(signals, 'inclusif:visuel_orientation_ou_perdu');
  }

  // Accompagnant demandant pour un tiers
  if (
    input.isForAnotherPerson === true &&
    (d === 'caregiver' || input.userProfile === 'caregiver')
  ) {
    addScore(INCLUSIVE_CAREGIVER_FOR_OTHER_SCORE);
    appendSignalUnique(signals, 'inclusif:accompagnant_pour_tiers');
  }

  if (input.needsPhysicalAssistance === true) {
    addScore(INCLUSIVE_PHYSICAL_ASSISTANCE_SCORE);
    appendSignalUnique(signals, 'inclusif:besoin_aide_physique');
  }

  // Communication : modéré si pas de mots urgents dans le texte
  if (ht === 'communication' && !hadUrgentKeywords) {
    addScore(INCLUSIVE_COMMUNICATION_MODERATE_SCORE);
    appendSignalUnique(signals, 'inclusif:communication_modérée_sans_mots_urgents');
  }

  // Modes de saisie « rapides »
  if (input.inputMode === 'volume_shortcut' || input.inputMode === 'haptic') {
    addScore(INCLUSIVE_INPUT_ESCALATION_SCORE);
    appendSignalUnique(signals, `inclusif:mode_saisie_rapide(${input.inputMode})`);
  }

  // Besoins d’accessibilité déclarés (plafonnés pour limiter l’inflation)
  let needScore = 0;
  const needTags: string[] = [];
  if (input.needsAudioGuidance === true) {
    needScore += INCLUSIVE_ACCESSIBILITY_NEED_SCORE;
    needTags.push('audio');
  }
  if (input.needsVisualSupport === true) {
    needScore += INCLUSIVE_ACCESSIBILITY_NEED_SCORE;
    needTags.push('visuel');
  }
  if (input.needsSimpleLanguage === true) {
    needScore += INCLUSIVE_ACCESSIBILITY_NEED_SCORE;
    needTags.push('langage_simple');
  }
  const capped = Math.min(needScore, 3);
  if (capped > 0) {
    addScore(capped);
    appendSignalUnique(
      signals,
      `inclusif:besoins_accessibilité(${needTags.slice(0, 5).join(',')})`,
    );
  }
}

function applyProfileBonuses(
  profile: HelpUserProfile | undefined,
  text: string,
  signals: string[],
  addScore: (delta: number) => void,
): void {
  if (profile === 'motor') {
    const motorHits = findMotorAccessHits(text);
    if (motorHits.length > 0) {
      addScore(PROFILE_CONTEXT_BONUS);
      appendSignalUnique(signals, `profil_moteur:accès(${motorHits.slice(0, 6).join(',')})`);
    }
  }

  if (profile === 'visual') {
    const visualHits = findVisualContextHits(text);
    if (visualHits.length > 0) {
      addScore(PROFILE_CONTEXT_BONUS);
      appendSignalUnique(signals, `profil_visuel:contexte(${visualHits.slice(0, 8).join(',')})`);
    }
  }
}
