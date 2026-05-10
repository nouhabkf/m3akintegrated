import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { EmergencyContactController } from './emergency-contact.controller';
import { EmergencyContactService } from './emergency-contact.service';
import { EmergencyContact, EmergencyContactSchema } from './schemas/emergency-contact.schema';
import { UserModule } from '../user/user.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: EmergencyContact.name, schema: EmergencyContactSchema },
    ]),
    UserModule,
  ],
  controllers: [EmergencyContactController],
  providers: [EmergencyContactService],
  exports: [EmergencyContactService],
})
export class EmergencyContactModule {}
