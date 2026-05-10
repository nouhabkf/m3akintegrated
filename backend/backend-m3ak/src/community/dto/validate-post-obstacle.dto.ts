import { ApiProperty } from '@nestjs/swagger';
import { IsBoolean } from 'class-validator';

export class ValidatePostObstacleDto {
  @ApiProperty({ description: 'true = obstacle toujours présent, false = plus là / signal erroné' })
  @IsBoolean()
  confirm: boolean;
}
