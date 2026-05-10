import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type LieuDocument = Lieu & Document;

export enum LieuStatus {
  PENDING = 'PENDING',
  APPROVED = 'APPROVED',
  REJECTED = 'REJECTED',
}

@Schema({ timestamps: true })
export class Lieu {
  @Prop({ required: true })
  nom: string;

  @Prop({ required: true })
  typeLieu: string; // PHARMACY, RESTAURANT, HOSPITAL, SCHOOL, SHOP, PUBLICTRANSPORT, PARK, OTHER

  @Prop({ required: true })
  adresse: string;

  @Prop({
    type: {
      type: String,
      enum: ['Point'],
      default: 'Point',
    },
    coordinates: {
      type: [Number],
      required: true,
    },
  })
  location: {
    type: string;
    coordinates: [number, number]; // [longitude, latitude] - Format GeoJSON
  };

  @Prop()
  description?: string;

  @Prop({ enum: LieuStatus, default: LieuStatus.PENDING })
  statut: LieuStatus;

  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  createdBy: Types.ObjectId;

  @Prop()
  telephone?: string;

  @Prop()
  horaires?: string;

  @Prop([String])
  amenities?: string[];

  @Prop([String])
  images?: string[];
}

export const LieuSchema = SchemaFactory.createForClass(Lieu);

// Index géospatial pour la recherche de proximité
LieuSchema.index({ location: '2dsphere' });

// Index pour les recherches par statut
LieuSchema.index({ statut: 1 });
LieuSchema.index({ typeLieu: 1 });
LieuSchema.index({ createdAt: -1 });





