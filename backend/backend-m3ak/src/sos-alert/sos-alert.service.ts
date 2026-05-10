import { Injectable, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { SosAlert, SosAlertDocument } from './schemas/sos-alert.schema';
import { CreateSosAlertDto } from './dto/create-sos-alert.dto';
import { EmergencyContactService } from '../emergency-contact/emergency-contact.service';
import { NotificationService } from '../notification/notification.service';
import {
  SosAlertRecipient,
  SosAlertRecipientDocument,
} from './schemas/sos-alert-recipient.schema';
import { SosAlertGateway } from './sos-alert.gateway';

@Injectable()
export class SosAlertService {
  private readonly logger = new Logger(SosAlertService.name);

  constructor(
    @InjectModel(SosAlert.name) private sosAlertModel: Model<SosAlertDocument>,
    @InjectModel(SosAlertRecipient.name)
    private sosAlertRecipientModel: Model<SosAlertRecipientDocument>,
    private readonly emergencyContactService: EmergencyContactService,
    private readonly notificationService: NotificationService,
    private readonly sosAlertGateway: SosAlertGateway,
  ) {}

  async create(userId: string, dto: CreateSosAlertDto) {
    const alert = await this.sosAlertModel.create({
      userId: new Types.ObjectId(userId),
      latitude: dto.latitude,
      longitude: dto.longitude,
      statut: 'ENVOYEE',
      voiceScore: dto.voiceScore,
      voiceLabel: dto.voiceLabel,
      voiceLabelFr: dto.voiceLabelFr,
      alertSource: dto.alertSource,
      beneficiaryTypeHandicap: dto.beneficiaryTypeHandicap,
      beneficiaryBesoinSpecifique: dto.beneficiaryBesoinSpecifique,
    });

    const accompagnantIds =
      await this.emergencyContactService.listAccompagnantIdsForUser(userId);
    const alertId = alert._id.toString();
    const pos = `Position : ${dto.latitude.toFixed(5)}, ${dto.longitude.toFixed(5)}`;

    for (const accId of accompagnantIds) {
      try {
        await this.sosAlertRecipientModel.updateOne(
          {
            alertId: alert._id,
            accompagnantId: new Types.ObjectId(accId),
          },
          {
            $setOnInsert: {
              beneficiaryId: new Types.ObjectId(userId),
              notifiedAt: new Date(),
            },
          },
          { upsert: true },
        );

        await this.notificationService.notifyDriver(
          accId,
          'Alerte SOS',
          `Un utilisateur vous a désigné comme contact d’urgence et a déclenché une alerte. ${pos}`,
          'SOS_ALERT',
          alertId,
        );

        this.sosAlertGateway.emitSosCreatedForAccompagnant(accId, {
          alertId,
          beneficiaryId: userId,
          statut: alert.statut,
          latitude: alert.latitude,
          longitude: alert.longitude,
          voiceScore: alert.voiceScore,
          voiceLabel: alert.voiceLabel,
          voiceLabelFr: alert.voiceLabelFr,
          alertSource: alert.alertSource,
          createdAt: alert.createdAt,
        });
      } catch (err: unknown) {
        this.logger.error(
          err instanceof Error ? err.message : `Notification SOS échouée pour ${accId}`,
        );
      }
    }

    return alert;
  }

  async findForAccompagnant(accompagnantId: string) {
    const assignments = await this.sosAlertRecipientModel
      .find({ accompagnantId: new Types.ObjectId(accompagnantId) })
      .sort({ createdAt: -1 })
      .populate({
        path: 'alertId',
        populate: { path: 'userId', select: '-password' },
      })
      .limit(200)
      .lean()
      .exec();

    if (assignments.length) {
      return assignments
        .map((item) => item.alertId)
        .filter(Boolean)
        .sort((a, b) => {
          const da = new Date((a as { createdAt?: Date }).createdAt ?? 0).getTime();
          const db = new Date((b as { createdAt?: Date }).createdAt ?? 0).getTime();
          return db - da;
        });
    }

    // Compat rétroactive: pour les anciennes alertes sans assignation persistée.
    const beneficiaryIds =
      await this.emergencyContactService.findBeneficiaryUserIdsForAccompagnant(
        accompagnantId,
      );
    if (!beneficiaryIds.length) return [];

    return this.sosAlertModel
      .find({ userId: { $in: beneficiaryIds } })
      .populate('userId', '-password')
      .sort({ createdAt: -1 })
      .limit(100)
      .exec();
  }

  async findByUser(userId: string) {
    return this.sosAlertModel
      .find({ userId: new Types.ObjectId(userId) })
      .sort({ createdAt: -1 })
      .exec();
  }

  async findNearby(latitude: number, longitude: number, maxDistanceKm = 10) {
    return this.sosAlertModel
      .find({
        latitude: { $gte: latitude - 0.1, $lte: latitude + 0.1 },
        longitude: { $gte: longitude - 0.1, $lte: longitude + 0.1 },
        statut: 'ENVOYEE',
      })
      .populate('userId', '-password')
      .sort({ createdAt: -1 })
      .limit(50)
      .exec();
  }

  async updateStatut(alertId: string, statut: string) {
    return this.sosAlertModel
      .findByIdAndUpdate(alertId, { $set: { statut } }, { new: true })
      .exec();
  }
}
