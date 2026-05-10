import { ApiProperty } from '@nestjs/swagger';
import { IsEnum } from 'class-validator';

/** Statuts métier réservation véhicule (aligné schéma Mongo). */
export enum VehicleReservationStatutDto {
  EN_ATTENTE = 'EN_ATTENTE',
  CONFIRMEE = 'CONFIRMEE',
  ANNULEE = 'ANNULEE',
  TERMINEE = 'TERMINEE',
}

export class UpdateVehicleReservationStatutDto {
  @ApiProperty({
    enum: VehicleReservationStatutDto,
    description: 'Nouveau statut de la réservation',
  })
  @IsEnum(VehicleReservationStatutDto)
  statut: VehicleReservationStatutDto;
}
