import { ApiProperty } from '@nestjs/swagger';
import { IsEnum } from 'class-validator';
import { TransportStatut } from '../enums/transport-statut.enum';

export class UpdateTransportStatutDto {
  @ApiProperty({ enum: TransportStatut, description: 'Nouveau statut du transport' })
  @IsEnum(TransportStatut)
  statut: TransportStatut;
}
