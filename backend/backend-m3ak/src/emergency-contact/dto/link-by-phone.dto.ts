import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString } from 'class-validator';

export class LinkByPhoneDto {
  @ApiProperty({
    example: '+21655000001',
    description: 'Numéro du compte accompagnant Ma3ak (profil)',
  })
  @IsString()
  @IsNotEmpty()
  telephone: string;
}
