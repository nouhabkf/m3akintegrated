import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsInt,
  IsNumber,
  IsString,
} from 'class-validator';

export class M3akPredictDto {
  @ApiProperty()
  @IsInt()
  user_id: number;

  @ApiProperty()
  @IsInt()
  response_time: number;

  @ApiProperty()
  @IsInt()
  errors_count: number;

  @ApiProperty()
  @Type(() => Number)
  @IsNumber()
  score: number;

  @ApiProperty()
  @IsInt()
  previous_successes: number;

  @ApiProperty()
  @IsInt()
  exercise_id: number;

  @ApiProperty()
  @IsString()
  user_answer: string;

  @ApiProperty()
  @IsInt()
  success_streak: number;

  @ApiProperty()
  @Type(() => Number)
  @IsNumber()
  avg_last_5_scores: number;

  @ApiProperty()
  @IsInt()
  total_sessions: number;

  @ApiProperty()
  @Type(() => Number)
  @IsNumber()
  error_rate: number;

  @ApiProperty()
  @IsInt()
  avg_response_time: number;
}
