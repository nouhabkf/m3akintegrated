import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AnalyzePlaceDto } from './dto/analyze-place.dto';

function countWords(s: string): number {
  const t = s.trim();
  if (!t) return 0;
  return t.split(/\s+/).filter(Boolean).length;
}

/**
 * Par défaut : Ollama **activé** si la variable est absente (repli heuristique si injoignable).
 * Pour désactiver explicitement : `OLLAMA_ENABLED=false`.
 */
function isOllamaEnabled(config: ConfigService): boolean {
  const raw = config.get<string>('OLLAMA_ENABLED');
  if (raw == null || String(raw).trim() === '') {
    return true;
  }
  const v = String(raw).trim().toLowerCase();
  if (v === 'false' || v === '0' || v === 'no' || v === 'off') {
    return false;
  }
  return v === 'true' || v === '1' || v === 'yes' || v === 'on';
}

@Injectable()
export class AccessibilityService implements OnModuleInit {
  private readonly logger = new Logger(AccessibilityService.name);
  private readonly nodeRegistry = new Map<number, { lat: number; lon: number }>();

  constructor(private readonly config: ConfigService) {}

  onModuleInit(): void {
    const f = this.getFeatureFlags();
    if (!f.ollamaEnabled) {
      this.logger.warn(
        `Ollama désactivé (OLLAMA_ENABLED=false). Résumés commentaires / score urgence → heuristique locale.`,
      );
    } else {
      this.logger.log(`Ollama activé — ${f.ollamaBaseUrl} | texte=${f.textModel}`);
    }
  }

  /** Pour l’app : savoir si l’IA locale (Ollama) est censée être active. */
  getFeatureFlags(): {
    ollamaEnabled: boolean;
    ollamaBaseUrl: string;
    textModel: string;
    visionModel: string;
  } {
    return {
      ollamaEnabled: isOllamaEnabled(this.config),
      ollamaBaseUrl: (
        this.config.get<string>('OLLAMA_BASE_URL') ?? 'http://127.0.0.1:11434'
      ).replace(/\/$/, ''),
      textModel: (this.config.get<string>('OLLAMA_MODEL') ?? 'llama3.2').trim(),
      visionModel: (this.config.get<string>('OLLAMA_VISION_MODEL') ?? 'llava').trim(),
    };
  }

  /**
   * GET /accessibility/features — flags + test HTTP vers Ollama (`/api/tags`, 5 s max).
   */
  async getFeatureFlagsWithOllamaPing(): Promise<
    ReturnType<AccessibilityService['getFeatureFlags']> & {
      ollamaReachable: boolean;
      ollamaPingMessage?: string;
    }
  > {
    const flags = this.getFeatureFlags();
    if (!flags.ollamaEnabled) {
      return {
        ...flags,
        ollamaReachable: false,
        ollamaPingMessage: 'OLLAMA_ENABLED=false dans .env',
      };
    }
    const tagsUrl = `${flags.ollamaBaseUrl}/api/tags`;
    try {
      const res = await fetch(tagsUrl, {
        signal: AbortSignal.timeout(5000),
      });
      if (res.ok) {
        return { ...flags, ollamaReachable: true };
      }
      return {
        ...flags,
        ollamaReachable: false,
        ollamaPingMessage: `Ollama HTTP ${res.status} (${tagsUrl})`,
      };
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      return {
        ...flags,
        ollamaReachable: false,
        ollamaPingMessage: `${msg} — lancer « ollama serve » et vérifier OLLAMA_BASE_URL`,
      };
    }
  }

  /**
   * Estime l'urgence d'une demande d'aide (1-5).
   * Si OLLAMA_ENABLED=true et Ollama est dispo : LLM local, sinon heuristique locale (zéro frais).
   */
  async getUrgencyScore(description: string): Promise<number> {
    const text = description.replace(/\s+/g, ' ').trim();
    if (!text) return 1;

    if (isOllamaEnabled(this.config)) {
      try {
        const s = await this.getUrgencyScoreWithOllama(text);
        if (s != null) return s;
      } catch (e) {
        this.logger.warn(`Ollama urgency score échoué, repli heuristique: ${e}`);
      }
    }
    return this.getUrgencyScoreHeuristic(text);
  }

  private async getUrgencyScoreWithOllama(description: string): Promise<number | null> {
    const baseUrl = (
      this.config.get<string>('OLLAMA_BASE_URL') ?? 'http://127.0.0.1:11434'
    ).replace(/\/$/, '');
    const model = this.config.get<string>('OLLAMA_MODEL') ?? 'llama3.2';
    const timeoutMs = Number(this.config.get<string>('OLLAMA_TIMEOUT_MS') ?? '120000');

    const prompt = `Sur une échelle de 1 à 5, quelle est l'urgence de cette demande d'aide ?
1 = pas urgent, 5 = urgence immédiate.
Réponds UNIQUEMENT par un nombre entre 1 et 5. Aucune autre phrase.

Demande:
${description}`;

    const res = await fetch(`${baseUrl}/api/generate`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model,
        prompt,
        stream: false,
        options: { num_predict: 12, temperature: 0.1 },
      }),
      signal: AbortSignal.timeout(Number.isFinite(timeoutMs) ? timeoutMs : 120000),
    });

    if (!res.ok) return null;
    const data = (await res.json()) as { response?: string };
    const raw = (data.response ?? '').toString();
    const match = raw.match(/[1-5]/);
    if (!match) return null;
    const n = Number(match[0]);
    if (!Number.isFinite(n)) return null;
    return Math.max(1, Math.min(5, n));
  }

  private getUrgencyScoreHeuristic(description: string): number {
    const t = description.toLowerCase();

    const urgentKeywords = [
      'urgence',
      'immédiat',
      'immediat',
      'tout de suite',
      'danger',
      'grave',
      'sang',
      'saigne',
      'détresse',
      'detresse',
      'douleur intense',
      'inconscient',
    ];

    const todayKeywords = ["aujourd'hui", 'vite', 'rapidement', 'au plus tard', 'ce soir'];

    if (urgentKeywords.some((k) => t.includes(k))) return 5;
    if (todayKeywords.some((k) => t.includes(k))) return 4;

    return 3;
  }

  /**
   * Résumé flash des commentaires — Ollama si activé, sinon heuristique.
   */
  async flashSummaryFromComments(commentTexts: string[]): Promise<{
    summary: string;
    keyPoints: string[];
    readingTimeSeconds: number;
    wordReduction: number;
  }> {
    if (isOllamaEnabled(this.config)) {
      try {
        const o = await this.flashSummaryWithOllama(commentTexts);
        if (o) return o;
      } catch (e) {
        this.logger.warn(`Ollama flash summary échoué, repli heuristique: ${e}`);
      }
    }
    return Promise.resolve(this.flashSummaryHeuristic(commentTexts));
  }

  private async flashSummaryWithOllama(commentTexts: string[]): Promise<{
    summary: string;
    keyPoints: string[];
    readingTimeSeconds: number;
    wordReduction: number;
  } | null> {
    const full = commentTexts.join(' ').replace(/\s+/g, ' ').trim();
    const originalWords = countWords(full);
    if (!full) {
      return {
        summary: 'Aucun commentaire pour résumer.',
        keyPoints: [],
        readingTimeSeconds: 0,
        wordReduction: 0,
      };
    }

    const baseUrl = (
      this.config.get<string>('OLLAMA_BASE_URL') ?? 'http://127.0.0.1:11434'
    ).replace(/\/$/, '');
    const model =
      this.config.get<string>('OLLAMA_MODEL') ?? 'llama3.2';
    const timeoutMs = Number(
      this.config.get<string>('OLLAMA_TIMEOUT_MS') ?? '120000',
    );

    const maxFlash = 2800;
    const fullCapped =
      full.length > maxFlash ? `${full.slice(0, maxFlash)} […]` : full;

    const prompt = `Résume les commentaires suivants en français en 2 à 4 phrases très courtes, vocabulaire simple. Une seule réponse continue, pas de liste numérotée.

Commentaires:
${fullCapped}

Résumé:`;

    const res = await fetch(`${baseUrl}/api/generate`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model,
        prompt,
        stream: false,
        options: { num_predict: 220, temperature: 0.35 },
      }),
      signal: AbortSignal.timeout(Number.isFinite(timeoutMs) ? timeoutMs : 120000),
    });

    if (!res.ok) return null;
    const data = (await res.json()) as { response?: string };
    const summary = (data.response ?? '').trim().replace(/\s+/g, ' ');
    if (!summary) return null;

    const summaryWords = countWords(summary);
    const sentences = summary.split(/(?<=[.!?])\s+/).map((s) => s.trim()).filter(Boolean);
    const keyPoints = sentences.slice(0, 5);

    return {
      summary,
      keyPoints: keyPoints.length ? keyPoints : [summary],
      readingTimeSeconds: Math.max(5, Math.round(summaryWords / 3)),
      wordReduction: Math.max(0, originalWords - summaryWords),
    };
  }

  private flashSummaryHeuristic(commentTexts: string[]): {
    summary: string;
    keyPoints: string[];
    readingTimeSeconds: number;
    wordReduction: number;
  } {
    const full = commentTexts.join(' ').replace(/\s+/g, ' ').trim();
    const originalWords = countWords(full);
    if (!full) {
      return {
        summary: 'Aucun commentaire pour résumer.',
        keyPoints: [],
        readingTimeSeconds: 0,
        wordReduction: 0,
      };
    }

    const sentences = full.split(/(?<=[.!?])\s+/).filter((s) => s.trim().length > 0);
    const picked = sentences.slice(0, 4);
    const summary = picked.join(' ');
    const summaryWords = countWords(summary);
    const keyPointsFull = picked.map((s) => s.trim()).filter((s) => s.length > 0);

    return {
      summary,
      keyPoints: keyPointsFull,
      readingTimeSeconds: Math.max(5, Math.round(summaryWords / 3)),
      wordReduction: Math.max(0, originalWords - summaryWords),
    };
  }

  getAccessibilityHealth() {
    return {
      status: 'ok',
      service: 'M3ak Accessibility',
      featureFlags: this.getFeatureFlags(),
    };
  }

  async getOsmTagsByLatLon(lat: number, lon: number): Promise<{
    tags: Record<string, string>;
    count: number;
  }> {
    const tags = await this.fetchOsmAccessibility(lat, lon);
    return { tags, count: Object.keys(tags).length };
  }

  async analyzePlace(dto: AnalyzePlaceDto) {
    const osmTags = await this.fetchOsmAccessibility(dto.latitude, dto.longitude);
    const merged = this.mergeAccessibilityData(dto, osmTags);
    const comments = dto.user_comments ?? [];
    const confidence = this.computeConfidenceLabel(merged);

    const fauteuil = this.computeFauteuilScore(merged);
    const mobilite = this.computeMobiliteReduiteScore(merged);
    const cecite = this.computeCeciteScore(merged);
    const surdite = this.computeSurditeScore(merged);
    const cognitif = this.computeCognitifScore(merged, comments);

    const scoreGlobal = Math.round(
      fauteuil.score * 0.3 +
        mobilite.score * 0.25 +
        cecite.score * 0.2 +
        surdite.score * 0.15 +
        cognitif.score * 0.1,
    );

    return {
      place_name: dto.place_name,
      score_global: Math.max(0, Math.min(100, scoreGlobal)),
      fauteuil_roulant: fauteuil,
      surdite,
      cecite,
      mobilite_reduite: mobilite,
      cognitif,
      osm_tags: osmTags,
      resume_ia: this.buildAccessibilitySummary(dto.place_name, scoreGlobal, confidence),
      confiance: confidence,
      sources_utilisees: ['M3ak BDD', 'OSM', 'Commentaires utilisateurs'],
    };
  }

  nearestNode(lat: number, lon: number): { node_id: number } {
    const nodeId = this.stableNodeId(lat, lon);
    this.nodeRegistry.set(nodeId, { lat, lon });
    return { node_id: nodeId };
  }

  async accessibleRouteFull(startNode: number, endNode: number) {
    const start = this.nodeRegistry.get(startNode);
    const end = this.nodeRegistry.get(endNode);
    if (!start || !end) {
      return {
        error:
          "start_node or end_node inconnu. Appelez /accessibility/nearest_node pour chaque point d'abord.",
      };
    }

    const path = await this.fetchOsrmWalkingPath(start, end);
    const finalPath = path ?? this.linearFallbackPath(start, end, 24);
    const distanceMeters = this.routeDistanceMeters(finalPath);
    const aiScore = this.aiAccessibilityScore(distanceMeters, finalPath.length);

    return {
      best_path: [startNode, endNode],
      coordinates: finalPath.map((p) => ({ lat: p.lat, lon: p.lon })),
      average_accessibility_score: aiScore,
    };
  }

  private stableNodeId(lat: number, lon: number): number {
    const latQ = Math.round((lat + 90.0) * 100000);
    const lonQ = Math.round((lon + 180.0) * 100000);
    return (latQ * 1000003 + lonQ * 9973) & 0x7fffffff;
  }

  private haversineMeters(lat1: number, lon1: number, lat2: number, lon2: number): number {
    const r = 6371000.0;
    const p1 = (lat1 * Math.PI) / 180.0;
    const p2 = (lat2 * Math.PI) / 180.0;
    const dp = ((lat2 - lat1) * Math.PI) / 180.0;
    const dl = ((lon2 - lon1) * Math.PI) / 180.0;
    const a =
      Math.sin(dp / 2) ** 2 +
      Math.cos(p1) * Math.cos(p2) * Math.sin(dl / 2) ** 2;
    return r * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  }

  private linearFallbackPath(
    start: { lat: number; lon: number },
    end: { lat: number; lon: number },
    segments = 24,
  ): Array<{ lat: number; lon: number }> {
    const points: Array<{ lat: number; lon: number }> = [];
    for (let i = 0; i <= segments; i++) {
      const t = i / segments;
      points.push({
        lat: start.lat + (end.lat - start.lat) * t,
        lon: start.lon + (end.lon - start.lon) * t,
      });
    }
    return points;
  }

  private routeDistanceMeters(points: Array<{ lat: number; lon: number }>): number {
    if (points.length < 2) return 0;
    let total = 0;
    for (let i = 1; i < points.length; i++) {
      total += this.haversineMeters(
        points[i - 1].lat,
        points[i - 1].lon,
        points[i].lat,
        points[i].lon,
      );
    }
    return total;
  }

  private aiAccessibilityScore(distanceMeters: number, segmentCount: number): number {
    const distanceScore = Math.max(0, Math.min(1, 1 - distanceMeters / 12000));
    const segmentScore = Math.max(
      0,
      Math.min(1, 1 - Math.max(0, segmentCount - 20) / 60),
    );
    const score = 0.7 * distanceScore + 0.3 * segmentScore;
    return Number(score.toFixed(4));
  }

  private async fetchOsrmWalkingPath(
    start: { lat: number; lon: number },
    end: { lat: number; lon: number },
  ): Promise<Array<{ lat: number; lon: number }> | null> {
    const osrmBase = (
      this.config.get<string>('OSRM_URL') ?? 'https://router.project-osrm.org'
    ).replace(/\/$/, '');
    const url = `${osrmBase}/route/v1/foot/${start.lon},${start.lat};${end.lon},${end.lat}?overview=full&geometries=geojson&steps=false`;
    try {
      const res = await fetch(url, { signal: AbortSignal.timeout(15000) });
      if (!res.ok) return null;
      const data = (await res.json()) as {
        code?: string;
        routes?: Array<{
          geometry?: { coordinates?: number[][] };
        }>;
      };
      if (data.code !== 'Ok' || !data.routes?.[0]?.geometry?.coordinates?.length) {
        return null;
      }
      const coords = data.routes[0].geometry.coordinates;
      return coords
        .filter((c) => Array.isArray(c) && c.length >= 2)
        .map((c) => ({ lon: Number(c[0]), lat: Number(c[1]) }));
    } catch {
      return null;
    }
  }

  private async fetchOsmAccessibility(
    lat: number,
    lon: number,
    radius = 80,
  ): Promise<Record<string, string>> {
    if (!Number.isFinite(lat) || !Number.isFinite(lon)) return {};
    const query = `[out:json][timeout:10];
(
  node(around:${radius},${lat},${lon});
  way(around:${radius},${lat},${lon});
);
out tags;`;
    const overpassUrl =
      this.config.get<string>('OVERPASS_URL') ??
      'https://overpass-api.de/api/interpreter';
    try {
      const response = await fetch(overpassUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: `data=${encodeURIComponent(query)}`,
        signal: AbortSignal.timeout(20000),
      });
      if (!response.ok) return {};
      const data = (await response.json()) as {
        elements?: Array<{ tags?: Record<string, string> }>;
      };
      const keywords = [
        'wheelchair',
        'ramp',
        'elevator',
        'lift',
        'tactile',
        'hearing',
        'braille',
        'blind',
        'accessible',
        'step',
        'kerb',
        'handrail',
        'disabled',
        'toilet',
        'pmr',
      ];
      const merged: Record<string, string> = {};
      for (const element of data.elements ?? []) {
        for (const [k, v] of Object.entries(element.tags ?? {})) {
          if (keywords.some((kw) => k.toLowerCase().includes(kw))) {
            merged[k] = v;
          }
        }
      }
      return merged;
    } catch {
      return {};
    }
  }

  private mergeAccessibilityData(dto: AnalyzePlaceDto, osmTags: Record<string, string>) {
    const m3ak = {
      wheelchair_access: Boolean(dto.wheelchair_access),
      elevator: Boolean(dto.elevator),
      braille: Boolean(dto.braille),
      audio_assistance: Boolean(dto.audio_assistance),
      accessible_toilets: Boolean(dto.accessible_toilets),
    };
    const osm = {
      wheelchair: osmTags.wheelchair ?? 'unknown',
      ramp:
        osmTags.ramp === 'yes' || osmTags['ramp:wheelchair'] === 'yes',
      step_free:
        osmTags.kerb === 'flush' || (osmTags.step_count ?? '1') === '0',
      hearing_loop: osmTags.hearing_loop === 'yes',
      tactile_paving: osmTags.tactile_paving === 'yes',
      braille_osm: osmTags['tactile_writing:braille'] === 'yes',
      elevator_osm: osmTags.elevator === 'yes' || osmTags.lift === 'yes',
      toilets_osm: osmTags['toilets:wheelchair'] === 'yes',
      has_osm_data: Object.keys(osmTags).length > 0,
    };
    return { m3ak, osm };
  }

  private computeFauteuilScore(merged: ReturnType<AccessibilityService['mergeAccessibilityData']>) {
    const score =
      (merged.m3ak.wheelchair_access ? 60 : 0) +
      (merged.m3ak.elevator ? 20 : 0) +
      (merged.osm.ramp ? 10 : 0) +
      (merged.osm.step_free ? 10 : 0);
    return this.makeHandicapScore(score, 'fauteuil roulant', ['M3ak BDD', 'OSM']);
  }

  private computeMobiliteReduiteScore(
    merged: ReturnType<AccessibilityService['mergeAccessibilityData']>,
  ) {
    const score =
      (merged.m3ak.wheelchair_access ? 40 : 0) +
      (merged.m3ak.elevator ? 30 : 0) +
      (merged.osm.step_free ? 20 : 0) +
      (merged.osm.ramp ? 10 : 0);
    return this.makeHandicapScore(score, 'mobilite reduite', ['M3ak BDD', 'OSM']);
  }

  private computeCeciteScore(merged: ReturnType<AccessibilityService['mergeAccessibilityData']>) {
    const score =
      (merged.m3ak.braille ? 50 : 0) +
      (merged.m3ak.audio_assistance ? 20 : 0) +
      (merged.osm.tactile_paving ? 30 : 0);
    return this.makeHandicapScore(score, 'cecite', ['M3ak BDD', 'OSM']);
  }

  private computeSurditeScore(merged: ReturnType<AccessibilityService['mergeAccessibilityData']>) {
    const score =
      (merged.m3ak.audio_assistance ? 60 : 0) +
      (merged.osm.hearing_loop ? 40 : 0);
    return this.makeHandicapScore(score, 'surdite', ['M3ak BDD', 'OSM']);
  }

  private computeCognitifScore(
    merged: ReturnType<AccessibilityService['mergeAccessibilityData']>,
    comments: string[],
  ) {
    const hasPositiveComment = comments.some((c) =>
      /(merci|calme|clair|facile|bien|accessible|aide)/i.test(c),
    );
    const score =
      (merged.m3ak.audio_assistance ? 30 : 0) +
      (merged.m3ak.braille ? 20 : 0) +
      (hasPositiveComment ? 20 : 0);
    return this.makeHandicapScore(score, 'cognitif', [
      'M3ak BDD',
      'Commentaires utilisateurs',
    ]);
  }

  private makeHandicapScore(scoreRaw: number, label: string, sources: string[]) {
    const score = Math.max(0, Math.min(100, Math.round(scoreRaw)));
    let niveau = 'Non adapte';
    if (score >= 80) niveau = 'Excellent';
    else if (score >= 60) niveau = 'Bon';
    else if (score >= 40) niveau = 'Partiel';
    return {
      score,
      niveau,
      details: [`Evaluation ${label}: score calcule a partir des donnees disponibles.`],
      sources,
    };
  }

  private computeConfidenceLabel(
    merged: ReturnType<AccessibilityService['mergeAccessibilityData']>,
  ): 'Elevee' | 'Moyenne' | 'Faible' {
    const positives = [
      merged.m3ak.wheelchair_access,
      merged.m3ak.elevator,
      merged.m3ak.braille,
      merged.m3ak.audio_assistance,
      merged.m3ak.accessible_toilets,
    ].filter(Boolean).length;
    if (positives >= 3) return 'Elevee';
    if (positives >= 1) return 'Moyenne';
    return 'Faible';
  }

  private buildAccessibilitySummary(placeName: string, score: number, confidence: string): string {
    if (score >= 80) {
      return `${placeName} presente un bon niveau d'accessibilite globale (confiance ${confidence.toLowerCase()}).`;
    }
    if (score >= 60) {
      return `${placeName} est partiellement accessible avec des points forts a confirmer sur place.`;
    }
    return `${placeName} montre des limites d'accessibilite, des adaptations restent necessaires.`;
  }
}
