import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsNumber, IsOptional, IsString, Min, Max } from 'class-validator';

export class CreateTransportReviewDto {
  @ApiProperty({ description: 'Note de 1 à 5' })
  @IsNumber()
  @Min(1)
  @Max(5)
  note: number;

  @ApiPropertyOptional({ description: 'Commentaire' })
  @IsOptional()
  @IsString()
  commentaire?: string;
}
