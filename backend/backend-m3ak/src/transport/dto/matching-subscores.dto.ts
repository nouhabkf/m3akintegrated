import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsNumber, IsOptional, Max, Min } from 'class-validator';

/** Sous-scores 0–1 renvoyés par le matching et persistables à l’acceptation (audit / UI). */
export class MatchingSubscoresDto {
  @ApiProperty({ minimum: 0, maximum: 1, description: 'Proximité normalisée' })
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  @Max(1)
  proximity!: number;

  @ApiProperty({ minimum: 0, maximum: 1, description: 'Note moyenne normalisée' })
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  @Max(1)
  rating!: number;

  @ApiProperty({ minimum: 0, maximum: 1, description: 'Adéquation véhicule / handicap' })
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  @Max(1)
  handicapVehicleFit!: number;

  @ApiProperty({
    minimum: 0,
    maximum: 1,
    description: 'Adéquation besoins d’assistance / véhicule',
  })
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  @Max(1)
  needsAdequacy!: number;

  @ApiPropertyOptional({
    minimum: 0,
    maximum: 1,
    description: 'Bonus urgence / fraîcheur position',
  })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  @Max(1)
  urgencyRecency?: number;
}
