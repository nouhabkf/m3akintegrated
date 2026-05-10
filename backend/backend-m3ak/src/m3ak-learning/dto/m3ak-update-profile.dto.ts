import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsInt, IsNumber, IsOptional, IsString } from 'class-validator';

export class M3akUpdateProfileDto {
  @ApiProperty()
  @IsInt()
  user_id: number;

  @ApiProperty()
  @IsInt()
  total_exercises_completed: number;

  @ApiProperty()
  @IsInt()
  current_level: number;

  @ApiProperty()
  @Type(() => Number)
  @IsNumber()
  progress_percentage: number;

  @ApiProperty()
  @IsInt()
  lessons_completed_this_week: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  last_exercise_date?: string;
}
