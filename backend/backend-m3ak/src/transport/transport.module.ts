import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { HttpModule } from '@nestjs/axios';
import { TransportController } from './transport.controller';
import { TransportService } from './transport.service';
import { TransportRequest, TransportRequestSchema } from './schemas/transport-request.schema';
import { UserModule } from '../user/user.module';
import { MapModule } from '../map/map.module';
import { NotificationModule } from '../notification/notification.module';
import { MobiliteCoreModule } from '../mobilite/mobilite-core.module';
import { TransportGateway } from '../mobilite/transport/transport.gateway';
import { TransportShareRateLimitService } from './transport-share-rate-limit.service';
import { AuthModule } from '../auth/auth.module';
import { Vehicle, VehicleSchema } from '../vehicle/schemas/vehicle.schema';
import {
  VehicleReservation,
  VehicleReservationSchema,
} from '../vehicle-reservation/schemas/vehicle-reservation.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: TransportRequest.name, schema: TransportRequestSchema },
      { name: Vehicle.name, schema: VehicleSchema },
      { name: VehicleReservation.name, schema: VehicleReservationSchema },
    ]),
    HttpModule.register({ timeout: 10000 }),
    MobiliteCoreModule,
    AuthModule,
    UserModule,
    MapModule,
    NotificationModule,
  ],
  controllers: [TransportController],
  providers: [TransportService, TransportGateway, TransportShareRateLimitService],
  exports: [TransportService],
})
export class TransportModule {}
