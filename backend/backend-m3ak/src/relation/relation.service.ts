import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Relation, RelationDocument, RelationStatut } from './schemas/relation.schema';
import { CreateRelationDto } from './dto/create-relation.dto';
import { UserService } from '../user/user.service';
import { Role } from '../user/enums/role.enum';

@Injectable()
export class RelationService {
  constructor(
    @InjectModel(Relation.name) private relationModel: Model<RelationDocument>,
    private userService: UserService,
  ) {}

  /**
   * Créer une demande de liaison.
   * - Si l'appelant est HANDICAPE : il fournit accompagnantId.
   * - Si l'appelant est ACCOMPAGNANT : il fournit handicapId.
   */
  async create(userId: string, userRole: Role, dto: CreateRelationDto) {
    let handicapId: string;
    let accompagnantId: string;

    if (userRole === Role.HANDICAPE) {
      if (!dto.accompagnantId) {
        throw new BadRequestException('accompagnantId est requis pour un handicapé');
      }
      handicapId = userId;
      accompagnantId = dto.accompagnantId;
    } else if (userRole === Role.ACCOMPAGNANT) {
      if (!dto.handicapId) {
        throw new BadRequestException('handicapId est requis pour un accompagnant');
      }
      handicapId = dto.handicapId;
      accompagnantId = userId;
    } else {
      throw new ForbiddenException('Seuls HANDICAPE et ACCOMPAGNANT peuvent créer une relation');
    }

    const handicap = await this.userService.findByIdWithPassword(handicapId);
    const accompagnant = await this.userService.findByIdWithPassword(accompagnantId);
    if (!handicap) throw new NotFoundException('Handicapé non trouvé');
    if (!accompagnant) throw new NotFoundException('Accompagnant non trouvé');
    if (handicap.role !== Role.HANDICAPE) {
      throw new BadRequestException('L\'utilisateur cible doit être un handicapé');
    }
    if (accompagnant.role !== Role.ACCOMPAGNANT) {
      throw new BadRequestException('L\'utilisateur cible doit être un accompagnant');
    }

    const existing = await this.relationModel
      .findOne({
        handicapId: new Types.ObjectId(handicapId),
        accompagnantId: new Types.ObjectId(accompagnantId),
      })
      .exec();
    if (existing) {
      if (existing.statut === RelationStatut.ACCEPTEE) {
        throw new BadRequestException('Cette liaison existe déjà');
      }
      return existing;
    }

    return this.relationModel.create({
      handicapId: new Types.ObjectId(handicapId),
      accompagnantId: new Types.ObjectId(accompagnantId),
      statut: RelationStatut.EN_ATTENTE,
    });
  }

  /** Accepter une demande de liaison (l'autre partie accepte). */
  async accept(relationId: string, userId: string) {
    const relation = await this.relationModel.findById(relationId).exec();
    if (!relation) throw new NotFoundException('Relation non trouvée');

    const handicapIdStr = relation.handicapId.toString();
    const accompagnantIdStr = relation.accompagnantId.toString();
    if (userId !== handicapIdStr && userId !== accompagnantIdStr) {
      throw new ForbiddenException('Vous ne pouvez pas accepter cette relation');
    }

    if (relation.statut === RelationStatut.ACCEPTEE) {
      return relation;
    }

    return this.relationModel
      .findByIdAndUpdate(
        relationId,
        { $set: { statut: RelationStatut.ACCEPTEE } },
        { new: true },
      )
      .populate('handicapId', '-password')
      .populate('accompagnantId', '-password')
      .exec();
  }

  /** Supprimer une liaison (l'un ou l'autre peut rompre). */
  async remove(relationId: string, userId: string) {
    const relation = await this.relationModel.findById(relationId).exec();
    if (!relation) throw new NotFoundException('Relation non trouvée');

    const handicapIdStr = relation.handicapId.toString();
    const accompagnantIdStr = relation.accompagnantId.toString();
    if (userId !== handicapIdStr && userId !== accompagnantIdStr) {
      throw new ForbiddenException('Vous ne pouvez pas supprimer cette relation');
    }

    await this.relationModel.findByIdAndDelete(relationId).exec();
    return { message: 'Relation supprimée' };
  }

  /** Liste des accompagnants liés à un handicapé (pour l'handicapé ou pour un tiers). */
  async findAccompagnantsByHandicape(handicapId: string, acceptedOnly = false) {
    const filter: Record<string, unknown> = { handicapId: new Types.ObjectId(handicapId) };
    if (acceptedOnly) filter.statut = RelationStatut.ACCEPTEE;

    return this.relationModel
      .find(filter)
      .populate('accompagnantId', '-password')
      .sort({ updatedAt: -1 })
      .exec();
  }

  /** Liste des handicapés liés à un accompagnant (pour l'accompagnant ou pour un tiers). */
  async findHandicapesByAccompagnant(accompagnantId: string, acceptedOnly = false) {
    const filter: Record<string, unknown> = {
      accompagnantId: new Types.ObjectId(accompagnantId),
    };
    if (acceptedOnly) filter.statut = RelationStatut.ACCEPTEE;

    return this.relationModel
      .find(filter)
      .populate('handicapId', '-password')
      .sort({ updatedAt: -1 })
      .exec();
  }

  /** Mes relations : selon le rôle, retourne mes accompagnants ou mes handicapés. */
  async findMyRelations(userId: string, userRole: Role, acceptedOnly?: boolean) {
    if (userRole === Role.HANDICAPE) {
      return this.findAccompagnantsByHandicape(userId, acceptedOnly ?? false);
    }
    if (userRole === Role.ACCOMPAGNANT) {
      return this.findHandicapesByAccompagnant(userId, acceptedOnly ?? false);
    }
    return [];
  }

  /** Détail d'une relation par ID. */
  async findById(relationId: string, userId: string) {
    const relation = await this.relationModel
      .findById(relationId)
      .populate('handicapId', '-password')
      .populate('accompagnantId', '-password')
      .exec();
    if (!relation) throw new NotFoundException('Relation non trouvée');

    const handicapIdStr = this.getIdFromRef(relation.handicapId);
    const accompagnantIdStr = this.getIdFromRef(relation.accompagnantId);
    if (userId !== handicapIdStr && userId !== accompagnantIdStr) {
      throw new ForbiddenException('Accès refusé à cette relation');
    }
    return relation;
  }

  private getIdFromRef(ref: Types.ObjectId | { _id?: Types.ObjectId }): string {
    if (ref && typeof ref === 'object' && ref !== null && '_id' in ref) {
      return (ref as { _id: Types.ObjectId })._id.toString();
    }
    return (ref as Types.ObjectId).toString();
  }
}
