import { ApiProperty } from '@nestjs/swagger';
import { IsISO8601, IsOptional, IsString, MinLength } from 'class-validator';

export class PublishMedicalQrDto {
  @ApiProperty({
    description: 'Payload QR médical hors ligne',
    example: 'MA3AK_MEDICAL_RECORD_V1\nupdatedAt:2026-04-27T11:00:00.000Z\n...',
  })
  @IsString()
  @MinLength(8)
  qrPayload: string;

  @ApiProperty({
    required: false,
    description: 'Date de mise à jour du QR (ISO8601)',
    example: '2026-04-27T11:00:00.000Z',
  })
  @IsOptional()
  @IsISO8601()
  qrUpdatedAt?: string;
}
