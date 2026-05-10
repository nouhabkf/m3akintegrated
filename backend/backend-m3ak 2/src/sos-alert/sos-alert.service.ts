import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { SosAlert, SosAlertDocument } from './schemas/sos-alert.schema';
import { CreateSosAlertDto } from './dto/create-sos-alert.dto';

@Injectable()
export class SosAlertService {
  constructor(
    @InjectModel(SosAlert.name) private sosAlertModel: Model<SosAlertDocument>,
  ) {}

  async create(userId: string, dto: CreateSosAlertDto) {
    return this.sosAlertModel.create({
      userId: new Types.ObjectId(userId),
      latitude: dto.latitude,
      longitude: dto.longitude,
      statut: 'ENVOYEE',
    });
  }

  async findByUser(userId: string) {
    return this.sosAlertModel
      .find({ userId: new Types.ObjectId(userId) })
      .populate('responderUserId', '-password')
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

  /** Un autre utilisateur prend l’alerte : statut → EN_ROUTE. */
  async respondToAlert(alertId: string, responderUserId: string) {
    const alert = await this.sosAlertModel.findById(alertId).exec();
    if (!alert) throw new NotFoundException('Alerte introuvable');
    if (alert.userId.toString() === responderUserId) {
      throw new BadRequestException('Vous ne pouvez pas répondre à votre propre alerte');
    }
    if (alert.statut !== 'ENVOYEE') {
      throw new BadRequestException('Cette alerte a déjà été prise en charge ou n’est plus disponible');
    }
    return this.sosAlertModel
      .findByIdAndUpdate(
        alertId,
        {
          $set: {
            statut: 'EN_ROUTE',
            responderUserId: new Types.ObjectId(responderUserId),
          },
        },
        { new: true },
      )
      .populate('userId', '-password')
      .populate('responderUserId', '-password')
      .exec();
  }
}
