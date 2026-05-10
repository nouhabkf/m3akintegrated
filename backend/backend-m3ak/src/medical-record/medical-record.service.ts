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
import { EmergencyContactService } from '../emergency-contact/emergency-contact.service';
import { PublishMedicalQrDto } from './dto/publish-medical-qr.dto';

@Injectable()
export class MedicalRecordService {
  constructor(
    @InjectModel(MedicalRecord.name) private medicalRecordModel: Model<MedicalRecordDocument>,
    private userService: UserService,
    private emergencyContactService: EmergencyContactService,
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
    await this.ensureQrPayload(record);
    return this.medicalRecordModel.findById(record._id).exec();
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
    await this.ensureQrPayload(record);
    return this.medicalRecordModel.findById(record._id).exec();
  }

  async publishQr(
    requestingUserId: string,
    dto: PublishMedicalQrDto,
  ): Promise<MedicalRecordDocument> {
    const record = await this.medicalRecordModel
      .findOneAndUpdate(
        { userId: new Types.ObjectId(requestingUserId) },
        {
          $set: {
            qrPayload: dto.qrPayload.trim(),
            qrUpdatedAt: dto.qrUpdatedAt ? new Date(dto.qrUpdatedAt) : new Date(),
            updatedAt: new Date(),
          },
        },
        { new: true },
      )
      .exec();
    if (!record) throw new NotFoundException('Dossier médical non trouvé');
    return record;
  }

  async getForAccompagnant(requestingUserId: string): Promise<any[]> {
    const user = await this.userService.findByIdWithPassword(requestingUserId);
    if (!user) throw new NotFoundException('Utilisateur non trouvé');
    if (user.role !== Role.ACCOMPAGNANT) {
      throw new ForbiddenException(
        'Seuls les accompagnants peuvent consulter les dossiers liés',
      );
    }

    const beneficiaryIds =
      await this.emergencyContactService.findBeneficiaryUserIdsForAccompagnant(
        requestingUserId,
      );
    if (beneficiaryIds.length === 0) return [];

    const records = await this.medicalRecordModel
      .find({
        userId: { $in: beneficiaryIds },
        qrPayload: { $exists: true, $nin: [null, ''] },
      })
      .populate('userId', 'nom prenom')
      .sort({ qrUpdatedAt: -1, updatedAt: -1 })
      .exec();

    return records.map((r: any) => {
      const beneficiary = r.userId as { _id?: Types.ObjectId; nom?: string; prenom?: string };
      const beneficiaryName = `${beneficiary?.prenom ?? ''} ${beneficiary?.nom ?? ''}`.trim();
      return {
        beneficiaryId: beneficiary?._id?.toString() ?? '',
        beneficiaryName: beneficiaryName || 'Bénéficiaire',
        qrPayload: r.qrPayload ?? '',
        groupeSanguin: r.groupeSanguin ?? null,
        allergies: r.allergies ?? null,
        medicaments: r.medicaments ?? null,
        contactUrgence: r.contactUrgence ?? null,
        typeHandicap: r.typeHandicap ?? null,
        updatedAt: r.updatedAt ?? null,
        qrUpdatedAt: r.qrUpdatedAt ?? null,
      };
    });
  }

  private async ensureQrPayload(record: MedicalRecordDocument): Promise<void> {
    const payload = this.buildOfflineQrPayload(record);
    await this.medicalRecordModel
      .findByIdAndUpdate(record._id, {
        $set: {
          qrPayload: payload,
          qrUpdatedAt: record.updatedAt ?? new Date(),
        },
      })
      .exec();
  }

  private buildOfflineQrPayload(record: MedicalRecordDocument): string {
    const clean = (v?: unknown) => {
      const s = (v ?? '').toString().trim().replace(/\s+/g, ' ');
      if (!s) return '';
      return s.length <= 120 ? s : `${s.slice(0, 117)}...`;
    };
    return [
      'MA3AK_MEDICAL_RECORD_V1',
      `updatedAt:${(record.updatedAt ?? new Date()).toISOString()}`,
      `typeHandicap:${clean(record.typeHandicap)}`,
      `groupeSanguin:${clean(record.groupeSanguin)}`,
      `allergies:${clean(record.allergies)}`,
      `maladiesChroniques:${clean(record.maladiesChroniques)}`,
      `medicaments:${clean(record.medicaments)}`,
      `antecedentsImportants:${clean(record.antecedentsImportants)}`,
      `medecinTraitant:${clean(record.medecinTraitant)}`,
      `medecinContact:${clean(record.medecinContact)}`,
      `contactUrgence:${clean(record.contactUrgence)}`,
    ].join('\n');
  }
}
