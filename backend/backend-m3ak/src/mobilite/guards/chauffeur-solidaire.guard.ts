import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { UserDocument } from '../../user/schemas/user.schema';
import { Role } from '../../user/enums/role.enum';
import { CHAUFFEURS_SOLIDAIRES_TYPE } from '../mobilite.constants';

/**
 * Accès réservé aux accompagnants enregistrés comme « Chauffeurs solidaires »
 * (même règle que validation statut véhicule / hub demandes ouvertes).
 */
@Injectable()
export class ChauffeurSolidaireGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const req = context.switchToHttp().getRequest<{ user?: UserDocument }>();
    const user = req.user;
    if (!user) {
      throw new ForbiddenException('Authentification requise');
    }
    if (user.role !== Role.ACCOMPAGNANT) {
      throw new ForbiddenException('Rôle accompagnant requis');
    }
    if (user.typeAccompagnant !== CHAUFFEURS_SOLIDAIRES_TYPE) {
      throw new ForbiddenException(
        'Cette action est réservée aux accompagnants « Chauffeurs solidaires »',
      );
    }
    return true;
  }
}
