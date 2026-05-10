import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString } from 'class-validator';

export class UpdateMedicalRecordDto {
  @ApiPropertyOptional({ description: 'Groupe sanguin' })
  @IsOptional()
  @IsString()
  groupeSanguin?: string;

  @ApiPropertyOptional({ description: 'Allergies' })
  @IsOptional()
  @IsString()
  allergies?: string;

  @ApiPropertyOptional({ description: 'Maladies chroniques' })
  @IsOptional()
  @IsString()
  maladiesChroniques?: string;

  @ApiPropertyOptional({ description: 'Médicaments' })
  @IsOptional()
  @IsString()
  medicaments?: string;

  @ApiPropertyOptional({ description: 'Médecin traitant' })
  @IsOptional()
  @IsString()
  medecinTraitant?: string;

  @ApiPropertyOptional({ description: 'Contact urgence' })
  @IsOptional()
  @IsString()
  contactUrgence?: string;
}
