import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform, Type } from 'class-transformer';
import {
  IsArray,
  IsBoolean,
  IsLatitude,
  IsLongitude,
  IsNumber,
  IsOptional,
  IsString,
  Max,
  Min,
} from 'class-validator';

/**
 * Corps POST /transport/matching — même sémantique que GET /transport/matching,
 * utile pour `besoinsAssistance[]` sans allonger l’URL.
 */
export class TransportMatchingBodyDto {
  @ApiProperty({ description: 'Latitude du point de référence' })
  @Type(() => Number)
  @IsLatitude()
  latitude!: number;

  @ApiProperty({ description: 'Longitude du point de référence' })
  @Type(() => Number)
  @IsLongitude()
  longitude!: number;

  @ApiPropertyOptional({ description: 'Type handicap du demandeur (filtre véhicule)' })
  @IsOptional()
  @IsString()
  typeHandicap?: string;

  @ApiPropertyOptional({ description: 'Priorité urgence (défaut: false)' })
  @IsOptional()
  @Transform(({ value }) => value === true || value === 'true')
  @IsBoolean()
  urgence?: boolean;

  @ApiPropertyOptional({ description: 'Rayon de recherche en km' })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0.1)
  @Max(500)
  rayonKm?: number;

  @ApiPropertyOptional({
    type: [String],
    description: 'Besoins d’assistance (prise en compte dans le scoring NestJS)',
  })
  @IsOptional()
  @Transform(({ value }) => {
    if (value == null) return undefined;
    if (Array.isArray(value)) return value.filter((v) => typeof v === 'string' && v.trim());
    if (typeof value === 'string') {
      return value
        .split(',')
        .map((s) => s.trim())
        .filter(Boolean);
    }
    return undefined;
  })
  @IsArray()
  @IsString({ each: true })
  besoinsAssistance?: string[];
}
