import { Injectable, NotFoundException, ForbiddenException, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { EmergencyContact, EmergencyContactDocument } from './schemas/emergency-contact.schema';
import { CreateEmergencyContactDto } from './dto/create-emergency-contact.dto';
import { UserService } from '../user/user.service';
import { Role } from '../user/enums/role.enum';
import { normalizeTunisiaPhone } from '../common/phone.util';

@Injectable()
export class EmergencyContactService {
  private readonly logger = new Logger(EmergencyContactService.name);

  constructor(
    @InjectModel(EmergencyContact.name) private emergencyContactModel: Model<EmergencyContactDocument>,
    private userService: UserService,
  ) {}

  async add(userId: string, dto: CreateEmergencyContactDto) {
    const accompagnant = await this.userService.findByIdWithPassword(dto.accompagnantId);
    if (!accompagnant) throw new NotFoundException('Accompagnant non trouvé');
    if (accompagnant.role !== Role.ACCOMPAGNANT) {
      throw new ForbiddenException('L\'utilisateur cible doit être un accompagnant');
    }

    const existing = await this.emergencyContactModel
      .findOne({
        userId: new Types.ObjectId(userId),
        accompagnantId: accompagnant._id,
      })
      .exec();
    if (existing) {
      return this.emergencyContactModel
        .findById(existing._id)
        .populate('accompagnantId', '-password')
        .exec();
    }

    const created = await this.emergencyContactModel.create({
      userId: new Types.ObjectId(userId),
      accompagnantId: new Types.ObjectId(dto.accompagnantId),
      ordrePriorite: dto.ordrePriorite ?? 1,
    });
    return this.emergencyContactModel
      .findById(created._id)
      .populate('accompagnantId', '-password')
      .exec();
  }

  async addByPhone(userId: string, telephone: string, ordrePriorite = 1) {
    const normalizedPhone = normalizeTunisiaPhone(telephone);
    this.logger.debug(
      JSON.stringify({
        event: 'link_by_phone_attempt',
        userId,
        receivedPhone: telephone,
        normalizedPhone,
        lookup: 'User.role=ACCOMPAGNANT + telephoneNormalized/telephone exact',
      }),
    );

    const accompagnantId = await this.userService.getAccompagnantIdByPhone(telephone);
    if (!accompagnantId) {
      this.logger.debug(
        JSON.stringify({
          event: 'link_by_phone_not_found',
          userId,
          normalizedPhone,
        }),
      );
      throw new NotFoundException(
        'Aucun accompagnant avec ce numéro. Vérifiez le format (+216...).',
      );
    }
    this.logger.debug(
      JSON.stringify({
        event: 'link_by_phone_found',
        userId,
        accompagnantId,
        normalizedPhone,
      }),
    );
    return this.add(userId, {
      accompagnantId,
      ordrePriorite,
    });
  }

  async findByUser(userId: string) {
    return this.emergencyContactModel
      .find({ userId: new Types.ObjectId(userId) })
      .populate('accompagnantId', '-password')
      .sort({ ordrePriorite: 1 })
      .exec();
  }

  /** IDs accompagnants uniques (pour notifications SOS, etc.). */
  async listAccompagnantIdsForUser(userId: string): Promise<string[]> {
    const rows = await this.emergencyContactModel
      .find({ userId: new Types.ObjectId(userId) })
      .select('accompagnantId')
      .lean()
      .exec();
    const ids = new Set<string>();
    for (const r of rows) {
      const id = r.accompagnantId?.toString();
      if (id) ids.add(id);
    }
    return [...ids];
  }

  async findBeneficiaryUserIdsForAccompagnant(
    accompagnantId: string,
  ): Promise<Types.ObjectId[]> {
    return this.emergencyContactModel.distinct('userId', {
      accompagnantId: new Types.ObjectId(accompagnantId),
    }) as Promise<Types.ObjectId[]>;
  }

  async remove(userId: string, contactId: string) {
    const result = await this.emergencyContactModel.findOneAndDelete({
      _id: contactId,
      userId: new Types.ObjectId(userId),
    }).exec();
    if (!result) throw new NotFoundException('Contact urgence non trouvé');
    return { message: 'Contact supprimé' };
  }
}
