import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Document, Types } from 'mongoose';
import { TransportType } from '../enums/transport-type.enum';

export type TransportRequestDocument = TransportRequest & Document;

@Schema({ timestamps: true, versionKey: false })
export class TransportRequest {
  @ApiProperty({ description: 'ID du demandeur' })
  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  demandeurId: Types.ObjectId;

  @ApiPropertyOptional({ description: 'ID de l\'accompagnant assigné' })
  @Prop({ type: Types.ObjectId, ref: 'User', default: null })
  accompagnantId: Types.ObjectId | null;

  @ApiProperty({ enum: TransportType, description: 'Type de transport' })
  @Prop({ type: String, enum: TransportType, required: true })
  typeTransport: TransportType;

  @ApiProperty({ description: 'Adresse de départ' })
  @Prop({ type: String, required: true })
  depart: string;

  @ApiProperty({ description: 'Adresse de destination' })
  @Prop({ type: String, required: true })
  destination: string;

  @ApiProperty({ description: 'Latitude départ' })
  @Prop({ type: Number, required: true })
  latitudeDepart: number;

  @ApiProperty({ description: 'Longitude départ' })
  @Prop({ type: Number, required: true })
  longitudeDepart: number;

  @ApiProperty({ description: 'Latitude arrivée' })
  @Prop({ type: Number, required: true })
  latitudeArrivee: number;

  @ApiProperty({ description: 'Longitude arrivée' })
  @Prop({ type: Number, required: true })
  longitudeArrivee: number;

  @ApiProperty({ description: 'Date et heure souhaitées' })
  @Prop({ type: Date, required: true })
  dateHeure: Date;

  @ApiProperty({ description: 'Statut', default: 'EN_ATTENTE' })
  @Prop({ type: String, default: 'EN_ATTENTE' })
  statut: string;

  @ApiPropertyOptional({ description: 'Score de matching' })
  @Prop({ type: Number, default: null })
  scoreMatching: number | null;

  @ApiProperty({ description: 'Date de création' })
  createdAt?: Date;
}

export const TransportRequestSchema = SchemaFactory.createForClass(TransportRequest);
