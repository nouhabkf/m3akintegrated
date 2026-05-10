import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type RatingDocument = Rating & Document;

@Schema({ timestamps: true })
export class Rating {
  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  ratedUserId: Types.ObjectId; // Utilisateur évalué (bénévole)

  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  raterUserId: Types.ObjectId; // Utilisateur qui évalue

  @Prop({ type: Types.ObjectId, ref: 'HelpRequest' })
  helpRequestId?: Types.ObjectId; // Demande d'aide associée

  @Prop({ required: true, min: 1, max: 5 })
  note: number;

  @Prop()
  commentaire?: string;

  @Prop({ default: false })
  verified: boolean; // Vérifié si l'aide a été réellement fournie
}

export const RatingSchema = SchemaFactory.createForClass(Rating);

RatingSchema.index({ ratedUserId: 1 });
RatingSchema.index({ raterUserId: 1 });
RatingSchema.index({ helpRequestId: 1 });

// Empêcher les doublons
RatingSchema.index({ ratedUserId: 1, raterUserId: 1, helpRequestId: 1 }, { unique: true });




