import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform, Type } from 'class-transformer';
import {
  IsEnum,
  IsString,
  IsNumber,
  IsDateString,
  IsOptional,
  IsArray,
  IsBoolean,
} from 'class-validator';
import { TransportType } from '../enums/transport-type.enum';
import { MotifTrajet } from '../enums/motif-trajet.enum';

export class CreateTransportDto {
  @ApiProperty({ enum: TransportType, description: 'Type de transport' })
  @IsEnum(TransportType)
  typeTransport: TransportType;

  @ApiPropertyOptional({
    enum: MotifTrajet,
    description: 'Motif du trajet (optionnel — distinct du type URGENCE/QUOTIDIEN)',
  })
  @IsOptional()
  @IsEnum(MotifTrajet)
  motifTrajet?: MotifTrajet;

  @ApiPropertyOptional({
    description:
      'Priorité médicale : remonte dans la file chauffeur au-dessus des urgences non médicales (voir README)',
  })
  @IsOptional()
  @Transform(({ value }) => value === true || value === 'true')
  @IsBoolean()
  prioriteMedicale?: boolean;

  @ApiProperty({ description: 'Adresse de départ' })
  @IsString()
  depart: string;

  @ApiProperty({ description: 'Adresse de destination' })
  @IsString()
  destination: string;

  @ApiProperty({ description: 'Latitude départ' })
  @Type(() => Number)
  @IsNumber()
  latitudeDepart: number;

  @ApiProperty({ description: 'Longitude départ' })
  @Type(() => Number)
  @IsNumber()
  longitudeDepart: number;

  @ApiProperty({ description: 'Latitude arrivée' })
  @Type(() => Number)
  @IsNumber()
  latitudeArrivee: number;

  @ApiProperty({ description: 'Longitude arrivée' })
  @Type(() => Number)
  @IsNumber()
  longitudeArrivee: number;

  @ApiProperty({ description: 'Date et heure (ISO 8601)' })
  @IsDateString()
  dateHeure: string;

  @ApiPropertyOptional({
    description: "Types d'assistance requise (ex: fauteuil_roulant, aide_embarquement)",
    type: [String],
    example: ['fauteuil_roulant', 'aide_embarquement'],
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  besoinsAssistance?: string[];
}
