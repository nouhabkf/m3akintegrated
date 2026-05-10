import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Document, Types } from 'mongoose';

export type VehicleReservationReviewDocument = VehicleReservationReview & Document;

@Schema({ timestamps: true, versionKey: false })
export class VehicleReservationReview {
  @ApiProperty({ description: 'ID de la réservation de véhicule' })
  @Prop({ type: Types.ObjectId, ref: 'VehicleReservation', required: true, unique: true })
  vehicleReservationId: Types.ObjectId;

  @ApiProperty({ description: 'ID de l\'utilisateur auteur (bénéficiaire du trajet)' })
  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  userId: Types.ObjectId;

  @ApiProperty({ description: 'Note de 1 à 5' })
  @Prop({ type: Number, required: true, min: 1, max: 5 })
  note: number;

  @ApiPropertyOptional({ description: 'Commentaire' })
  @Prop({ type: String, default: null })
  comment: string | null;

  @ApiPropertyOptional({ description: 'ID du véhicule évalué (optionnel)' })
  @Prop({ type: Types.ObjectId, ref: 'Vehicle', default: null })
  vehicleId: Types.ObjectId | null;

  @ApiPropertyOptional({ description: 'ID du chauffeur évalué (optionnel)' })
  @Prop({ type: Types.ObjectId, ref: 'User', default: null })
  driverId: Types.ObjectId | null;

  @ApiPropertyOptional({ description: 'Date de création' })
  createdAt?: Date;
}

export const VehicleReservationReviewSchema = SchemaFactory.createForClass(VehicleReservationReview);

/** Index utilisateur (vehicleReservationId déjà unique via @Prop unique: true) */
VehicleReservationReviewSchema.index({ userId: 1 });
