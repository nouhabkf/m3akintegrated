import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsBoolean,
  IsIn,
  IsNumber,
  IsOptional,
  IsString,
} from 'class-validator';
import {
  HELP_REQUEST_HELP_TYPES,
  HELP_REQUEST_INPUT_MODES,
  HELP_REQUEST_REQUESTER_PROFILES,
} from '../enums/help-request-inclusion.enum';

export class CreateHelpRequestDto {
  @ApiPropertyOptional({
    description:
      'Texte libre. Si absent ou trop court, la description est générée à partir des options inclusives.',
  })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiProperty({ description: 'Latitude' })
  @IsNumber()
  @Type(() => Number)
  latitude!: number;

  @ApiProperty({ description: 'Longitude' })
  @IsNumber()
  @Type(() => Number)
  longitude!: number;

  @ApiPropertyOptional({
    enum: HELP_REQUEST_HELP_TYPES,
    description: 'Type de besoin (optionnel)',
  })
  @IsOptional()
  @IsIn(HELP_REQUEST_HELP_TYPES as unknown as string[])
  helpType?: (typeof HELP_REQUEST_HELP_TYPES)[number];

  @ApiPropertyOptional({
    enum: HELP_REQUEST_INPUT_MODES,
    description: 'Mode de saisie côté client',
  })
  @IsOptional()
  @IsIn(HELP_REQUEST_INPUT_MODES as unknown as string[])
  inputMode?: (typeof HELP_REQUEST_INPUT_MODES)[number];

  @ApiPropertyOptional({
    enum: HELP_REQUEST_REQUESTER_PROFILES,
    description: 'Profil déclaré du demandeur',
  })
  @IsOptional()
  @IsIn(HELP_REQUEST_REQUESTER_PROFILES as unknown as string[])
  requesterProfile?: (typeof HELP_REQUEST_REQUESTER_PROFILES)[number];

  @ApiPropertyOptional({ description: 'Besoin de consignes audio' })
  @IsOptional()
  @IsBoolean()
  @Type(() => Boolean)
  needsAudioGuidance?: boolean;

  @ApiPropertyOptional({ description: 'Besoin de repères visuels / aide visuelle' })
  @IsOptional()
  @IsBoolean()
  @Type(() => Boolean)
  needsVisualSupport?: boolean;

  @ApiPropertyOptional({ description: 'Besoin d’aide physique sur place' })
  @IsOptional()
  @IsBoolean()
  @Type(() => Boolean)
  needsPhysicalAssistance?: boolean;

  @ApiPropertyOptional({ description: 'Langage simple souhaité' })
  @IsOptional()
  @IsBoolean()
  @Type(() => Boolean)
  needsSimpleLanguage?: boolean;

  @ApiPropertyOptional({
    description: 'Demande formulée pour une autre personne (accompagnant)',
  })
  @IsOptional()
  @IsBoolean()
  @Type(() => Boolean)
  isForAnotherPerson?: boolean;

  @ApiPropertyOptional({
    description:
      'Clé de message prédéfini (ex. blocked, lost) — voir HelpRequestMessageBuilderService',
  })
  @IsOptional()
  @IsString()
  presetMessageKey?: string;
}
