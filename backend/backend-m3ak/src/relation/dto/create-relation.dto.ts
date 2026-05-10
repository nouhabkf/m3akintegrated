import { ApiProperty } from '@nestjs/swagger';
import { IsMongoId } from 'class-validator';

export class CreateRelationDto {
  @ApiProperty({
    description:
      "ID de l'accompagnant à lier (à fournir si l'appelant est un HANDICAPE)",
  })
  @IsMongoId()
  accompagnantId?: string;

  @ApiProperty({
    description:
      "ID de l'handicapé à lier (à fournir si l'appelant est un ACCOMPAGNANT)",
  })
  @IsMongoId()
  handicapId?: string;
}
