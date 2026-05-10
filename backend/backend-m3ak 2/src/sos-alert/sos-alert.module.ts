import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { SosAlertController } from './sos-alert.controller';
import { SosAlertService } from './sos-alert.service';
import { SosAlert, SosAlertSchema } from './schemas/sos-alert.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: SosAlert.name, schema: SosAlertSchema },
    ]),
  ],
  controllers: [SosAlertController],
  providers: [SosAlertService],
  exports: [SosAlertService],
})
export class SosAlertModule {}
