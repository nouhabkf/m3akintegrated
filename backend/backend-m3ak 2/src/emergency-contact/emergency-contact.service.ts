import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { EmergencyContact, EmergencyContactDocument } from './schemas/emergency-contact.schema';
import { CreateEmergencyContactDto } from './dto/create-emergency-contact.dto';
import { UserService } from '../user/user.service';
import { Role } from '../user/enums/role.enum';

@Injectable()
export class EmergencyContactService {
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

    return this.emergencyContactModel.create({
      userId: new Types.ObjectId(userId),
      accompagnantId: new Types.ObjectId(dto.accompagnantId),
      ordrePriorite: dto.ordrePriorite,
    });
  }

  async findByUser(userId: string) {
    return this.emergencyContactModel
      .find({ userId: new Types.ObjectId(userId) })
      .populate('accompagnantId', '-password')
      .sort({ ordrePriorite: 1 })
      .exec();
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
