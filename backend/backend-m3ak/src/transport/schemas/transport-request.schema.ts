import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Document, Types } from 'mongoose';
import { TransportType } from '../enums/transport-type.enum';
import { TransportStatut } from '../enums/transport-statut.enum';
import { MotifTrajet } from '../enums/motif-trajet.enum';

export type TransportRequestDocument = TransportRequest & Document;

@Schema({ timestamps: true, versionKey: false })
export class TransportRequest {
  @ApiProperty({ description: 'ID du demandeur' })
  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  demandeurId: Types.ObjectId;

  @ApiPropertyOptional({ description: 'ID de l\'accompagnant assigné' })
  @Prop({ type: Types.ObjectId, ref: 'User', default: null })
  accompagnantId: Types.ObjectId | null;

  @ApiPropertyOptional({ description: 'ID du véhicule assigné (optionnel)' })
  @Prop({ type: Types.ObjectId, ref: 'Vehicle', default: null })
  vehicleId: Types.ObjectId | null;

  @ApiProperty({ enum: TransportType, description: 'Type de transport' })
  @Prop({ type: String, enum: TransportType, required: true })
  typeTransport: TransportType;

  @ApiPropertyOptional({
    enum: MotifTrajet,
    description: 'Motif du trajet (optionnel, rétrocompatible)',
  })
  @Prop({ type: String, enum: MotifTrajet, default: null })
  motifTrajet: MotifTrajet | null;

  @ApiPropertyOptional({
    description:
      'Priorité médicale (distincte de typeTransport=URGENCE). Utilisée pour le tri des demandes ouvertes.',
    default: false,
  })
  @Prop({ type: Boolean, default: false })
  prioriteMedicale: boolean;

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

  @ApiPropertyOptional({ description: "Types d'assistance requise" })
  @Prop({ type: [String], default: [] })
  besoinsAssistance: string[];

  @ApiProperty({ enum: TransportStatut, description: 'Statut', default: TransportStatut.EN_ATTENTE })
  @Prop({ type: String, enum: TransportStatut, default: TransportStatut.EN_ATTENTE })
  statut: TransportStatut;

  @ApiPropertyOptional({ description: 'Score de matching' })
  @Prop({ type: Number, default: null })
  scoreMatching: number | null;

  @ApiPropertyOptional({
    description: 'Sous-scores de matching (persistés si envoyés à l’acceptation)',
    type: Object,
  })
  @Prop({
    type: {
      proximity: { type: Number },
      rating: { type: Number },
      handicapVehicleFit: { type: Number },
      needsAdequacy: { type: Number },
      urgencyRecency: { type: Number, required: false },
    },
    default: null,
    _id: false,
  })
  matchingSubscores: {
    proximity: number;
    rating: number;
    handicapVehicleFit: number;
    needsAdequacy: number;
    urgencyRecency?: number;
  } | null;

  @ApiPropertyOptional({
    description: 'SHA256 (hex) du jeton de partage trajet (opaque côté client)',
  })
  @Prop({ type: String, default: null })
  shareTokenHash: string | null;

  @ApiPropertyOptional({ description: 'Expiration du jeton de partage' })
  @Prop({ type: Date, default: null })
  shareTokenExpiresAt: Date | null;

  @ApiPropertyOptional({ description: 'Date/heure d\'arrivée réelle (trajet terminé)' })
  @Prop({ type: Date, default: null })
  dateHeureArrivee: Date | null;

  @ApiPropertyOptional({ description: 'Durée du trajet en minutes (trajet terminé)' })
  @Prop({ type: Number, default: null })
  dureeMinutes: number | null;

  @ApiPropertyOptional({ description: 'Distance estimée en km' })
  @Prop({ type: Number, default: null })
  distanceEstimeeKm: number | null;

  @ApiPropertyOptional({ description: 'Durée estimée en minutes' })
  @Prop({ type: Number, default: null })
  dureeEstimeeMinutes: number | null;

  @ApiPropertyOptional({ description: 'Prix estimé en dinars tunisiens' })
  @Prop({ type: Number, default: null })
  prixEstimeTnd: number | null;

  @ApiPropertyOptional({ description: 'Prix final en dinars tunisiens' })
  @Prop({ type: Number, default: null })
  prixFinalTnd: number | null;

  @ApiPropertyOptional({ description: "Raison de l'annulation" })
  @Prop({ type: String, default: null })
  raisonAnnulation: string | null;

  @ApiPropertyOptional({ description: 'ID utilisateur qui a annulé' })
  @Prop({ type: Types.ObjectId, ref: 'User', default: null })
  annuleParUserId: Types.ObjectId | null;

  @ApiPropertyOptional({
    description:
      'Si présent, transport généré depuis une réservation véhicule (liaison 1–1, idempotence). Absent pour les demandes classiques — sinon index unique sparse ne peut pas avoir plusieurs null explicites.',
  })
  @Prop({ type: Types.ObjectId, ref: 'VehicleReservation' })
  vehicleReservationId?: Types.ObjectId;

  @Prop({ type: Number })
  driverCurrentLat?: number;

  @Prop({ type: Number })
  driverCurrentLng?: number;

  @ApiProperty({ description: 'Date de création' })
  createdAt?: Date;
}

export const TransportRequestSchema = SchemaFactory.createForClass(TransportRequest);

TransportRequestSchema.index(
  { vehicleReservationId: 1 },
  { unique: true, sparse: true },
);
