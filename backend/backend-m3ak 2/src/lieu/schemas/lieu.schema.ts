import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Document, Types } from 'mongoose';

export type LieuDocument = Lieu & Document;

@Schema({ timestamps: true, versionKey: false })
export class Lieu {
  @ApiProperty({ description: 'Nom du lieu' })
  @Prop({ type: String, required: true })
  nom: string;

  @ApiProperty({ description: 'Adresse' })
  @Prop({ type: String, required: true })
  adresse: string;

  @ApiProperty({ description: 'Type de lieu' })
  @Prop({ type: String, required: true })
  typeLieu: string;

  @ApiProperty({ description: 'Latitude' })
  @Prop({ type: Number, required: true })
  latitude: number;

  @ApiProperty({ description: 'Longitude' })
  @Prop({ type: Number, required: true })
  longitude: number;

  @Prop({
    type: {
      type: String,
      enum: ['Point'],
      default: 'Point',
    },
    coordinates: { type: [Number], default: [0, 0] },
  })
  location: { type: string; coordinates: [number, number] };

  @ApiPropertyOptional({ description: 'Description' })
  @Prop({ type: String, default: null })
  description: string | null;

  @ApiPropertyOptional({ description: 'Score d\'accessibilité (0-100)' })
  @Prop({ type: Number, default: 0 })
  scoreAccessibilite: number;

  @ApiPropertyOptional({
    description: 'Niveau de risque (safe/caution/danger) pour affichage couleur',
    enum: ['safe', 'caution', 'danger'],
    default: 'safe',
  })
  @Prop({ type: String, default: 'safe' })
  riskLevel: string;

  @ApiPropertyOptional({
    description: 'Statut de vérification du signalement communautaire',
    enum: ['auto', 'pending', 'verified', 'rejected'],
    default: 'verified',
  })
  @Prop({ type: String, default: 'verified' })
  verificationStatus: string;

  @ApiPropertyOptional({ description: 'Lien post source (si issu de la communauté)' })
  @Prop({ type: Types.ObjectId, ref: 'Post', required: false })
  sourcePostId?: Types.ObjectId;

  @ApiPropertyOptional({ description: 'Confiance IA [0..1]' })
  @Prop({ type: Number, required: false, default: null })
  aiConfidence?: number | null;

  @ApiPropertyOptional({ description: 'Résumé IA ou texte publié', required: false })
  @Prop({ type: String, required: false, default: null })
  aiSummary?: string | null;

  @ApiPropertyOptional({ description: 'Obstacle présent selon IA/validation', default: false })
  @Prop({ type: Boolean, default: false })
  obstaclePresent: boolean;

  @ApiPropertyOptional({ description: 'Dernier signalement lié' })
  @Prop({ type: Date, required: false, default: null })
  lastReportedAt?: Date | null;

  @ApiPropertyOptional({ description: 'Rampe disponible', default: false })
  @Prop({ type: Boolean, default: false })
  rampe: boolean;

  @ApiPropertyOptional({ description: 'Ascenseur disponible', default: false })
  @Prop({ type: Boolean, default: false })
  ascenseur: boolean;

  @ApiPropertyOptional({ description: 'Toilettes adaptées', default: false })
  @Prop({ type: Boolean, default: false })
  toilettesAdaptees: boolean;

  @ApiPropertyOptional({
    description: 'Liste des images (filenames stockés dans /uploads)',
    type: [String],
  })
  @Prop({ type: [String], default: [] })
  images: string[];

  @ApiProperty({ description: 'Date de création' })
  createdAt?: Date;
}

export const LieuSchema = SchemaFactory.createForClass(Lieu);

LieuSchema.pre('save', function (next) {
  if (this.latitude != null && this.longitude != null) {
    this.location = {
      type: 'Point',
      coordinates: [this.longitude, this.latitude],
    } as { type: string; coordinates: [number, number] };
  }
  next();
});

// Index géospatial 2dsphere pour recherche par proximité
LieuSchema.index({ location: '2dsphere' });
