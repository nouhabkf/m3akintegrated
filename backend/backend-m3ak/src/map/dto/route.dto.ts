import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsNumber,
  Min,
  Max,
  IsOptional,
  IsArray,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';

export class RouteWaypointDto {
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

export class RouteDto {
  @ApiProperty({
    description: 'Point de départ',
    example: { lat: 36.8065, lon: 10.1815 },
  })
  @ValidateNested()
  @Type(() => RouteWaypointDto)
  origin: RouteWaypointDto;

  @ApiProperty({
    description: 'Point d\'arrivée',
    example: { lat: 36.8536, lon: 10.3239 },
  })
  @ValidateNested()
  @Type(() => RouteWaypointDto)
  destination: RouteWaypointDto;

  @ApiPropertyOptional({
    description: 'Points intermédiaires (optionnel)',
    type: [RouteWaypointDto],
  })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => RouteWaypointDto)
  waypoints?: RouteWaypointDto[];
}
