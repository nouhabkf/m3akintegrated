import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Document } from 'mongoose';
import { Role } from '../enums/role.enum';

export type UserDocument = User & Document;

@Schema({ timestamps: true, versionKey: false })
export class User {
  @ApiProperty({ description: 'Nom de famille', example: 'Benali' })
  @Prop({ required: true })
  nom: string;

  @ApiProperty({ description: 'Prénom', example: 'Ahmed' })
  @Prop({ required: true })
  prenom: string;

  @ApiProperty({ description: 'Email unique', example: 'ahmed@example.com' })
  @Prop({ required: true, unique: true, lowercase: true })
  email: string;

  @ApiProperty({ description: 'Mot de passe (min 6 caractères)' })
  @Prop({ required: true, minlength: 6, select: false })
  password: string;

  @ApiPropertyOptional({ description: 'Téléphone' })
  @Prop({ type: String, default: null })
  telephone: string | null;

  @ApiProperty({ enum: Role, description: 'Rôle utilisateur' })
  @Prop({
    type: String,
    enum: Object.values(Role),
    required: true,
  })
  role: Role;

  @ApiPropertyOptional({ description: 'Type de handicap (pour HANDICAPE)' })
  @Prop({ type: String, default: null })
  typeHandicap: string | null;

  @ApiPropertyOptional({ description: 'Besoins spécifiques' })
  @Prop({ type: String, default: null })
  besoinSpecifique: string | null;

  @ApiPropertyOptional({ description: 'Animal d\'assistance', default: false })
  @Prop({ type: Boolean, default: false })
  animalAssistance: boolean;

  @ApiPropertyOptional({ description: 'Type d\'accompagnant (pour ACCOMPAGNANT)' })
  @Prop({ type: String, default: null })
  typeAccompagnant: string | null;

  @ApiPropertyOptional({ description: 'Spécialisation (pour ACCOMPAGNANT)' })
  @Prop({ type: String, default: null })
  specialisation: string | null;

  @ApiPropertyOptional({ description: 'Disponible pour accompagnement', default: false })
  @Prop({ type: Boolean, default: false })
  disponible: boolean;

  @ApiPropertyOptional({ description: 'Note moyenne des évaluations', default: 0 })
  @Prop({ type: Number, default: 0 })
  noteMoyenne: number;

  @ApiPropertyOptional({
    description:
      'Points de confiance (aide communauté : commentaires, acceptation de demandes)',
    default: 0,
  })
  @Prop({ type: Number, default: 0 })
  trustPoints: number;

  @ApiPropertyOptional({ description: 'Langue préférée (ar, fr, etc.)' })
  @Prop({ type: String, default: 'fr' })
  langue: string;

  @ApiPropertyOptional({ description: 'URL photo de profil' })
  @Prop({ type: String, default: null })
  photoProfil: string | null;

  @ApiPropertyOptional({ description: 'Statut du compte', default: 'ACTIF' })
  @Prop({ type: String, default: 'ACTIF' })
  statut: string;

  @ApiPropertyOptional({
    description:
      'Compte partenaire (association, commerce labellisé) — badge « Partenaire »',
    default: false,
  })
  @Prop({ type: Boolean, default: false })
  partenaire: boolean;

  @ApiProperty({ description: 'Date de création' })
  createdAt?: Date;

  @ApiProperty({ description: 'Date de dernière mise à jour' })
  updatedAt?: Date;
}

export const UserSchema = SchemaFactory.createForClass(User);

// Index pour les requêtes fréquentes
UserSchema.index({ email: 1 });
UserSchema.index({ role: 1 });
