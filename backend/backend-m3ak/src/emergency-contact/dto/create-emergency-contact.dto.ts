import { ApiProperty } from '@nestjs/swagger';
import { IsMongoId, IsNumber } from 'class-validator';

export class CreateEmergencyContactDto {
  @ApiProperty({ description: 'ID de l\'accompagnant' })
  @IsMongoId()
  accompagnantId: string;

  @ApiProperty({ description: 'Ordre de priorité (1 = premier)', default: 1 })
  @IsNumber()
  ordrePriorite: number;
}
