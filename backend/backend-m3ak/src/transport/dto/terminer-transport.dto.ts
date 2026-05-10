import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsNumber, IsDateString, Min } from 'class-validator';

export class TerminerTransportDto {
  @ApiPropertyOptional({ description: 'Durée du trajet en minutes' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  dureeMinutes?: number;

  @ApiPropertyOptional({ description: "Date/heure d'arrivée réelle (ISO 8601)" })
  @IsOptional()
  @IsDateString()
  dateHeureArrivee?: string;
}
