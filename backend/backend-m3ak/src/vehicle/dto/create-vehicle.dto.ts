import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsString,
  IsOptional,
  IsEnum,
  IsArray,
  IsObject,
  ValidateNested,
  MinLength,
  MaxLength,
} from 'class-validator';
import { Type } from 'class-transformer';
import { VehicleStatut } from '../enums/vehicle-statut.enum';
import { AccessibiliteDto } from './accessibilite.dto';

export class CreateVehicleDto {
  @ApiPropertyOptional({
    description:
      'ID du propriétaire — obligatoire pour ADMIN ; ignoré pour les autres rôles (propriétaire = utilisateur connecté)',
  })
  @IsOptional()
  @IsString()
  ownerId?: string;

  @ApiProperty({ description: 'Marque du véhicule', example: 'Toyota' })
  @IsString()
  @MinLength(1, { message: 'La marque est requise' })
  @MaxLength(100)
  marque: string;

  @ApiProperty({ description: 'Modèle du véhicule', example: 'Yaris' })
  @IsString()
  @MinLength(1, { message: 'Le modèle est requis' })
  @MaxLength(100)
  modele: string;

  @ApiProperty({ description: 'Immatriculation', example: '123-456-78' })
  @IsString()
  @MinLength(1, { message: 'L\'immatriculation est requise' })
  @MaxLength(50)
  immatriculation: string;

  @ApiPropertyOptional({ description: 'Caractéristiques d\'accessibilité' })
  @IsOptional()
  @IsObject()
  @ValidateNested()
  @Type(() => AccessibiliteDto)
  accessibilite?: AccessibiliteDto;

  @ApiPropertyOptional({ description: 'URLs des photos', type: [String] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  photos?: string[];

  @ApiPropertyOptional({ enum: VehicleStatut, description: 'Statut du véhicule' })
  @IsOptional()
  @IsEnum(VehicleStatut)
  statut?: VehicleStatut;
}
