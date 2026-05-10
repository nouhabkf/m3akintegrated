import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString } from 'class-validator';

export class UpdateMedicalRecordDto {
  @ApiPropertyOptional({ description: 'Type de handicap' })
  @IsOptional()
  @IsString()
  typeHandicap?: string;

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

  @ApiPropertyOptional({ description: 'Antécédents médicaux importants' })
  @IsOptional()
  @IsString()
  antecedentsImportants?: string;

  @ApiPropertyOptional({ description: 'Médecin traitant' })
  @IsOptional()
  @IsString()
  medecinTraitant?: string;

  @ApiPropertyOptional({ description: 'Coordonnées médecin traitant' })
  @IsOptional()
  @IsString()
  medecinContact?: string;

  @ApiPropertyOptional({ description: 'Contact urgence' })
  @IsOptional()
  @IsString()
  contactUrgence?: string;
}
