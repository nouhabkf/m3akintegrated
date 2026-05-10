import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { ApiProperty } from '@nestjs/swagger';
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

  /** Utilisateur qui a cliqué « M’y rendre » (secours en route). */
  @ApiProperty({ description: 'ID du répondant', required: false })
  @Prop({ type: Types.ObjectId, ref: 'User', required: false })
  responderUserId?: Types.ObjectId;

  @ApiProperty({ description: 'Date de création' })
  createdAt?: Date;
}

export const SosAlertSchema = SchemaFactory.createForClass(SosAlert);

// Index géospatial pour recherche
SosAlertSchema.index({ latitude: 1, longitude: 1 });
