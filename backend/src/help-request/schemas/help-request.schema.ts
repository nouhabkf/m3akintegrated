import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type HelpRequestDocument = HelpRequest & Document;

export enum HelpRequestStatus {
  EN_ATTENTE = 'EN_ATTENTE',
  EN_COURS = 'EN_COURS',
  TERMINEE = 'TERMINEE',
  ANNULEE = 'ANNULEE',
}

export enum HelpRequestType {
  ACCOMPAGNEMENT = 'ACCOMPAGNEMENT',
  ADMINISTRATIF = 'ADMINISTRATIF',
  TRANSPORT = 'TRANSPORT',
  AUTRE = 'AUTRE',
}

@Schema({ timestamps: true })
export class HelpRequest {
  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  userId: Types.ObjectId;

  @Prop({ required: true })
  description: string;

  @Prop({ type: String, enum: HelpRequestType, default: HelpRequestType.ACCOMPAGNEMENT })
  type: HelpRequestType;

  @Prop({ required: true })
  latitude: number;

  @Prop({ required: true })
  longitude: number;

  @Prop({ type: String, enum: HelpRequestStatus, default: HelpRequestStatus.EN_ATTENTE })
  statut: HelpRequestStatus;

  @Prop({ type: Types.ObjectId, ref: 'User' })
  acceptedBy?: Types.ObjectId;

  @Prop()
  address?: string;

  @Prop()
  city?: string;
}

export const HelpRequestSchema = SchemaFactory.createForClass(HelpRequest);

// Index géospatial pour les recherches de proximité
HelpRequestSchema.index({ latitude: 1, longitude: 1 });
HelpRequestSchema.index({ userId: 1 });
HelpRequestSchema.index({ statut: 1 });




