import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, IsOptional, IsNumber, Min, Max } from 'class-validator';

export class GeocodeDto {
  @ApiProperty({ description: 'Adresse ou lieu à géocoder', example: 'Avenue Habib Bourguiba, Tunis' })
  @IsString()
  query: string;

  @ApiPropertyOptional({ description: 'Code pays pour affiner la recherche (ex: TN pour Tunisie)' })
  @IsOptional()
  @IsString()
  countrycodes?: string;

  @ApiPropertyOptional({ description: 'Limite du nombre de résultats', default: 5 })
  @IsOptional()
  limit?: number;
}

export class ReverseGeocodeDto {
  @ApiProperty({ description: 'Latitude', example: 36.8065 })
  @IsNumber()
  @Min(-90)
  @Max(90)
  lat: number;

  @ApiProperty({ description: 'Longitude', example: 10.1815 })
  @IsNumber()
  @Min(-180)
  @Max(180)
  lon: number;
}
