import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { PostPlaceExtractionResultDto } from './dto/post-place-extraction-result.dto';
import { PlaceRiskLevel } from './enums/place-risk-level.enum';
import { PlaceExtractionCategory } from './enums/place-extraction-category.enum';
import { AccessibilityService } from '../accessibility/accessibility.service';

/**
 * Couche IA **Communauté** : extraction lieu depuis le texte du post,
 * résumé commentaires, score urgence (délègue à {@link AccessibilityService}).
 */
@Injectable()
export class CommunityVisionService implements OnModuleInit {
  private readonly logger = new Logger(CommunityVisionService.name);

  constructor(private readonly accessibility: AccessibilityService) {}

  onModuleInit(): void {
    this.logger.log('CommunityVisionService prêt — extraction lieu + résumés commentaires.');
  }

  async flashSummaryFromComments(commentTexts: string[]) {
    return this.accessibility.flashSummaryFromComments(commentTexts);
  }

  async getUrgencyScore(description: string) {
    return this.accessibility.getUrgencyScore(description);
  }

  /**
   * Extraction "Lieu dans le post" (MVP robuste):
   * - détecte mention de lieu
   * - classe la catégorie
   * - calcule la confiance [0..1]
   * - déduit le niveau de risque visuel
   */
  async extractPlaceFromPost(params: {
    contenu: string;
    dangerLevel?: string;
    latitude?: number;
    longitude?: number;
    hasImages?: boolean;
  }): Promise<PostPlaceExtractionResultDto> {
    const text = (params.contenu ?? '').trim();
    const t = text.toLowerCase();
    const reasonCodes: string[] = [];

    const placeHints = [
      'rue',
      'avenue',
      'boulevard',
      'station',
      'gare',
      'pharmacie',
      'hôpital',
      'hopital',
      'clinique',
      'mosquée',
      'mosquee',
      'école',
      'ecole',
      'université',
      'universite',
      'centre',
      'supermarché',
      'supermarche',
      'arrêt',
      'arret',
      'place ',
    ];
    const hasPlaceHint = placeHints.some((k) => t.includes(k));
    if (hasPlaceHint) reasonCodes.push('place_hint_in_text');

    const obstacleHints = [
      'obstacle',
      'bloqué',
      'bloque',
      'cassé',
      'casse',
      'escalier',
      'trottoir',
      'fauteuil impossible',
      'rampe absente',
    ];
    const dangerHints = [
      'danger',
      'urgent',
      'risque',
      'accident',
      'inondation',
      'incendie',
      'impraticable',
    ];
    const accessibilityHints = [
      'accessible',
      'rampe',
      'ascenseur',
      'toilettes adaptées',
      'toilettes adaptees',
      'guidage',
    ];

    const hasObstacle = obstacleHints.some((k) => t.includes(k));
    const hasDangerWords = dangerHints.some((k) => t.includes(k));
    const hasAccessibilityWords = accessibilityHints.some((k) => t.includes(k));

    if (hasObstacle) reasonCodes.push('obstacle_words');
    if (hasDangerWords) reasonCodes.push('danger_words');
    if (hasAccessibilityWords) reasonCodes.push('accessibility_words');

    const hasCoords =
      Number.isFinite(params.latitude) && Number.isFinite(params.longitude);
    if (hasCoords) reasonCodes.push('gps_attached');
    if (params.hasImages) reasonCodes.push('images_attached');

    let category: PlaceExtractionCategory = 'information';
    if (hasObstacle) category = 'obstacle';
    else if (hasDangerWords || params.dangerLevel === 'critical') category = 'danger';
    else if (hasAccessibilityWords) category = 'accessibility';

    let riskLevel: PlaceRiskLevel = 'safe';
    if (params.dangerLevel === 'critical' || hasDangerWords) {
      riskLevel = 'danger';
    } else if (hasObstacle || params.dangerLevel === 'medium') {
      riskLevel = 'caution';
    }

    const obstaclePresent = hasObstacle || riskLevel !== 'safe';
    const hasPlace = hasPlaceHint || hasCoords || obstaclePresent;

    let confidence = 0.2;
    if (hasPlaceHint) confidence += 0.35;
    if (hasCoords) confidence += 0.15;
    if (hasObstacle) confidence += 0.2;
    if (hasDangerWords) confidence += 0.2;
    if (hasAccessibilityWords) confidence += 0.1;
    if (params.hasImages) confidence += 0.05;
    if (text.length >= 20) confidence += 0.05;
    confidence = Math.max(0, Math.min(1, confidence));

    const placeText = this.extractPlaceText(text);
    const summary = this.buildSummary(text, category, riskLevel);

    return {
      hasPlace,
      placeText,
      category,
      confidence,
      riskLevel,
      obstaclePresent,
      summary,
      reasonCodes,
    };
  }

  private extractPlaceText(text: string): string | null {
    const trimmed = text.trim();
    if (!trimmed) return null;

    const patterns = [
      /(?:rue|avenue|boulevard|station|gare|pharmacie|hopital|hôpital|clinique)\s+([^\n,.]{3,60})/i,
      /(?:à|au|aux)\s+([^\n,.]{3,60})/i,
    ];
    for (const p of patterns) {
      const m = trimmed.match(p);
      if (m?.[1]) {
        return m[1].trim();
      }
    }
    const firstLine = (trimmed.split('\n')[0] ?? '').trim();
    if (firstLine.length <= 80) return firstLine;
    return `${firstLine.substring(0, 77)}...`;
  }

  private buildSummary(
    text: string,
    category: PlaceExtractionCategory,
    riskLevel: PlaceRiskLevel,
  ): string | null {
    const clean = text.replace(/\s+/g, ' ').trim();
    if (!clean) return null;
    const base = clean.length > 180 ? `${clean.substring(0, 177)}...` : clean;
    if (riskLevel === 'danger') return `Alerte danger: ${base}`;
    if (category === 'obstacle') return `Obstacle signalé: ${base}`;
    return base;
  }
}
