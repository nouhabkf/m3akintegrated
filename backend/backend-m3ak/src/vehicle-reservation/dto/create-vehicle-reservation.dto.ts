import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsMongoId, IsString, IsDateString, IsOptional } from 'class-validator';

export class CreateVehicleReservationDto {
  @ApiProperty({ description: 'ID du véhicule' })
  @IsMongoId()
  vehicleId: string;

  @ApiProperty({ description: 'Date de réservation (ISO)' })
  @IsDateString()
  date: string;

  @ApiProperty({ description: 'Heure de départ', example: '14:30' })
  @IsString()
  heure: string;

  @ApiPropertyOptional({ description: 'Lieu de départ' })
  @IsOptional()
  @IsString()
  lieuDepart?: string;

  @ApiPropertyOptional({ description: 'Lieu de destination' })
  @IsOptional()
  @IsString()
  lieuDestination?: string;

  @ApiPropertyOptional({ description: 'Besoins spécifiques' })
  @IsOptional()
  @IsString()
  besoinsSpecifiques?: string;
}
