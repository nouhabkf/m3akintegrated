import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString } from 'class-validator';

export class CancelTransportDto {
  @ApiPropertyOptional({ description: 'Raison de l\'annulation' })
  @IsOptional()
  @IsString()
  raison?: string;
}
