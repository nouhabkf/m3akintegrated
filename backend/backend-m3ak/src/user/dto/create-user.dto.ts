import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsEmail,
  IsEnum,
  IsOptional,
  IsString,
  IsBoolean,
  IsNumber,
  MinLength,
  MaxLength,
} from 'class-validator';
import { Role } from '../enums/role.enum';

export class CreateUserDto {
  @ApiProperty({ description: 'Nom de famille', minLength: 2, maxLength: 50 })
  @IsString()
  @MinLength(2, { message: 'Le nom doit contenir entre 2 et 50 caractères' })
  @MaxLength(50)
  nom: string;

  @ApiProperty({ description: 'Prénom', minLength: 2, maxLength: 50 })
  @IsString()
  @MinLength(2, { message: 'Le prénom doit contenir entre 2 et 50 caractères' })
  @MaxLength(50)
  prenom: string;

  @ApiProperty({ description: 'Email unique' })
  @IsEmail({}, { message: 'Email invalide' })
  email: string;

  @ApiProperty({ description: 'Mot de passe', minLength: 6 })
  @IsString()
  @MinLength(6, { message: 'Le mot de passe doit contenir au moins 6 caractères' })
  password: string;

  @ApiPropertyOptional({ description: 'Téléphone' })
  @IsOptional()
  @IsString()
  telephone?: string;

  @ApiProperty({ enum: Role, description: 'Rôle utilisateur' })
  @IsEnum(Role)
  role: Role;

  @ApiPropertyOptional({ description: 'Type de handicap (pour HANDICAPE)' })
  @IsOptional()
  @IsString()
  typeHandicap?: string;

  @ApiPropertyOptional({ description: 'Besoins spécifiques' })
  @IsOptional()
  @IsString()
  besoinSpecifique?: string;

  @ApiPropertyOptional({ description: 'Animal d\'assistance', default: false })
  @IsOptional()
  @IsBoolean()
  animalAssistance?: boolean;

  @ApiPropertyOptional({ description: 'Type d\'accompagnant (pour ACCOMPAGNANT)' })
  @IsOptional()
  @IsString()
  typeAccompagnant?: string;

  @ApiPropertyOptional({ description: 'Spécialisation (pour ACCOMPAGNANT)' })
  @IsOptional()
  @IsString()
  specialisation?: string;

  @ApiPropertyOptional({ description: 'Disponible', default: false })
  @IsOptional()
  @IsBoolean()
  disponible?: boolean;

  @ApiPropertyOptional({ description: 'Langue préférée (ar, fr)', default: 'fr' })
  @IsOptional()
  @IsString()
  langue?: string;

  @ApiPropertyOptional({ description: 'Statut', default: 'ACTIF' })
  @IsOptional()
  @IsString()
  statut?: string;
}
