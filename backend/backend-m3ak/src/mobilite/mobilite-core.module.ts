import { Module } from '@nestjs/common';
import { ChauffeurSolidaireGuard } from './guards/chauffeur-solidaire.guard';

/**
 * Noyau mobilité : garde réutilisable. Les constantes partagées vivent dans
 * `mobilite.constants.ts` (ex. CHAUFFEURS_SOLIDAIRES_TYPE) — import direct pour
 * éviter les cycles avec UserModule.
 */
@Module({
  providers: [ChauffeurSolidaireGuard],
  exports: [ChauffeurSolidaireGuard],
})
export class MobiliteCoreModule {}
