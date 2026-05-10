import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Document } from 'mongoose';
import { EducationType } from '../enums/education-type.enum';

export type EducationModuleDocument = EduModule & Document;

@Schema({ timestamps: false, versionKey: false })
export class EduModule {
  @ApiProperty({ description: 'Titre du module' })
  @Prop({ type: String, required: true })
  titre: string;

  @ApiProperty({ enum: EducationType, description: 'Type (BRAILLE / LANGUE_SIGNES)' })
  @Prop({ type: String, enum: EducationType, required: true })
  type: EducationType;

  @ApiProperty({ description: 'Niveau' })
  @Prop({ type: String, required: true })
  niveau: string;

  @ApiPropertyOptional({ description: 'Description' })
  @Prop({ type: String, default: null })
  description: string | null;
}

export const EducationModuleSchema = SchemaFactory.createForClass(EduModule);
