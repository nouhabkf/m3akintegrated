import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { JwtModule } from '@nestjs/jwt';
import { SosAlertController } from './sos-alert.controller';
import { SosAlertService } from './sos-alert.service';
import { SosAlert, SosAlertSchema } from './schemas/sos-alert.schema';
import {
  SosAlertRecipient,
  SosAlertRecipientSchema,
} from './schemas/sos-alert-recipient.schema';
import { EmergencyContactModule } from '../emergency-contact/emergency-contact.module';
import { NotificationModule } from '../notification/notification.module';
import { SosAlertGateway } from './sos-alert.gateway';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: SosAlert.name, schema: SosAlertSchema },
      { name: SosAlertRecipient.name, schema: SosAlertRecipientSchema },
    ]),
    JwtModule.register({}),
    EmergencyContactModule,
    NotificationModule,
  ],
  controllers: [SosAlertController],
  providers: [SosAlertService, SosAlertGateway],
  exports: [SosAlertService],
})
export class SosAlertModule {}
