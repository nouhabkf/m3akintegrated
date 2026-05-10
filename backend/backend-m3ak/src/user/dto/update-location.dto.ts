import { ApiProperty } from '@nestjs/swagger';
import { IsNumber, Min, Max } from 'class-validator';

export class UpdateLocationDto {
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
