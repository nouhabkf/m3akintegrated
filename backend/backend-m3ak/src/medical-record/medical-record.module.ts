import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { MedicalRecordController } from './medical-record.controller';
import { MedicalRecordService } from './medical-record.service';
import { UserModule } from '../user/user.module';
import { MedicalRecord, MedicalRecordSchema } from './schemas/medical-record.schema';
import { EmergencyContactModule } from '../emergency-contact/emergency-contact.module';

@Module({
  imports: [
    UserModule,
    EmergencyContactModule,
    MongooseModule.forFeature([
      { name: MedicalRecord.name, schema: MedicalRecordSchema },
    ]),
  ],
  controllers: [MedicalRecordController],
  providers: [MedicalRecordService],
  exports: [MedicalRecordService],
})
export class MedicalRecordModule {}
