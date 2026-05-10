import { ApiProperty } from '@nestjs/swagger';
import { IsEnum, IsString, IsNumber, IsDateString } from 'class-validator';
import { TransportType } from '../enums/transport-type.enum';

export class CreateTransportDto {
  @ApiProperty({ enum: TransportType, description: 'Type de transport' })
  @IsEnum(TransportType)
  typeTransport: TransportType;

  @ApiProperty({ description: 'Adresse de départ' })
  @IsString()
  depart: string;

  @ApiProperty({ description: 'Adresse de destination' })
  @IsString()
  destination: string;

  @ApiProperty({ description: 'Latitude départ' })
  @IsNumber()
  latitudeDepart: number;

  @ApiProperty({ description: 'Longitude départ' })
  @IsNumber()
  longitudeDepart: number;

  @ApiProperty({ description: 'Latitude arrivée' })
  @IsNumber()
  latitudeArrivee: number;

  @ApiProperty({ description: 'Longitude arrivée' })
  @IsNumber()
  longitudeArrivee: number;

  @ApiProperty({ description: 'Date et heure (ISO 8601)' })
  @IsDateString()
  dateHeure: string;
}
