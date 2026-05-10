import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsString,
  IsNumber,
  IsBoolean,
  IsOptional,
  Min,
  Max,
  IsArray,
  MinLength,
  IsIn,
} from 'class-validator';

export class CreateLieuDto {
  @ApiProperty({ description: 'Nom du lieu' })
  @IsString()
  @MinLength(1, { message: 'Le nom est requis' })
  nom: string;

  @ApiProperty({ description: 'Adresse' })
  @IsString()
  @MinLength(1, { message: "L'adresse est requise" })
  adresse: string;

  @ApiProperty({ description: 'Type de lieu' })
  @IsString()
  @MinLength(1, { message: 'Le type de lieu est requis' })
  typeLieu: string;

  @ApiProperty({ description: 'Latitude' })
  @Type(() => Number)
  @IsNumber()
  latitude: number;

  @ApiProperty({ description: 'Longitude' })
  @Type(() => Number)
  @IsNumber()
  longitude: number;

  @ApiPropertyOptional({ description: 'Description' })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional({ description: 'Score accessibilité 0-100' })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  @Max(100)
  scoreAccessibilite?: number;

  @ApiPropertyOptional({
    description: 'Niveau de risque visuel',
    enum: ['safe', 'caution', 'danger'],
  })
  @IsOptional()
  @IsString()
  @IsIn(['safe', 'caution', 'danger'])
  riskLevel?: string;

  @ApiPropertyOptional({
    description: 'Statut de vérification',
    enum: ['auto', 'pending', 'verified', 'rejected'],
  })
  @IsOptional()
  @IsString()
  @IsIn(['auto', 'pending', 'verified', 'rejected'])
  verificationStatus?: string;

  @ApiPropertyOptional({ description: 'Résumé IA / texte communautaire' })
  @IsOptional()
  @IsString()
  aiSummary?: string;

  @ApiPropertyOptional({ description: 'Confiance IA [0..1]' })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  @Max(1)
  aiConfidence?: number;

  @ApiPropertyOptional({ description: 'Obstacle présent' })
  @IsOptional()
  @IsBoolean()
  obstaclePresent?: boolean;

  @ApiPropertyOptional({ description: 'Rampe' })
  @IsOptional()
  @IsBoolean()
  rampe?: boolean;

  @ApiPropertyOptional({ description: 'Ascenseur' })
  @IsOptional()
  @IsBoolean()
  ascenseur?: boolean;

  @ApiPropertyOptional({ description: 'Toilettes adaptées' })
  @IsOptional()
  @IsBoolean()
  toilettesAdaptees?: boolean;

  @ApiPropertyOptional({
    description: 'Images du lieu (tableau de filenames) si envoyées en JSON',
    type: [String],
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  images?: string[];
}
