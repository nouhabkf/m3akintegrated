import { Injectable, Logger } from '@nestjs/common';

/**
 * Fenêtre glissante simple en mémoire (MVP). En production, préférer Redis / API Gateway.
 */
@Injectable()
export class TransportShareRateLimitService {
  private readonly logger = new Logger(TransportShareRateLimitService.name);
  private readonly hits = new Map<string, number[]>();

  /** @returns true si la requête est autorisée */
  tryConsume(key: string, maxPerWindow: number, windowMs: number): boolean {
    const now = Date.now();
    const windowStart = now - windowMs;
    const prev = this.hits.get(key) ?? [];
    const kept = prev.filter((t) => t > windowStart);
    if (kept.length >= maxPerWindow) {
      this.logger.warn(`Rate limit transport partage : ${key}`);
      return false;
    }
    kept.push(now);
    this.hits.set(key, kept);
    if (this.hits.size > 20_000) {
      this.hits.clear();
    }
    return true;
  }
}
