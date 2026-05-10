import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsArray,
  IsBoolean,
  IsNumber,
  IsOptional,
  IsString,
  MinLength,
} from 'class-validator';

/**
 * Corps aligné sur le service FastAPI `POST /ai/accessibility/analyze`
 * (snake_case pour correspondance directe avec Python).
 */
export class PlaceAccessibilityAnalyzeRequestDto {
  @ApiProperty({ description: 'Nom du lieu analysé' })
  @IsString()
  @MinLength(1)
  place_name: string;

  @ApiProperty({ description: 'Latitude (WGS84)' })
  @Type(() => Number)
  @IsNumber()
  latitude: number;

  @ApiProperty({ description: 'Longitude (WGS84)' })
  @Type(() => Number)
  @IsNumber()
  longitude: number;

  @ApiPropertyOptional({ description: 'Accès fauteuil déclaré dans l’app' })
  @IsOptional()
  @IsBoolean()
  wheelchair_access?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  elevator?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  braille?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  audio_assistance?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  accessible_toilets?: boolean;

  @ApiPropertyOptional({
    description: 'Commentaires utilisateurs / préfixe [Communauté M3ak …]',
    type: [String],
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  user_comments?: string[];

  @ApiPropertyOptional({
    description: 'Indique si des posts communauté ont été agrégés pour ce lieu',
  })
  @IsOptional()
  @IsBoolean()
  has_community_data?: boolean;

  @ApiPropertyOptional({
    description: 'Nombre de posts communauté pris en compte',
  })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  community_posts_count?: number;
}
