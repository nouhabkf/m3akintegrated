import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import * as tf from '@tensorflow/tfjs';
import * as handPoseDetection from '@tensorflow-models/hand-pose-detection';
import * as blazeface from '@tensorflow-models/blazeface';
import sharp from 'sharp';
import type { Hand, Keypoint } from '@tensorflow-models/hand-pose-detection';
import type { NormalizedFace } from '@tensorflow-models/blazeface';

/** Réponses JSON alignées sur FastAPI / l’app Flutter. */
export type SignExplainPayload = {
  detected_word: string | null;
  explanation: string;
  raised_fingers: string[];
  raised_fingers_count: number;
  confidence: number;
  landmarks: { x: number; y: number; z: number }[];
};

@Injectable()
export class M3akVisionService implements OnModuleInit {
  private readonly logger = new Logger(M3akVisionService.name);
  private handDetector: handPoseDetection.HandDetector | null = null;
  private faceModel: blazeface.BlazeFaceModel | null = null;
  private initError: string | null = null;

  async onModuleInit() {
    try {
      await this.loadModels();
    } catch (e) {
      this.initError = e instanceof Error ? e.message : String(e);
      this.logger.warn(`Modèles IA M3AK non chargés: ${this.initError}`);
    }
  }

  private async loadModels() {
    await tf.ready();
    this.logger.log('Chargement MediaPipe Hands (TFJS)…');
    this.handDetector = await handPoseDetection.createDetector(
      handPoseDetection.SupportedModels.MediaPipeHands,
      {
        runtime: 'tfjs',
        modelType: 'full',
        maxHands: 1,
      },
    );
    this.logger.log('Chargement BlazeFace…');
    this.faceModel = await blazeface.load({ maxFaces: 1 });
    this.logger.log('Modèles M3AK vision prêts.');
  }

  getHealth() {
    return {
      message: 'API OK',
      status: 'online',
      sign_ai_available: this.handDetector !== null,
      face_ai_available: this.faceModel !== null,
      sign_ai_import_error: this.initError,
      face_ai_import_error: this.initError,
    };
  }

  assertSignAi() {
    if (!this.handDetector) {
      throw new Error(
        this.initError ??
          'Module IA gestes indisponible (échec chargement TensorFlow.js).',
      );
    }
  }

  assertFaceAi() {
    if (!this.faceModel) {
      throw new Error(
        this.initError ??
          'Module IA visage indisponible (échec chargement BlazeFace).',
      );
    }
  }

  async explainSign(buffer: Buffer): Promise<SignExplainPayload> {
    this.assertSignAi();
    const { tensor, width, height } = await this.bufferToTensor3d(buffer);
    try {
      const hands = await this.handDetector!.estimateHands(tensor, {
        flipHorizontal: false,
        staticImageMode: true,
      });
      if (!hands.length) {
        return {
          detected_word: null,
          explanation:
            'Aucune main detectee. Essayez avec plus de lumiere.',
          raised_fingers: [],
          raised_fingers_count: 0,
          confidence: 0,
          landmarks: [],
        };
      }
      return this.handToResponse(hands[0], width, height);
    } finally {
      tensor.dispose();
    }
  }

  private handToResponse(hand: Hand, width: number, height: number): SignExplainPayload {
    const kp = hand.keypoints;
    const handedness = hand.handedness ?? 'Right';
    const doigts = this.detectFingers(kp, handedness);
    const mot = this.recognizeSigne(doigts, doigts.length);
    const confidence = mot ? 0.85 : 0.4;
    const landmarks = kp.map((p) => ({
      x: p.x / width,
      y: p.y / height,
      z: p.z ?? 0,
    }));
    return {
      detected_word: mot,
      explanation: this.expliquer(mot),
      raised_fingers: doigts,
      raised_fingers_count: doigts.length,
      confidence,
      landmarks,
    };
  }

  private detectFingers(kp: Keypoint[], handedness: string): string[] {
    const doigts: string[] = [];
    const isRight = handedness === 'Right';
    const tip = (i: number) => kp[i];

    const t4 = tip(4);
    const t3 = tip(3);
    if (t4 && t3) {
      if (isRight ? t4.x < t3.x : t4.x > t3.x) doigts.push('pouce');
    }
    if (tip(8) && tip(6) && tip(8).y < tip(6).y) doigts.push('index');
    if (tip(12) && tip(10) && tip(12).y < tip(10).y) doigts.push('majeur');
    if (tip(16) && tip(14) && tip(16).y < tip(14).y) doigts.push('annulaire');
    if (tip(20) && tip(18) && tip(20).y < tip(18).y) doigts.push('auriculaire');
    return doigts;
  }

  private recognizeSigne(doigts: string[], nb: number): string | null {
    if (nb === 0) return 'POING';
    if (nb === 5) return 'BONJOUR';
    if (nb === 1) {
      if (doigts.includes('pouce')) return 'OUI';
      if (doigts.includes('index')) return 'DIRE';
      if (doigts.includes('majeur')) return 'INSULTE';
      if (doigts.includes('auriculaire')) return 'APPELER';
    }
    if (nb === 2) {
      if (doigts.includes('index') && doigts.includes('majeur')) return 'VICTOIRE';
      if (doigts.includes('pouce') && doigts.includes('index')) return 'PISTOLET';
      if (doigts.includes('pouce') && doigts.includes('auriculaire')) return 'TELEPHONE';
      if (doigts.includes('index') && doigts.includes('auriculaire')) return 'ROCK';
    }
    if (nb === 3) {
      if (doigts.includes('pouce') && doigts.includes('index') && doigts.includes('majeur'))
        return 'TROIS';
      if (doigts.includes('index') && doigts.includes('majeur') && doigts.includes('annulaire'))
        return 'W';
    }
    if (nb === 4) return 'QUATRE';
    return null;
  }

  private expliquer(mot: string | null): string {
    if (!mot) {
      return 'Aucun signe reconnu. Montrez la main entiere dans le cadre.';
    }
    const explanations: Record<string, string> = {
      POING: 'Poing ferme. Peut servir a indiquer un arret ou une position neutre.',
      BONJOUR: 'Main ouverte. Ce signe est interprete comme une salutation (bonjour).',
      OUI: 'Pouce leve. Ce geste signifie oui/validation.',
      DIRE: 'Index leve. Peut etre utilise pour indiquer/exprimer une information.',
      INSULTE: 'Majeur leve. Geste impoli a eviter.',
      APPELER: "Auriculaire leve. Peut indiquer l'action d'appeler.",
      VICTOIRE: 'Index + majeur leves. Signe de victoire.',
      PISTOLET: 'Pouce + index leves. Forme de geste type pistolet.',
      TELEPHONE: 'Pouce + auriculaire leves. Geste classique du telephone.',
      ROCK: 'Index + auriculaire leves. Signe souvent associe a rock.',
      TROIS: 'Trois doigts leves (pouce, index, majeur).',
      W: "Trois doigts leves (index, majeur, annulaire), proche d'un W.",
      QUATRE: 'Quatre doigts leves.',
    };
    return explanations[mot] ?? 'Signe reconnu.';
  }

  private async bufferToTensor3d(buffer: Buffer): Promise<{
    tensor: tf.Tensor3D;
    width: number;
    height: number;
  }> {
    const { data, info } = await sharp(buffer)
      .rotate()
      .removeAlpha()
      .raw()
      .toBuffer({ resolveWithObject: true });

    if (info.channels !== 3) {
      throw new Error('Image doit être RGB (3 canaux).');
    }
    const height = info.height;
    const width = info.width;
    const tensor = tf.tensor3d(new Uint8Array(data), [height, width, 3]);
    return { tensor, width, height };
  }

  async detectFace(buffer: Buffer) {
    this.assertFaceAi();
    const { tensor, width, height } = await this.bufferToTensor3d(buffer);
    try {
      const faces = await this.faceModel!.estimateFaces(tensor, false, false, true);
      if (!faces.length) {
        return { face_detected: false };
      }
      const face = faces[0];
      const box = this.faceBoxPixels(face, width, height);
      const prob = await this.readProbability(face);
      return {
        face_detected: true,
        confidence: prob,
        bounding_box: box,
      };
    } finally {
      tensor.dispose();
    }
  }

  private async readProbability(face: NormalizedFace): Promise<number> {
    const p = face.probability;
    if (typeof p === 'number') return p;
    if (p && 'data' in p) {
      const t = p as tf.Tensor1D;
      const d = await t.data();
      const v = d[0] ?? 0.9;
      t.dispose();
      return v;
    }
    return 0.9;
  }

  /** BlazeFace peut renvoyer coords pixels ou normalisées selon version ; on normalise vers entiers pixels. */
  private faceBoxPixels(face: NormalizedFace, imgW: number, imgH: number): number[] {
    const tl = face.topLeft as [number, number];
    const br = face.bottomRight as [number, number];
    let x1 = tl[0];
    let y1 = tl[1];
    let x2 = br[0];
    let y2 = br[1];
    const maxCoord = Math.max(x1, y1, x2, y2);
    if (maxCoord <= 1.5) {
      x1 *= imgW;
      x2 *= imgW;
      y1 *= imgH;
      y2 *= imgH;
    }
    const left = Math.max(0, Math.floor(Math.min(x1, x2)));
    const top = Math.max(0, Math.floor(Math.min(y1, y2)));
    const w = Math.max(1, Math.floor(Math.abs(x2 - x1)));
    const h = Math.max(1, Math.floor(Math.abs(y2 - y1)));
    return [left, top, w, h];
  }

  async encodeFace(buffer: Buffer) {
    this.assertFaceAi();
    const { tensor, width, height } = await this.bufferToTensor3d(buffer);
    try {
      const faces = await this.faceModel!.estimateFaces(tensor, false, false, true);
      if (!faces.length) {
        return { success: false, error: 'Aucun visage détecté' };
      }
      const face = faces[0];
      const [left, top, bw, bh] = this.faceBoxPixels(face, width, height);
      const embedding = await this.embeddingFromCrop(buffer, left, top, bw, bh);
      return { success: true, embedding };
    } finally {
      tensor.dispose();
    }
  }

  /** Vecteur 384 flottants (comme l’ancien FastAPI mesh simplifié). */
  private async embeddingFromCrop(
    buffer: Buffer,
    left: number,
    top: number,
    bw: number,
    bh: number,
  ): Promise<number[]> {
    const meta = await sharp(buffer).metadata();
    const iw = meta.width ?? bw + left;
    const ih = meta.height ?? bh + top;
    const l = Math.max(0, Math.min(left, Math.max(0, iw - 2)));
    const t0 = Math.max(0, Math.min(top, Math.max(0, ih - 2)));
    const w = Math.max(1, Math.min(bw, iw - l));
    const h = Math.max(1, Math.min(bh, ih - t0));
    const raw = await sharp(buffer)
      .extract({
        left: l,
        top: t0,
        width: w,
        height: h,
      })
      .greyscale()
      .resize(16, 16, { fit: 'fill' })
      .raw()
      .toBuffer();

    const vec: number[] = [];
    for (let i = 0; i < raw.length; i++) {
      vec.push(raw[i]! / 255);
    }
    while (vec.length < 384) vec.push(0);
    return vec.slice(0, 384);
  }

  async detectEmotion(buffer: Buffer) {
    this.assertFaceAi();
    const { tensor, width, height } = await this.bufferToTensor3d(buffer);
    try {
      const faces = await this.faceModel!.estimateFaces(tensor, false, false, true);
      if (!faces.length) {
        return { emotion: 'neutral', confidence: 0 };
      }
      const face = faces[0];
      const landmarks = face.landmarks as number[][] | undefined;
      return this.emotionHeuristic(landmarks, width, height);
    } finally {
      tensor.dispose();
    }
  }

  private emotionHeuristic(
    landmarks: number[][] | undefined,
    imgW: number,
    imgH: number,
  ) {
    if (!landmarks || landmarks.length < 4) {
      return { emotion: 'neutral', confidence: 0.65 };
    }
    const toPx = (x: number, y: number) =>
      Math.max(x, y) <= 1.5 ? [x * imgW, y * imgH] : [x, y];
    const re = toPx(landmarks[0]![0]!, landmarks[0]![1]!);
    const le = toPx(landmarks[1]![0]!, landmarks[1]![1]!);
    const mouth = toPx(landmarks[3]![0]!, landmarks[3]![1]!);
    const eyeY = (re[1]! + le[1]!) / 2;
    const mouthY = mouth[1]!;
    const eyeDist = Math.abs(le[0]! - re[0]!) || 1;
    const mouthW = eyeDist;
    const vert = (mouthY - eyeY) / imgH;
    const horiz = mouthW / imgW;
    if (horiz > 0.12 && vert < 0.03) {
      return { emotion: 'happy', confidence: 0.74 };
    }
    if (vert > 0.04) {
      return { emotion: 'sad', confidence: 0.63 };
    }
    return { emotion: 'neutral', confidence: 0.69 };
  }
}
