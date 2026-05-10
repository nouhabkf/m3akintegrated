import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Document, Types } from 'mongoose';

export type TransportReviewDocument = TransportReview & Document;

@Schema({ timestamps: true, versionKey: false })
export class TransportReview {
  @ApiProperty({ description: 'ID de la demande de transport' })
  @Prop({ type: Types.ObjectId, ref: 'TransportRequest', required: true })
  transportId: Types.ObjectId;

  @ApiProperty({ description: 'Note (1-5)' })
  @Prop({ type: Number, required: true, min: 1, max: 5 })
  note: number;

  @ApiPropertyOptional({ description: 'Commentaire' })
  @Prop({ type: String, default: null })
  commentaire: string | null;

  @ApiProperty({ description: 'Date de création' })
  createdAt?: Date;
}

export const TransportReviewSchema = SchemaFactory.createForClass(TransportReview);
