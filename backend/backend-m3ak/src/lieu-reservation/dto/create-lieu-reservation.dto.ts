import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsMongoId, IsString, IsDateString, IsOptional } from 'class-validator';

export class CreateLieuReservationDto {
  @ApiProperty({ description: 'ID du lieu' })
  @IsMongoId()
  lieuId: string;

  @ApiProperty({ description: 'Date (ISO)' })
  @IsDateString()
  date: string;

  @ApiProperty({ description: 'Heure' })
  @IsString()
  heure: string;

  @ApiPropertyOptional({ description: 'Besoins spécifiques' })
  @IsOptional()
  @IsString()
  besoinsSpecifiques?: string;
}
