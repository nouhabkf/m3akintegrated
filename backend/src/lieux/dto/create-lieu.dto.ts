import { IsString, IsNumber, IsOptional, IsArray, Min, Max } from 'class-validator';

export class CreateLieuDto {
  @IsString()
  nom: string;

  @IsString()
  typeLieu: string;

  @IsString()
  adresse: string;

  @IsNumber()
  @Min(-90)
  @Max(90)
  latitude: number;

  @IsNumber()
  @Min(-180)
  @Max(180)
  longitude: number;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsString()
  telephone?: string;

  @IsOptional()
  @IsString()
  horaires?: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  amenities?: string[];

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  images?: string[];
}





