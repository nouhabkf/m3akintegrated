import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { LieuReservationController } from './lieu-reservation.controller';
import { LieuReservationService } from './lieu-reservation.service';
import { LieuReservation, LieuReservationSchema } from './schemas/lieu-reservation.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: LieuReservation.name, schema: LieuReservationSchema },
    ]),
  ],
  controllers: [LieuReservationController],
  providers: [LieuReservationService],
  exports: [LieuReservationService],
})
export class LieuReservationModule {}
