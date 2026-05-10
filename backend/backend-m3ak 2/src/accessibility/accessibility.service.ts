import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

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
}
