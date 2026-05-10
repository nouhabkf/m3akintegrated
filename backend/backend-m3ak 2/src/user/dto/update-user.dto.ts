import { ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsEnum,
  IsOptional,
  IsString,
  IsBoolean,
  MinLength,
  MaxLength,
} from 'class-validator';
import { Role } from '../enums/role.enum';

export class UpdateUserDto {
  @ApiPropertyOptional({ description: 'Nom de famille', minLength: 2, maxLength: 50 })
  @IsOptional()
  @IsString()
  @MinLength(2)
  @MaxLength(50)
  nom?: string;

  @ApiPropertyOptional({ description: 'Prénom', minLength: 2, maxLength: 50 })
  @IsOptional()
  @IsString()
  @MinLength(2)
  @MaxLength(50)
  prenom?: string;

  @ApiPropertyOptional({ description: 'Téléphone' })
  @IsOptional()
  @IsString()
  telephone?: string;

  @ApiPropertyOptional({ enum: Role, description: 'Rôle utilisateur' })
  @IsOptional()
  @IsEnum(Role)
  role?: Role;

  @ApiPropertyOptional({ description: 'Type de handicap' })
  @IsOptional()
  @IsString()
  typeHandicap?: string;

  @ApiPropertyOptional({ description: 'Besoins spécifiques' })
  @IsOptional()
  @IsString()
  besoinSpecifique?: string;

  @ApiPropertyOptional({ description: 'Animal d\'assistance' })
  @IsOptional()
  @IsBoolean()
  animalAssistance?: boolean;

  @ApiPropertyOptional({ description: 'Type d\'accompagnant' })
  @IsOptional()
  @IsString()
  typeAccompagnant?: string;

  @ApiPropertyOptional({ description: 'Spécialisation' })
  @IsOptional()
  @IsString()
  specialisation?: string;

  @ApiPropertyOptional({ description: 'Disponible' })
  @IsOptional()
  @IsBoolean()
  disponible?: boolean;

  @ApiPropertyOptional({ description: 'Langue préférée' })
  @IsOptional()
  @IsString()
  langue?: string;

  @ApiPropertyOptional({ description: 'Statut' })
  @IsOptional()
  @IsString()
  statut?: string;

  @ApiPropertyOptional({ description: 'Badge partenaire (compte institutionnel labellisé)' })
  @IsOptional()
  @IsBoolean()
  partenaire?: boolean;
}
