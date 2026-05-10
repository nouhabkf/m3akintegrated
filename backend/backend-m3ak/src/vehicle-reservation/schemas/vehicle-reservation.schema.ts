import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Document, Types } from 'mongoose';

export type VehicleReservationDocument = VehicleReservation & Document;

@Schema({ timestamps: true, versionKey: false })
export class VehicleReservation {
  @ApiProperty({ description: 'ID utilisateur (handicapé qui réserve)' })
  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  userId: Types.ObjectId;

  @ApiProperty({ description: 'ID du véhicule' })
  @Prop({ type: Types.ObjectId, ref: 'Vehicle', required: true })
  vehicleId: Types.ObjectId;

  @ApiProperty({ description: 'Date de réservation' })
  @Prop({ type: Date, required: true })
  date: Date;

  @ApiProperty({ description: 'Heure de départ' })
  @Prop({ type: String, required: true })
  heure: string;

  @ApiPropertyOptional({ description: 'Lieu de départ' })
  @Prop({ type: String, default: null })
  lieuDepart: string | null;

  @ApiPropertyOptional({ description: 'Lieu de destination' })
  @Prop({ type: String, default: null })
  lieuDestination: string | null;

  @ApiPropertyOptional({ description: 'Besoins spécifiques' })
  @Prop({ type: String, default: null })
  besoinsSpecifiques: string | null;

  @ApiPropertyOptional({ description: 'QR Code' })
  @Prop({ type: String, default: null })
  qrCode: string | null;

  @ApiProperty({ description: 'Statut', default: 'EN_ATTENTE' })
  @Prop({ type: String, default: 'EN_ATTENTE' })
  statut: string;

  @ApiPropertyOptional({
    description:
      'Demande de transport liée (créée automatiquement pour le flux chauffeur /transport/available)',
  })
  @Prop({ type: Types.ObjectId, ref: 'TransportRequest' })
  transportId?: Types.ObjectId;

  @ApiPropertyOptional({ description: 'Durée du trajet en minutes (une fois terminé)' })
  @Prop({ type: Number, default: null })
  dureeTrajet: number | null;

  @ApiPropertyOptional({ description: 'Date et heure de fin du trajet (une fois terminé)' })
  @Prop({ type: Date, default: null })
  dateHeureFin: Date | null;

  @ApiPropertyOptional({ description: 'Date de création' })
  createdAt?: Date;

  @ApiProperty({ description: 'Date de dernière mise à jour' })
  updatedAt?: Date;
}

export const VehicleReservationSchema = SchemaFactory.createForClass(VehicleReservation);

VehicleReservationSchema.index({ userId: 1 });
VehicleReservationSchema.index({ vehicleId: 1 });
VehicleReservationSchema.index({ date: 1 });
