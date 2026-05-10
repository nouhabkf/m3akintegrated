import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Document, Types } from 'mongoose';

export type MedicalRecordDocument = MedicalRecord & Document;

@Schema({ timestamps: false, versionKey: false })
export class MedicalRecord {
  @ApiProperty({ description: 'ID utilisateur (ref users)' })
  @Prop({ type: Types.ObjectId, ref: 'User', required: true, unique: true })
  userId: Types.ObjectId;

  @ApiPropertyOptional({ description: 'Groupe sanguin' })
  @Prop({ type: String, default: null })
  groupeSanguin: string | null;

  @ApiPropertyOptional({ description: 'Allergies' })
  @Prop({ type: String, default: null })
  allergies: string | null;

  @ApiPropertyOptional({ description: 'Maladies chroniques' })
  @Prop({ type: String, default: null })
  maladiesChroniques: string | null;

  @ApiPropertyOptional({ description: 'Médicaments' })
  @Prop({ type: String, default: null })
  medicaments: string | null;

  @ApiPropertyOptional({ description: 'Médecin traitant' })
  @Prop({ type: String, default: null })
  medecinTraitant: string | null;

  @ApiPropertyOptional({ description: 'Contact urgence' })
  @Prop({ type: String, default: null })
  contactUrgence: string | null;

  @ApiProperty({ description: 'Date de dernière mise à jour' })
  @Prop({ type: Date, default: Date.now })
  updatedAt: Date;
}

export const MedicalRecordSchema = SchemaFactory.createForClass(MedicalRecord);
