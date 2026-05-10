import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Document, Types } from 'mongoose';

export type SosAlertDocument = SosAlert & Document;

@Schema({ timestamps: true, versionKey: false })
export class SosAlert {
  @ApiProperty({ description: 'ID utilisateur' })
  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  userId: Types.ObjectId;

  @ApiProperty({ description: 'Latitude' })
  @Prop({ type: Number, required: true })
  latitude: number;

  @ApiProperty({ description: 'Longitude' })
  @Prop({ type: Number, required: true })
  longitude: number;

  @ApiProperty({ description: 'Statut', default: 'ENVOYEE' })
  @Prop({ type: String, default: 'ENVOYEE' })
  statut: string;

  @ApiPropertyOptional({ description: 'Score stress vocal 0–100' })
  @Prop({ type: Number, required: false })
  voiceScore?: number;

  @ApiPropertyOptional({ description: 'Libellé technique (stress, panic…)' })
  @Prop({ type: String, required: false })
  voiceLabel?: string;

  @ApiPropertyOptional({ description: 'Libellé FR affiché' })
  @Prop({ type: String, required: false })
  voiceLabelFr?: string;

  @ApiPropertyOptional({ description: 'Origine: VOICE_AUTO, MANUAL, MEDICAL…' })
  @Prop({ type: String, required: false })
  alertSource?: string;

  @ApiPropertyOptional({ description: 'Snapshot handicap bénéficiaire' })
  @Prop({ type: String, required: false })
  beneficiaryTypeHandicap?: string;

  @ApiPropertyOptional({ description: 'Snapshot besoins bénéficiaire' })
  @Prop({ type: String, required: false })
  beneficiaryBesoinSpecifique?: string;

  @ApiProperty({ description: 'Date de création' })
  createdAt?: Date;
}

export const SosAlertSchema = SchemaFactory.createForClass(SosAlert);

SosAlertSchema.index({ latitude: 1, longitude: 1 });
