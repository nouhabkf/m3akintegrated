import { IsOptional, IsString } from 'class-validator';

export class GuidanceSessionDto {
  /// Optionnel: hint de device/platform (web/android/ios)
  @IsOptional()
  @IsString()
  clientHint?: string;
}

