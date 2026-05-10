import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString } from 'class-validator';

export class GuidanceSessionDto {
  @ApiPropertyOptional({ description: 'Hint device/platform (web/android/ios)' })
  @IsOptional()
  @IsString()
  clientHint?: string;
}
