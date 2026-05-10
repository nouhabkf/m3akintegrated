import { IsString, IsNumber, IsEnum, IsOptional, Min, Max } from 'class-validator';
import { HelpRequestType } from '../schemas/help-request.schema';

export class CreateHelpRequestDto {
  @IsString()
  description: string;

  @IsEnum(HelpRequestType)
  @IsOptional()
  type?: HelpRequestType;

  @IsNumber()
  @Min(-90)
  @Max(90)
  latitude: number;

  @IsNumber()
  @Min(-180)
  @Max(180)
  longitude: number;

  @IsString()
  @IsOptional()
  address?: string;

  @IsString()
  @IsOptional()
  city?: string;
}




