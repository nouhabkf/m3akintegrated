import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsNumber, IsOptional, IsString, IsMongoId, Min, Max } from 'class-validator';

export class CreateVehicleReservationReviewDto {
  @ApiProperty({ description: 'Note de 1 à 5', minimum: 1, maximum: 5 })
  @IsNumber()
  @Min(1)
  @Max(5)
  note: number;

  @ApiPropertyOptional({ description: 'Commentaire' })
  @IsOptional()
  @IsString()
  comment?: string;

  @ApiPropertyOptional({ description: 'ID du véhicule évalué' })
  @IsOptional()
  @IsMongoId()
  vehicleId?: string;

  @ApiPropertyOptional({ description: 'ID du chauffeur évalué' })
  @IsOptional()
  @IsMongoId()
  driverId?: string;
}
