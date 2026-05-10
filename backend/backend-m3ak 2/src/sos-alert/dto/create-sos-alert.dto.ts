import { ApiProperty } from '@nestjs/swagger';
import { IsNumber } from 'class-validator';

export class CreateSosAlertDto {
  @ApiProperty({ description: 'Latitude' })
  @IsNumber()
  latitude: number;

  @ApiProperty({ description: 'Longitude' })
  @IsNumber()
  longitude: number;
}
