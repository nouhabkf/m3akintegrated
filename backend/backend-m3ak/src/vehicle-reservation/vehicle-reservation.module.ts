import { Module, forwardRef } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { VehicleReservationController } from './vehicle-reservation.controller';
import { VehicleReservationService } from './vehicle-reservation.service';
import { VehicleReservation, VehicleReservationSchema } from './schemas/vehicle-reservation.schema';
import { VehicleReservationReview, VehicleReservationReviewSchema } from './schemas/vehicle-reservation-review.schema';
import { VehicleModule } from '../vehicle/vehicle.module';
import { TransportModule } from '../transport/transport.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: VehicleReservation.name, schema: VehicleReservationSchema },
      { name: VehicleReservationReview.name, schema: VehicleReservationReviewSchema },
    ]),
    VehicleModule,
    forwardRef(() => TransportModule),
  ],
  controllers: [VehicleReservationController],
  providers: [VehicleReservationService],
  exports: [VehicleReservationService],
})
export class VehicleReservationModule {}
