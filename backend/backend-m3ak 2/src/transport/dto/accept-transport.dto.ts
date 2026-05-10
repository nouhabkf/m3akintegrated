import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsNumber } from 'class-validator';

export class AcceptTransportDto {
  @ApiProperty({ description: 'ID de la demande de transport' })
  transportId: string;

  @ApiPropertyOptional({ description: 'Score de matching' })
  @IsOptional()
  @IsNumber()
  scoreMatching?: number;
}
