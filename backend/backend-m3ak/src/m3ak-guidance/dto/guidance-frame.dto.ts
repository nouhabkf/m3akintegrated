import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsBase64, IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class GuidanceFrameDto {
  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  sessionId!: string;

  /** JPEG/PNG encodé en base64 (sans prefix "data:image/...;base64,") */
  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  @IsBase64()
  imageBase64!: string;

  @ApiPropertyOptional({ description: 'Timestamp côté client (ms)' })
  @IsOptional()
  clientTs?: number;
}
