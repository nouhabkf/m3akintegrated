import { ApiPropertyOptional } from '@nestjs/swagger';
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

export class UpdateVehicleDto {
  @ApiPropertyOptional({ description: 'Marque du véhicule' })
  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(100)
  marque?: string;

  @ApiPropertyOptional({ description: 'Modèle du véhicule' })
  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(100)
  modele?: string;

  @ApiPropertyOptional({ description: 'Immatriculation' })
  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(50)
  immatriculation?: string;

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
