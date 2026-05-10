import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Document, Types } from 'mongoose';

export type LieuReservationDocument = LieuReservation & Document;

@Schema({ timestamps: true, versionKey: false })
export class LieuReservation {
  @ApiProperty({ description: 'ID utilisateur' })
  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  userId: Types.ObjectId;

  @ApiProperty({ description: 'ID du lieu' })
  @Prop({ type: Types.ObjectId, ref: 'Lieu', required: true })
  lieuId: Types.ObjectId;

  @ApiProperty({ description: 'Date de réservation' })
  @Prop({ type: Date, required: true })
  date: Date;

  @ApiProperty({ description: 'Heure' })
  @Prop({ type: String, required: true })
  heure: string;

  @ApiPropertyOptional({ description: 'Besoins spécifiques' })
  @Prop({ type: String, default: null })
  besoinsSpecifiques: string | null;

  @ApiPropertyOptional({ description: 'QR Code' })
  @Prop({ type: String, default: null })
  qrCode: string | null;

  @ApiProperty({ description: 'Statut', default: 'EN_ATTENTE' })
  @Prop({ type: String, default: 'EN_ATTENTE' })
  statut: string;

  @ApiProperty({ description: 'Date de création' })
  createdAt?: Date;
}

export const LieuReservationSchema = SchemaFactory.createForClass(LieuReservation);
