import { Module } from '@nestjs/common';
import { MedicalRecordModule } from '../medical-record/medical-record.module';
import { SosAlertModule } from '../sos-alert/sos-alert.module';
import { EmergencyContactModule } from '../emergency-contact/emergency-contact.module';
import { CommunityModule } from '../community/community.module';

/**
 * Domaine santé & social (fusion backend collègue) :
 * dossier médical, SOS, contacts d'urgence, communauté.
 */
@Module({
  imports: [
    MedicalRecordModule,
    SosAlertModule,
    EmergencyContactModule,
    CommunityModule,
  ],
  exports: [
    MedicalRecordModule,
    SosAlertModule,
    EmergencyContactModule,
    CommunityModule,
  ],
})
export class SanteModule {}
