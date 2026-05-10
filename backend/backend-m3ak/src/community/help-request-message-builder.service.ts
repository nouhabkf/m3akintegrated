import { Injectable } from '@nestjs/common';
import {
  HELP_REQUEST_PRESET_MESSAGES_FR,
  HELP_TYPE_SENTENCES_CAREGIVER_FR,
  HELP_TYPE_SENTENCES_FR,
  MEANINGFUL_DESCRIPTION_MIN_LENGTH,
} from './help-request-message-builder.constants';
import type { HelpRequestMessageBuilderInput } from './help-request-message-builder.types';

/**
 * Construit la chaîne `description` stockée sur une demande d’aide à partir
 * du texte libre et/ou des options inclusives (préréglages, profil, besoins).
 *
 * **Usage recommandé** : appeler `buildFinalDescription(...)` dans le flux de
 * création **avant** `getUrgencyScore`, `computePriority` et `save`, afin que
 * priorité et urgence IA reflètent le message réellement diffusé aux aidants.
 */
@Injectable()
export class HelpRequestMessageBuilderService {
  /**
   * Texte libre conservé tel quel s’il est assez long (voir constante).
   */
  isMeaningfulRawDescription(raw: string | undefined): boolean {
    const t = (raw ?? '').trim();
    return t.length >= MEANINGFUL_DESCRIPTION_MIN_LENGTH;
  }

  /**
   * Produit la description finale (non vide si les entrées le permettent).
   * @throws Error si aucune combinaison ne permet de générer un message.
   */
  buildFinalDescription(input: HelpRequestMessageBuilderInput): string {
    if (this.isMeaningfulRawDescription(input.description)) {
      return (input.description ?? '').trim();
    }

    const preset = this.tryPreset(input);
    if (preset) return preset;

    const helpType = input.helpType ?? 'other';
    const actingAsCaregiver =
      input.isForAnotherPerson === true || input.requesterProfile === 'caregiver';

    if (actingAsCaregiver) {
      const base =
        HELP_TYPE_SENTENCES_CAREGIVER_FR[helpType] ?? HELP_TYPE_SENTENCES_CAREGIVER_FR.other;
      return this.appendAccessibilityNeeds(base, input, true);
    }

    let base = HELP_TYPE_SENTENCES_FR[helpType] ?? HELP_TYPE_SENTENCES_FR.other;

    // Affinage par profil si pas déjà couvert par le type
    base = this.refineWithProfile(base, input);

    return this.appendAccessibilityNeeds(base, input, false);
  }

  private tryPreset(input: HelpRequestMessageBuilderInput): string | null {
    const key = input.presetMessageKey?.trim();
    if (!key) return null;

    // Cas combiné type + préréglage (ex. accès dangereux + « blocked »)
    if (key === 'blocked' && input.helpType === 'unsafe_access') {
      return HELP_REQUEST_PRESET_MESSAGES_FR.blocked;
    }

    const direct = HELP_REQUEST_PRESET_MESSAGES_FR[key];
    if (direct) {
      // « blocked » seul : message mobilité / accès (ex. profil moteur)
      if (key === 'blocked') return HELP_REQUEST_PRESET_MESSAGES_FR.blocked;
      return direct;
    }

    return null;
  }

  private refineWithProfile(
    base: string,
    input: HelpRequestMessageBuilderInput,
  ): string {
    const p = input.requesterProfile;
    if (p === 'visual' && input.helpType === 'orientation') {
      return HELP_REQUEST_PRESET_MESSAGES_FR.lost;
    }
    if (p === 'motor' && input.helpType === 'unsafe_access') {
      return HELP_REQUEST_PRESET_MESSAGES_FR.blocked;
    }
    return base;
  }

  private appendAccessibilityNeeds(
    base: string,
    input: HelpRequestMessageBuilderInput,
    caregiver: boolean,
  ): string {
    const bits: string[] = [];
    if (input.needsAudioGuidance) {
      bits.push(
        caregiver
          ? 'La personne a besoin de consignes orales claires.'
          : 'J’ai besoin de consignes orales claires.',
      );
    }
    if (input.needsVisualSupport) {
      bits.push(
        caregiver
          ? 'La personne a besoin d’aide visuelle ou de repères concrets.'
          : 'J’ai besoin d’aide visuelle ou de repères concrets.',
      );
    }
    if (input.needsPhysicalAssistance) {
      bits.push(
        caregiver
          ? 'La personne a besoin d’une aide physique sur place.'
          : 'J’ai besoin d’une aide physique sur place.',
      );
    }
    if (input.needsSimpleLanguage) {
      bits.push(
        caregiver
          ? 'Merci d’utiliser des phrases simples et courtes avec la personne.'
          : 'Merci d’utiliser des phrases simples et courtes.',
      );
    }
    if (bits.length === 0) return base;
    return `${base} ${bits.join(' ')}`.trim();
  }
}
