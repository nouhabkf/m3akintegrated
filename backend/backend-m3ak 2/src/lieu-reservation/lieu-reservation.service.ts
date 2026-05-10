import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { LieuReservation, LieuReservationDocument } from './schemas/lieu-reservation.schema';
import { CreateLieuReservationDto } from './dto/create-lieu-reservation.dto';

@Injectable()
export class LieuReservationService {
  constructor(
    @InjectModel(LieuReservation.name) private reservationModel: Model<LieuReservationDocument>,
  ) {}

  async create(userId: string, dto: CreateLieuReservationDto) {
    return this.reservationModel.create({
      userId: new Types.ObjectId(userId),
      lieuId: new Types.ObjectId(dto.lieuId),
      date: new Date(dto.date),
      heure: dto.heure,
      besoinsSpecifiques: dto.besoinsSpecifiques ?? null,
      qrCode: `QR-${Date.now()}-${userId.slice(-4)}`,
      statut: 'EN_ATTENTE',
    });
  }

  async findByUser(userId: string) {
    return this.reservationModel
      .find({ userId: new Types.ObjectId(userId) })
      .populate('lieuId')
      .sort({ date: -1 })
      .exec();
  }

  async findByLieu(lieuId: string) {
    return this.reservationModel
      .find({ lieuId: new Types.ObjectId(lieuId) })
      .populate('userId', '-password')
      .sort({ date: -1 })
      .exec();
  }

  async updateStatut(reservationId: string, statut: string) {
    const res = await this.reservationModel
      .findByIdAndUpdate(reservationId, { $set: { statut } }, { new: true })
      .exec();
    if (!res) throw new NotFoundException('Réservation non trouvée');
    return res;
  }
}
