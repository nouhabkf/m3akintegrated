import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Document, Types } from 'mongoose';

export type HelpRequestDocument = HelpRequest & Document;

@Schema({ timestamps: true, versionKey: false })
export class HelpRequest {
  @ApiProperty({ description: 'ID utilisateur' })
  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  userId: Types.ObjectId;

  @ApiProperty({ description: 'Description de la demande' })
  @Prop({ type: String, required: true })
  description: string;

  @ApiProperty({ description: 'Latitude' })
  @Prop({ type: Number, required: true })
  latitude: number;

  @ApiProperty({ description: 'Longitude' })
  @Prop({ type: Number, required: true })
  longitude: number;

  @ApiProperty({ description: 'Statut', default: 'EN_ATTENTE' })
  @Prop({ type: String, default: 'EN_ATTENTE' })
  statut: string;

  @ApiPropertyOptional({
    description: "ID de l'utilisateur qui a accepté la demande",
    type: String,
  })
  @Prop({ type: Types.ObjectId, ref: 'User', default: null })
  acceptedBy: Types.ObjectId | null;

  @ApiPropertyOptional({
    description: "Nom affiché du bénévole (helper) après acceptation",
  })
  @Prop({ type: String, default: null })
  helperName: string | null;

  @ApiPropertyOptional({
    description: "Urgence estimée sur une échelle 1-5",
    default: 1,
  })
  @Prop({ type: Number, default: 1 })
  urgencyScore: number;

  /** Priorité métier (règles HelpPriorityService) : low | medium | high | critical */
  @ApiPropertyOptional({ description: 'Niveau de priorité calculé' })
  @Prop({ type: String, default: null })
  priority: string | null;

  @ApiPropertyOptional({ description: 'Score agrégé avant seuils' })
  @Prop({ type: Number, default: null })
  priorityScore: number | null;

  @ApiPropertyOptional({ description: 'Phrase de justification (FR)' })
  @Prop({ type: String, default: null })
  priorityReason: string | null;

  @ApiPropertyOptional({ description: 'Signaux ayant influencé le score', type: [String] })
  @Prop({ type: [String], default: [] })
  prioritySignals: string[];

  /** Type de besoin (flux inclusif, optionnel). */
  @ApiPropertyOptional({ description: 'Type de besoin' })
  @Prop({ type: String, default: null })
  helpType: string | null;

  /** Mode de saisie côté client (texte, voix, raccourci volume, etc.). */
  @ApiPropertyOptional({ description: 'Mode de saisie' })
  @Prop({ type: String, default: null })
  inputMode: string | null;

  /** Profil déclaré du demandeur. */
  @ApiPropertyOptional({ description: 'Profil demandeur' })
  @Prop({ type: String, default: null })
  requesterProfile: string | null;

  @ApiPropertyOptional({ description: 'Besoin de consignes audio' })
  @Prop({ type: Boolean, default: null })
  needsAudioGuidance: boolean | null;

  @ApiPropertyOptional({ description: 'Besoin de repères visuels' })
  @Prop({ type: Boolean, default: null })
  needsVisualSupport: boolean | null;

  @ApiPropertyOptional({ description: 'Besoin d’aide physique' })
  @Prop({ type: Boolean, default: null })
  needsPhysicalAssistance: boolean | null;

  @ApiPropertyOptional({ description: 'Langage simple' })
  @Prop({ type: Boolean, default: null })
  needsSimpleLanguage: boolean | null;

  @ApiPropertyOptional({ description: 'Demande pour une autre personne' })
  @Prop({ type: Boolean, default: null })
  isForAnotherPerson: boolean | null;

  @ApiPropertyOptional({ description: 'Clé de message prédéfini' })
  @Prop({ type: String, default: null })
  presetMessageKey: string | null;

  @ApiProperty({ description: 'Date de création' })
  createdAt?: Date;
}

export const HelpRequestSchema = SchemaFactory.createForClass(HelpRequest);
