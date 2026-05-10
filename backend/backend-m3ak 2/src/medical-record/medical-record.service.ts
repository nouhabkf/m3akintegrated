import {
  Injectable,
  ConflictException,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { MedicalRecord, MedicalRecordDocument } from './schemas/medical-record.schema';
import { CreateMedicalRecordDto } from './dto/create-medical-record.dto';
import { UpdateMedicalRecordDto } from './dto/update-medical-record.dto';
import { UserService } from '../user/user.service';
import { Role } from '../user/enums/role.enum';

@Injectable()
export class MedicalRecordService {
  constructor(
    @InjectModel(MedicalRecord.name) private medicalRecordModel: Model<MedicalRecordDocument>,
    private userService: UserService,
  ) {}

  async create(createDto: CreateMedicalRecordDto, requestingUserId: string) {
    const user = await this.userService.findByIdWithPassword(requestingUserId);
    if (!user) throw new NotFoundException('Utilisateur non trouvé');
    if (user.role !== Role.HANDICAPE) {
      throw new ForbiddenException('Seuls les utilisateurs HANDICAPE peuvent avoir un dossier médical');
    }

    const existing = await this.medicalRecordModel.findOne({ userId: new Types.ObjectId(requestingUserId) }).exec();
    if (existing) {
      throw new ConflictException('Un dossier médical existe déjà pour cet utilisateur');
    }

    const record = await this.medicalRecordModel.create({
      ...createDto,
      userId: new Types.ObjectId(requestingUserId),
    });
    return record;
  }

  async findByUserId(userId: string, requestingUserId: string) {
    const record = await this.medicalRecordModel.findOne({ userId: new Types.ObjectId(userId) }).exec();
    if (!record) throw new NotFoundException('Dossier médical non trouvé');
    if (record.userId.toString() !== requestingUserId) {
      throw new ForbiddenException('Accès non autorisé à ce dossier médical');
    }
    return record;
  }

  async update(userId: string, updateDto: UpdateMedicalRecordDto, requestingUserId: string) {
    if (userId !== requestingUserId) {
      throw new ForbiddenException('Vous ne pouvez modifier que votre propre dossier médical');
    }
    const record = await this.medicalRecordModel
      .findOneAndUpdate(
        { userId: new Types.ObjectId(userId) },
        { $set: { ...updateDto, updatedAt: new Date() } },
        { new: true },
      )
      .exec();
    if (!record) throw new NotFoundException('Dossier médical non trouvé');
    return record;
  }
}
