import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { DatabaseModule } from './database/database.module';
import { UserModule } from './user/user.module';
import { AuthModule } from './auth/auth.module';
import { AdminModule } from './admin/admin.module';
import { MobiliteModule } from './mobilite/mobilite.module';
import { NotificationModule } from './notification/notification.module';
import { MapModule } from './map/map.module';
import { RelationModule } from './relation/relation.module';
import { SanteModule } from './sante/sante.module';
import { MedicalRecordModule } from './medical-record/medical-record.module';
import { SosAlertModule } from './sos-alert/sos-alert.module';
import { EmergencyContactModule } from './emergency-contact/emergency-contact.module';
import { TransportModule } from './transport/transport.module';
import { TransportReviewModule } from './transport-review/transport-review.module';
import { CommunityModule } from './community/community.module';
import { AccessibilityModule } from './accessibility/accessibility.module';
import { HelpPriorityModule } from './help-priority/help-priority.module';
import { LieuModule } from './lieu/lieu.module';
import { LieuReservationModule } from './lieu-reservation/lieu-reservation.module';
import { M3akLearningModule } from './m3ak-learning/m3ak-learning.module';
import { M3akGuidanceModule } from './m3ak-guidance/m3ak-guidance.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),
    DatabaseModule,
    UserModule,
    AuthModule,
    AdminModule,
    MedicalRecordModule,
    SosAlertModule,
    EmergencyContactModule,
    TransportModule,
    TransportReviewModule,
    CommunityModule,
    LieuModule,
    LieuReservationModule,
    SanteModule,
    MobiliteModule,
    NotificationModule,
    AccessibilityModule,
    HelpPriorityModule,
    M3akLearningModule,
    M3akGuidanceModule,
    MapModule,
    RelationModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
