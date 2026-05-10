import { Module } from '@nestjs/common';
import { MobiliteCoreModule } from './mobilite-core.module';
import { TransportModule } from '../transport/transport.module';
import { TransportReviewModule } from '../transport-review/transport-review.module';
import { VehicleModule } from '../vehicle/vehicle.module';
import { VehicleReservationModule } from '../vehicle-reservation/vehicle-reservation.module';

/**
 * MobiliteModule — agrégateur du domaine mobilité Ma3ak :
 * Transport, TransportReview, Vehicle, VehicleReservation (une seule entrée dans AppModule).
 *
 * Règle produit « chauffeur solidaire » : `CHAUFFEURS_SOLIDAIRES_TYPE` dans mobilite.constants.ts,
 * appliquée par ChauffeurSolidaireGuard (routes transport sensibles) et côté services (matching, accept).
 *
 * Vehicle n’est enregistré qu’une fois (VehicleModule) ; VehicleReservationModule importe VehicleModule.
 */
@Module({
  imports: [
    MobiliteCoreModule,
    TransportModule,
    TransportReviewModule,
    VehicleModule,
    VehicleReservationModule,
  ],
  exports: [
    MobiliteCoreModule,
    TransportModule,
    TransportReviewModule,
    VehicleModule,
    VehicleReservationModule,
  ],
})
export class MobiliteModule {}
