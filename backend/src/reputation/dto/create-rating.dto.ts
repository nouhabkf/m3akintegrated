import { IsNumber, IsString, IsOptional, Min, Max } from 'class-validator';

export class CreateRatingDto {
  @IsNumber()
  @Min(1)
  @Max(5)
  note: number;

  @IsString()
  @IsOptional()
  commentaire?: string;

  @IsString()
  @IsOptional()
  helpRequestId?: string;
}




