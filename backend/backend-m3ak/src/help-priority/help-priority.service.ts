import { Injectable } from '@nestjs/common';
import { buildFrenchHelpPriorityReason } from './help-priority.french-reason';
import {
  dedupeSignalsPreserveOrder,
  evaluateRuleBasedHelpPriority,
  scoreToLevel,
} from './help-priority.scoring-rules';
import { normalizeHelpPriorityText } from './help-priority.text';
import type { HelpPriorityInput, HelpPriorityResult } from './help-priority.types';

/**
 * Orchestration de la priorité d’aide : règles métier déterministes aujourd’hui ;
 * la logique est découpée pour pouvoir brancher plus tard un score ML
 * (ex. fusionner `evaluateRuleBasedHelpPriority` avec un delta issu d’un modèle).
 */
@Injectable()
export class HelpPriorityService {
  computePriority(input: HelpPriorityInput): HelpPriorityResult {
    const normalizedText = normalizeHelpPriorityText(input.text);
    const { score: ruleScore, signals: ruleSignals } = evaluateRuleBasedHelpPriority(
      input,
      normalizedText,
    );

    const matchedSignals = dedupeSignalsPreserveOrder(ruleSignals);
    const priority = scoreToLevel(ruleScore);
    const reason = buildFrenchHelpPriorityReason(priority, ruleScore, matchedSignals);

    return {
      priority,
      score: ruleScore,
      reason,
      matchedSignals,
    };
  }
}
