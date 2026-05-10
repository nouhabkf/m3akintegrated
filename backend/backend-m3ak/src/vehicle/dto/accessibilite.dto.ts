import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsOptional } from 'class-validator';

export class AccessibiliteDto {
  @ApiPropertyOptional({ description: 'Coffre vaste', default: false })
  @IsOptional()
  @IsBoolean()
  coffreVaste?: boolean;

  @ApiPropertyOptional({ description: 'Rampe d\'accès', default: false })
  @IsOptional()
  @IsBoolean()
  rampeAcces?: boolean;

  @ApiPropertyOptional({ description: 'Siège pivotant', default: false })
  @IsOptional()
  @IsBoolean()
  siegePivotant?: boolean;

  @ApiPropertyOptional({ description: 'Climatisation', default: false })
  @IsOptional()
  @IsBoolean()
  climatisation?: boolean;

  @ApiPropertyOptional({ description: 'Animal accepté', default: false })
  @IsOptional()
  @IsBoolean()
  animalAccepte?: boolean;
}
