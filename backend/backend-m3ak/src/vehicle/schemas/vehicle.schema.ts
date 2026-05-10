import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Document, Schema as MongooseSchema } from 'mongoose';
import { VehicleStatut } from '../enums/vehicle-statut.enum';

export type VehicleDocument = Vehicle & Document;

@Schema({ _id: false })
export class Accessibilite {
  @ApiPropertyOptional({ description: 'Coffre vaste', default: false })
  @Prop({ type: Boolean, default: false })
  coffreVaste: boolean;

  @ApiPropertyOptional({ description: 'Rampe d\'accès', default: false })
  @Prop({ type: Boolean, default: false })
  rampeAcces: boolean;

  @ApiPropertyOptional({ description: 'Siège pivotant', default: false })
  @Prop({ type: Boolean, default: false })
  siegePivotant: boolean;

  @ApiPropertyOptional({ description: 'Climatisation', default: false })
  @Prop({ type: Boolean, default: false })
  climatisation: boolean;

  @ApiPropertyOptional({ description: 'Animal accepté', default: false })
  @Prop({ type: Boolean, default: false })
  animalAccepte: boolean;
}

export const AccessibiliteSchema = SchemaFactory.createForClass(Accessibilite);

@Schema({ timestamps: true, versionKey: false })
export class Vehicle {
  @ApiProperty({ description: 'ID du propriétaire (User)' })
  @Prop({ type: MongooseSchema.Types.ObjectId, ref: 'User', required: true })
  ownerId: MongooseSchema.Types.ObjectId;

  @ApiProperty({ description: 'Marque du véhicule', example: 'Toyota' })
  @Prop({ type: String, required: true })
  marque: string;

  @ApiProperty({ description: 'Modèle du véhicule', example: 'Yaris' })
  @Prop({ type: String, required: true })
  modele: string;

  @ApiProperty({ description: 'Immatriculation', example: '123-456-78' })
  @Prop({ type: String, required: true })
  immatriculation: string;

  @ApiPropertyOptional({ description: 'Caractéristiques d\'accessibilité' })
  @Prop({ type: AccessibiliteSchema, default: () => ({}) })
  accessibilite: Accessibilite;

  @ApiPropertyOptional({ description: 'URLs des photos', type: [String] })
  @Prop({ type: [String], default: [] })
  photos: string[];

  @ApiProperty({ enum: VehicleStatut, description: 'Statut du véhicule' })
  @Prop({ type: String, enum: VehicleStatut, default: VehicleStatut.EN_ATTENTE })
  statut: VehicleStatut;

  @ApiPropertyOptional({ description: 'Date de création' })
  createdAt?: Date;

  @ApiPropertyOptional({ description: 'Date de dernière mise à jour' })
  updatedAt?: Date;
}

export const VehicleSchema = SchemaFactory.createForClass(Vehicle);

VehicleSchema.index({ ownerId: 1 });
VehicleSchema.index({ statut: 1 });
