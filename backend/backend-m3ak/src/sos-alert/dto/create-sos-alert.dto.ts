import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsNumber, IsOptional, IsString, Max, Min } from 'class-validator';

export class CreateSosAlertDto {
  @ApiProperty({ description: 'Latitude' })
  @IsNumber()
  latitude: number;

  @ApiProperty({ description: 'Longitude' })
  @IsNumber()
  longitude: number;

  @ApiPropertyOptional({ description: 'Score stress vocal 0–100' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(100)
  voiceScore?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  voiceLabel?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  voiceLabelFr?: string;

  @ApiPropertyOptional({ description: 'VOICE_AUTO, MANUAL, MEDICAL…' })
  @IsOptional()
  @IsString()
  alertSource?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  beneficiaryTypeHandicap?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  beneficiaryBesoinSpecifique?: string;
}
