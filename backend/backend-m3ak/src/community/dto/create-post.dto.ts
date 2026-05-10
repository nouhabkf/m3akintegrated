import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform, Type } from 'class-transformer';
import {
  IsBoolean,
  IsIn,
  IsNumber,
  IsOptional,
  IsString,
  Max,
  Min,
  MinLength,
} from 'class-validator';
import {
  POST_INPUT_MODE_VALUES,
  POST_LOCATION_SHARING_MODE_VALUES,
  POST_NATURE_VALUES,
  POST_TARGET_AUDIENCE_VALUES,
} from '../enums/post-inclusion.enum';
import { POST_TYPE_VALUES } from '../enums/post-type.enum';

const DANGER_LEVELS = ['none', 'low', 'medium', 'critical'] as const;
const STREAM_TYPES = ['post', 'live', 'replay'] as const;
const LIVE_STATUSES = ['active', 'ended'] as const;

function parseOptionalBool(value: unknown): boolean | undefined {
  if (value === undefined || value === null || value === '') return undefined;
  if (typeof value === 'boolean') return value;
  if (value === 'true' || value === '1' || value === 'on') return true;
  if (value === 'false' || value === '0') return false;
  return undefined;
}

export class CreatePostDto {
  @ApiProperty({ description: 'Contenu du post' })
  @IsString()
  @MinLength(1, { message: 'Le contenu est requis' })
  contenu: string;

  @ApiProperty({
    description: 'Type de post (enum alignée Flutter / Nest `PostTypeCommunity`)',
    enum: POST_TYPE_VALUES,
    example: 'general',
  })
  @IsString()
  @MinLength(1, { message: 'Le type est requis' })
  @IsIn(POST_TYPE_VALUES, { message: 'Type de post invalide' })
  type: string;

  /** Optionnel (multipart) : corrélation Lieu + alerte SOS si critique. */
  @ApiPropertyOptional({ description: 'Latitude du signalement' })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(-90)
  @Max(90)
  latitude?: number;

  @ApiPropertyOptional({ description: 'Longitude du signalement' })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(-180)
  @Max(180)
  longitude?: number;

  @ApiPropertyOptional({
    description: 'Niveau de danger (`critical` + coords → alerte SOS proximité)',
    enum: DANGER_LEVELS,
  })
  @IsOptional()
  @IsString()
  @IsIn([...DANGER_LEVELS])
  dangerLevel?: string;

  // —— Inclusif (optionnel, rétrocompatible) ——

  @ApiPropertyOptional({ enum: POST_NATURE_VALUES })
  @IsOptional()
  @IsString()
  @IsIn([...POST_NATURE_VALUES])
  postNature?: string;

  @ApiPropertyOptional({ enum: POST_TARGET_AUDIENCE_VALUES })
  @IsOptional()
  @IsString()
  @IsIn([...POST_TARGET_AUDIENCE_VALUES])
  targetAudience?: string;

  @ApiPropertyOptional({ enum: POST_INPUT_MODE_VALUES })
  @IsOptional()
  @IsString()
  @IsIn([...POST_INPUT_MODE_VALUES])
  inputMode?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @Transform(({ value }) => parseOptionalBool(value))
  @IsBoolean()
  isForAnotherPerson?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @Transform(({ value }) => parseOptionalBool(value))
  @IsBoolean()
  needsAudioGuidance?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @Transform(({ value }) => parseOptionalBool(value))
  @IsBoolean()
  needsVisualSupport?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @Transform(({ value }) => parseOptionalBool(value))
  @IsBoolean()
  needsPhysicalAssistance?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @Transform(({ value }) => parseOptionalBool(value))
  @IsBoolean()
  needsSimpleLanguage?: boolean;

  @ApiPropertyOptional({ enum: POST_LOCATION_SHARING_MODE_VALUES })
  @IsOptional()
  @IsString()
  @IsIn([...POST_LOCATION_SHARING_MODE_VALUES])
  locationSharingMode?: string;

  @ApiPropertyOptional({
    description: 'Type de flux du post',
    enum: STREAM_TYPES,
    default: 'post',
  })
  @IsOptional()
  @IsString()
  @IsIn([...STREAM_TYPES])
  streamType?: string;

  @ApiPropertyOptional({ description: 'Session live active', default: false })
  @IsOptional()
  @Transform(({ value }) => parseOptionalBool(value))
  @IsBoolean()
  isLive?: boolean;

  @ApiPropertyOptional({
    description: 'Statut du live',
    enum: LIVE_STATUSES,
    default: 'ended',
  })
  @IsOptional()
  @IsString()
  @IsIn([...LIVE_STATUSES])
  liveStatus?: string;

  @ApiPropertyOptional({ description: 'Nombre de spectateurs', default: 0 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  viewersCount?: number;

  @ApiPropertyOptional({ description: 'URL vidéo live/replay (optionnel)' })
  @IsOptional()
  @IsString()
  liveVideoUrl?: string;
}
