import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { ApiProperty } from '@nestjs/swagger';
import { Document, Types } from 'mongoose';

export type PostDocument = Post & Document;

@Schema({ timestamps: true, versionKey: false })
export class Post {
  @ApiProperty({ description: 'ID utilisateur' })
  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  userId: Types.ObjectId;

  @ApiProperty({ description: 'Contenu' })
  @Prop({ type: String, required: true })
  contenu: string;

  @ApiProperty({ description: 'Type de post' })
  @Prop({ type: String, required: true })
  type: string;

  @ApiProperty({
    description: 'Type de flux communautaire',
    required: false,
    enum: ['post', 'live', 'replay'],
    default: 'post',
  })
  @Prop({ type: String, enum: ['post', 'live', 'replay'], default: 'post' })
  streamType: string;

  @ApiProperty({
    description: 'Indique si le post représente une session live',
    required: false,
    default: false,
  })
  @Prop({ type: Boolean, default: false })
  isLive: boolean;

  @ApiProperty({
    description: 'Statut live (active/ended)',
    required: false,
    enum: ['active', 'ended'],
    default: 'ended',
  })
  @Prop({ type: String, enum: ['active', 'ended'], default: 'ended' })
  liveStatus: string;

  @ApiProperty({
    description: 'Nombre de spectateurs live',
    required: false,
    default: 0,
  })
  @Prop({ type: Number, default: 0, min: 0 })
  viewersCount: number;

  @ApiProperty({
    description: 'URL vidéo live/replay (MVP optionnel)',
    required: false,
  })
  @Prop({ type: String, default: null })
  liveVideoUrl?: string | null;

  @ApiProperty({ description: 'Chemins des images (dossier uploads/)', type: [String] })
  @Prop({ type: [String], default: [] })
  images: string[];

  /** Géolocalisation optionnelle (obstacle / accessibilité). */
  @ApiProperty({ description: 'Latitude (signalement lieu)', required: false })
  @Prop({ type: Number, required: false })
  latitude?: number;

  @ApiProperty({ description: 'Longitude', required: false })
  @Prop({ type: Number, required: false })
  longitude?: number;

  /** Niveau de danger : si `critical` + coords → corrélation alerte SOS zone Aide. */
  @ApiProperty({ description: 'Niveau de danger du signalement', required: false })
  @Prop({ type: String, default: 'none' })
  dangerLevel: string;

  /** Validation communautaire : « l’obstacle est-il toujours là ? » */
  @ApiProperty({ description: 'Votes « oui » (toujours présent)', required: false })
  @Prop({ type: Number, default: 0 })
  validationYes: number;

  @ApiProperty({ description: 'Votes « non »', required: false })
  @Prop({ type: Number, default: 0 })
  validationNo: number;

  @ApiProperty({ description: 'Date de création' })
  createdAt?: Date;

  @ApiProperty({ description: 'Lieu détecté dans le post (IA)', required: false })
  @Prop({ type: Boolean, default: false })
  hasPlace?: boolean;

  @ApiProperty({ description: 'Texte lieu extrait', required: false })
  @Prop({ type: String, default: null })
  placeText?: string | null;

  @ApiProperty({ description: 'Catégorie extraction IA', required: false })
  @Prop({ type: String, default: null })
  placeCategory?: string | null;

  @ApiProperty({ description: 'Confiance IA [0..1]', required: false })
  @Prop({ type: Number, default: null })
  placeConfidence?: number | null;

  @ApiProperty({ description: 'Niveau de risque (safe/caution/danger)', required: false })
  @Prop({ type: String, default: 'safe' })
  riskLevel?: string;

  @ApiProperty({ description: 'Obstacle présent', required: false })
  @Prop({ type: Boolean, default: false })
  obstaclePresent?: boolean;

  @ApiProperty({ description: 'Résumé IA', required: false })
  @Prop({ type: String, default: null })
  aiSummary?: string | null;

  @ApiProperty({ description: 'Raison de détection IA', required: false, type: [String] })
  @Prop({ type: [String], default: [] })
  reasonCodes?: string[];

  @ApiProperty({ description: 'Statut validation pour publication lieu', required: false })
  @Prop({ type: String, default: 'none' })
  placeVerificationStatus?: string;

  @ApiProperty({ description: 'Lieu lié', required: false })
  @Prop({ type: Types.ObjectId, ref: 'Lieu', required: false, default: null })
  linkedLieuId?: Types.ObjectId | null;

  /** Remerciements (« Merci ») — remplace la logique « Like ». */
  @ApiProperty({ description: 'Nombre de Merci', required: false })
  @Prop({ type: Number, default: 0 })
  merciCount: number;

  @ApiProperty({ description: 'Utilisateurs ayant cliqué Merci', required: false })
  @Prop({ type: [{ type: Types.ObjectId, ref: 'User' }], default: [] })
  merciUserIds: Types.ObjectId[];

  /** Un vote par utilisateur pour la validation obstacle. */
  @ApiProperty({ description: 'IDs ayant déjà voté sur la présence obstacle', required: false })
  @Prop({ type: [{ type: Types.ObjectId, ref: 'User' }], default: [] })
  obstacleVoterIds: Types.ObjectId[];

  /** Nature du post (flux inclusif, optionnel). */
  @Prop({ type: String, default: null })
  postNature?: string | null;

  /** Public cible déclaré. */
  @Prop({ type: String, default: null })
  targetAudience?: string | null;

  /** Mode de saisie côté client. */
  @Prop({ type: String, default: null })
  inputMode?: string | null;

  @Prop({ type: Boolean, default: null })
  isForAnotherPerson?: boolean | null;

  @Prop({ type: Boolean, default: null })
  needsAudioGuidance?: boolean | null;

  @Prop({ type: Boolean, default: null })
  needsVisualSupport?: boolean | null;

  @Prop({ type: Boolean, default: null })
  needsPhysicalAssistance?: boolean | null;

  @Prop({ type: Boolean, default: null })
  needsSimpleLanguage?: boolean | null;

  /** none | approximate | precise */
  @Prop({ type: String, default: null })
  locationSharingMode?: string | null;
}

export const PostSchema = SchemaFactory.createForClass(Post);
