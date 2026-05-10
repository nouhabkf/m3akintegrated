import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type UserDocument = User & Document;

export enum UserRole {
  HANDICAPE = 'HANDICAPE',
  ACCOMPAGNANT = 'ACCOMPAGNANT',
  ADMIN = 'ADMIN',
}

@Schema({ timestamps: true })
export class User {
  @Prop({ required: true })
  nom: string;

  @Prop({ required: true })
  prenom: string;

  @Prop({ required: true, unique: true })
  email: string;

  @Prop()
  password?: string;

  @Prop({ type: String, enum: UserRole, default: UserRole.HANDICAPE })
  role: UserRole;

  @Prop()
  telephone?: string;

  @Prop()
  typeHandicap?: string;

  @Prop()
  besoinSpecifique?: string;

  @Prop({ default: false })
  animalAssistance: boolean;

  @Prop()
  typeAccompagnant?: string;

  @Prop()
  specialisation?: string;

  @Prop({ default: false })
  disponible: boolean;

  @Prop({ default: 0.0 })
  noteMoyenne: number;

  @Prop({ default: 'fr' })
  langue: string;

  @Prop()
  photoProfil?: string;

  @Prop({ default: 'ACTIF' })
  statut: string;

  @Prop()
  googleId?: string;

  // Système de réputation
  @Prop({ default: 0 })
  trustPoints: number;

  @Prop({ type: [String], default: [] })
  badges: string[];

  @Prop({ default: 0 })
  totalAidesFournies: number;

  @Prop({ default: 0 })
  totalAidesRecues: number;
}

export const UserSchema = SchemaFactory.createForClass(User);




