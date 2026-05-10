import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsBoolean,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
  ValidateIf,
} from 'class-validator';

export class UpdateAnimalDto {
  @ApiProperty({ description: 'Animal d\'assistance', example: true })
  @IsBoolean()
  animalAssistance: boolean;

  @ApiPropertyOptional({
    description: 'Type d\'animal (obligatoire si animalAssistance est true)',
    example: 'chien',
  })
  @ValidateIf((o: UpdateAnimalDto) => o.animalAssistance === true)
  @IsString()
  @IsNotEmpty({ message: 'animalType est requis lorsque animalAssistance est true' })
  @MaxLength(120)
  animalType?: string;

  @ApiPropertyOptional({ description: 'Nom de l\'animal', example: 'Rex' })
  @IsOptional()
  @IsString()
  @MaxLength(120)
  animalName?: string;

  @ApiPropertyOptional({
    description: 'Notes (comportement, soins, etc.)',
    example: 'chien guide',
  })
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  animalNotes?: string;
}
