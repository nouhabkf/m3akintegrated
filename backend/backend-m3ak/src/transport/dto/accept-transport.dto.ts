import { ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsOptional, IsNumber, IsString, ValidateNested } from 'class-validator';
import { MatchingSubscoresDto } from './matching-subscores.dto';

export class AcceptTransportDto {
  @ApiPropertyOptional({ description: 'Score de matching' })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  scoreMatching?: number;

  @ApiPropertyOptional({ description: 'ID du véhicule assigné pour ce trajet' })
  @IsOptional()
  @IsString()
  vehicleId?: string;

  @ApiPropertyOptional({
    type: MatchingSubscoresDto,
    description: 'Sous-scores (persistés sur la demande si fournis)',
  })
  @IsOptional()
  @ValidateNested()
  @Type(() => MatchingSubscoresDto)
  matchingSubscores?: MatchingSubscoresDto;
}
