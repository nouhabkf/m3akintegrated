import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { ApiProperty } from '@nestjs/swagger';
import { Document, Types } from 'mongoose';

export type EducationProgressDocument = EducationProgress & Document;

@Schema({ timestamps: false, versionKey: false })
export class EducationProgress {
  @ApiProperty({ description: 'ID utilisateur' })
  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  userId: Types.ObjectId;

  @ApiProperty({ description: 'ID du module' })
  @Prop({ type: Types.ObjectId, ref: 'EduModule', required: true })
  moduleId: Types.ObjectId;

  @ApiProperty({ description: 'Score' })
  @Prop({ type: Number, default: 0 })
  score: number;

  @ApiProperty({ description: 'Niveau actuel' })
  @Prop({ type: String, default: 'debutant' })
  niveauActuel: string;

  @ApiProperty({ description: 'Dernière activité' })
  @Prop({ type: Date, default: Date.now })
  derniereActivite: Date;
}

export const EducationProgressSchema = SchemaFactory.createForClass(EducationProgress);
