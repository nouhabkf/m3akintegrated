import { ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsInt,
  IsNumber,
  IsOptional,
  IsString,
  Max,
  Min,
} from 'class-validator';
import {
  PLACES_DEFAULT_LIMIT,
  PLACES_MAX_LIMIT,
} from '../map-places.constants';

export class PlacesQueryDto {
  @ApiPropertyOptional({
    description:
      'Latitude sud de la bbox (avec west, north, east). Sinon : Grand Tunis par défaut.',
    example: 36.68,
  })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  south?: number;

  @ApiPropertyOptional({ description: 'Longitude ouest', example: 10.02 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  west?: number;

  @ApiPropertyOptional({ description: 'Latitude nord', example: 36.93 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  north?: number;

  @ApiPropertyOptional({ description: 'Longitude est', example: 10.35 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  east?: number;

  @ApiPropertyOptional({
    description:
      'Catégories séparées par des virgules (ex: restaurant,cafe,shop). Jeton « all » = large ensemble OSM. Vide = idem all.',
    example: 'restaurant,cafe,shop',
  })
  @IsOptional()
  @IsString()
  categories?: string;

  @ApiPropertyOptional({
    description: `Nombre max de lieux renvoyés (1–${PLACES_MAX_LIMIT})`,
    default: PLACES_DEFAULT_LIMIT,
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(PLACES_MAX_LIMIT)
  limit?: number;
}
