import { Injectable } from '@nestjs/common';
import { randomUUID } from 'crypto';
import sharp from 'sharp';

type SessionState = {
  createdAt: number;
  lastSeenAt: number;
  clientHint?: string;
};

export type GuidanceResponse = {
  sessionId: string;
  instruction: string; // phrase courte (pour TTS)
  okCapture: boolean;
  confidence: number; // 0..1
  metrics: {
    focus: number;
    focusOk: boolean;
    centerX: number; // 0..1
    edgeEnergy: number;
  };
};

@Injectable()
export class M3akGuidanceService {
  private readonly sessions = new Map<string, SessionState>();

  createSession(clientHint?: string) {
    const sessionId = randomUUID();
    const now = Date.now();
    this.sessions.set(sessionId, {
      createdAt: now,
      lastSeenAt: now,
      clientHint,
    });
    return { sessionId };
  }

  async analyzeFrame(sessionId: string, imageBase64: string): Promise<GuidanceResponse> {
    const now = Date.now();
    const s = this.sessions.get(sessionId);
    if (s) s.lastSeenAt = now;

    const buf = Buffer.from(imageBase64, 'base64');

    // Pré-traitement léger (rapide) pour mesures simples
    const { data, info } = await sharp(buf)
      .rotate()
      .resize(96, 96, { fit: 'inside' })
      .greyscale()
      .raw()
      .toBuffer({ resolveWithObject: true });

    const w = info.width;
    const h = info.height;

    // Focus (approx): énergie de gradient (plus c’est net, plus c’est grand)
    let gradSum = 0;
    for (let y = 0; y < h - 1; y++) {
      for (let x = 0; x < w - 1; x++) {
        const i = y * w + x;
        const p = data[i] ?? 0;
        const px = data[i + 1] ?? 0;
        const py = data[i + w] ?? 0;
        gradSum += Math.abs(p - px) + Math.abs(p - py);
      }
    }

    const focus = gradSum / (w * h);
    const focusOk = focus > 9.5; // seuil empirique (à ajuster)

    // Centre de "détails" (centre de masse des gradients)
    let wxSum = 0;
    let wSum = 0;
    for (let y = 0; y < h - 1; y++) {
      for (let x = 0; x < w - 1; x++) {
        const i = y * w + x;
        const p = data[i] ?? 0;
        const px = data[i + 1] ?? 0;
        const py = data[i + w] ?? 0;
        const g = Math.abs(p - px) + Math.abs(p - py);
        wSum += g;
        wxSum += g * x;
      }
    }

    const centerX = wSum > 0 ? wxSum / wSum / Math.max(1, w - 1) : 0.5;
    const edgeEnergy = wSum / (w * h);

    const centerDelta = centerX - 0.5;
    const centeredOk = Math.abs(centerDelta) < 0.08;

    // Heuristique guidance (fallback "offline")
    let instruction = 'Reste stable.';
    let okCapture = false;
    let confidence = 0.55;

    if (!focusOk) {
      instruction = "C'est flou. Stabilise et rapproche doucement.";
      confidence = 0.8;
    } else if (edgeEnergy < 6.0) {
      instruction = 'Avance doucement vers la cible.';
      confidence = 0.65;
    } else if (!centeredOk) {
      instruction =
        centerDelta < 0
          ? 'Tourne un peu à gauche.'
          : 'Tourne un peu à droite.';
      confidence = 0.75;
    } else {
      instruction = 'Parfait. Ne bouge pas.';
      okCapture = true;
      confidence = 0.9;
    }

    return {
      sessionId,
      instruction,
      okCapture,
      confidence,
      metrics: {
        focus,
        focusOk,
        centerX,
        edgeEnergy,
      },
    };
  }
}

