import { IsBase64, IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class GuidanceFrameDto {
  @IsString()
  @IsNotEmpty()
  sessionId!: string;

  /// JPEG/PNG encodé en base64 (sans prefix "data:image/...;base64,")
  @IsString()
  @IsNotEmpty()
  @IsBase64()
  imageBase64!: string;

  /// Timestamp côté client (ms)
  @IsOptional()
  clientTs?: number;
}

