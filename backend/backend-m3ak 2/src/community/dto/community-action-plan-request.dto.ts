import { IsBoolean, IsIn, IsOptional, IsString } from 'class-validator';

const CONTEXT_HINTS = ['post', 'help', 'community'] as const;

const INPUT_MODE_HINTS = [
  'keyboard',
  'voice',
  'headEyes',
  'vibration',
  'deafBlind',
  'caregiver',
  'text',
  'tap',
  'haptic',
  'volume_shortcut',
] as const;

export class CommunityActionPlanRequestDto {
  @IsString()
  text!: string;

  @IsOptional()
  @IsIn(CONTEXT_HINTS)
  contextHint?: (typeof CONTEXT_HINTS)[number];

  @IsOptional()
  @IsIn(INPUT_MODE_HINTS)
  inputModeHint?: (typeof INPUT_MODE_HINTS)[number];

  @IsOptional()
  @IsBoolean()
  isForAnotherPersonHint?: boolean;
}

