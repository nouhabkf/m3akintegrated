import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
  Inject,
  forwardRef,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { VehicleReservation, VehicleReservationDocument } from './schemas/vehicle-reservation.schema';
import { TransportService } from '../transport/transport.service';
import { VehicleReservationReview, VehicleReservationReviewDocument } from './schemas/vehicle-reservation-review.schema';
import { CreateVehicleReservationDto } from './dto/create-vehicle-reservation.dto';
import { CreateVehicleReservationReviewDto } from './dto/create-vehicle-reservation-review.dto';
import { Vehicle } from '../vehicle/schemas/vehicle.schema';
import { UserDocument } from '../user/schemas/user.schema';
import { Role } from '../user/enums/role.enum';

const POPULATE_VEHICLE_AND_DRIVER = [
  { path: 'vehicleId', populate: { path: 'ownerId', select: 'nom prenom' } },
  { path: 'userId', select: '-password' },
];

@Injectable()
export class VehicleReservationService {
  constructor(
    @InjectModel(VehicleReservation.name) private reservationModel: Model<VehicleReservationDocument>,
    @InjectModel(VehicleReservationReview.name) private reviewModel: Model<VehicleReservationReviewDocument>,
    @InjectModel(Vehicle.name) private vehicleModel: Model<Vehicle>,
    @Inject(forwardRef(() => TransportService))
    private readonly transportService: TransportService,
  ) {}

  async create(userId: string, dto: CreateVehicleReservationDto) {
    // Vérifier que le véhicule existe et est valide
    const vehicle = await this.vehicleModel.findById(dto.vehicleId).exec();
    if (!vehicle) {
      throw new NotFoundException('Véhicule non trouvé');
    }
    if (vehicle.statut !== 'VALIDE') {
      throw new BadRequestException('Ce véhicule n\'est pas disponible pour réservation');
    }

    // Vérifier qu'il n'y a pas déjà une réservation pour ce véhicule à cette date/heure
    const reservationDate = new Date(dto.date);
    const existingReservation = await this.reservationModel
      .findOne({
        vehicleId: new Types.ObjectId(dto.vehicleId),
        date: reservationDate,
        heure: dto.heure,
        statut: { $in: ['EN_ATTENTE', 'CONFIRMEE'] },
      })
      .exec();

    if (existingReservation) {
      throw new BadRequestException(
        'Ce véhicule est déjà réservé à cette date et heure',
      );
    }

    const reservation = await this.reservationModel.create({
      userId: new Types.ObjectId(userId),
      vehicleId: new Types.ObjectId(dto.vehicleId),
      date: reservationDate,
      heure: dto.heure,
      lieuDepart: dto.lieuDepart ?? null,
      lieuDestination: dto.lieuDestination ?? null,
      besoinsSpecifiques: dto.besoinsSpecifiques ?? null,
      qrCode: `QR-VEHICLE-${Date.now()}-${userId.slice(-4)}`,
      statut: 'EN_ATTENTE',
    });

    try {
      const transport = await this.transportService.createLinkedToVehicleReservation(reservation);
      await this.reservationModel
        .updateOne({ _id: reservation._id }, { $set: { transportId: transport._id } })
        .exec();
    } catch (err) {
      await this.reservationModel.deleteOne({ _id: reservation._id }).exec();
      throw err;
    }

    return this.findOne(reservation._id.toString());
  }

  async findByUser(userId: string) {
    return this.reservationModel
      .find({ userId: new Types.ObjectId(userId) })
      .populate(POPULATE_VEHICLE_AND_DRIVER[0])
      .populate(POPULATE_VEHICLE_AND_DRIVER[1])
      .sort({ date: -1, heure: -1 })
      .exec();
  }

  /** Réservations de l'utilisateur, optionnellement filtrées par statut (ex. TERMINEE), tri date décroissante */
  async findHistoryByUser(userId: string, statut?: string) {
    const filter: { userId: Types.ObjectId; statut?: string } = { userId: new Types.ObjectId(userId) };
    if (statut) filter.statut = statut;
    return this.reservationModel
      .find(filter)
      .populate(POPULATE_VEHICLE_AND_DRIVER[0])
      .populate(POPULATE_VEHICLE_AND_DRIVER[1])
      .sort({ date: -1, heure: -1 })
      .exec();
  }

  async findByVehicle(vehicleId: string) {
    return this.reservationModel
      .find({ vehicleId: new Types.ObjectId(vehicleId) })
      .populate('userId', '-password')
      .sort({ date: -1, heure: -1 })
      .exec();
  }

  async findOne(id: string) {
    const reservation = await this.reservationModel
      .findById(id)
      .populate(POPULATE_VEHICLE_AND_DRIVER[0])
      .populate(POPULATE_VEHICLE_AND_DRIVER[1])
      .exec();
    if (!reservation) throw new NotFoundException('Réservation non trouvée');
    return reservation;
  }

  async updateStatut(reservationId: string, statut: string, actor: UserDocument) {
    const validStatuts = ['EN_ATTENTE', 'CONFIRMEE', 'ANNULEE', 'TERMINEE'];
    if (!validStatuts.includes(statut)) {
      throw new BadRequestException(`Statut invalide. Valeurs autorisées: ${validStatuts.join(', ')}`);
    }

    const reservation = await this.reservationModel
      .findById(reservationId)
      .populate({ path: 'vehicleId', select: 'ownerId' })
      .exec();
    if (!reservation) throw new NotFoundException('Réservation non trouvée');

    const isAdmin = actor.role === Role.ADMIN;
    const isReservationOwner = reservation.userId?.toString() === actor._id?.toString();
    const vehicleOwnerId = (reservation.vehicleId as { ownerId?: Types.ObjectId })?.ownerId?.toString();
    const isVehicleOwner = vehicleOwnerId === actor._id?.toString();

    // Confirmer/terminer: réservé au propriétaire du véhicule ou admin.
    if (statut === 'CONFIRMEE' || statut === 'TERMINEE') {
      if (!isVehicleOwner && !isAdmin) {
        throw new ForbiddenException('Seul le propriétaire du véhicule ou un admin peut confirmer/terminer');
      }
    }

    // Annuler: possible par demandeur, propriétaire du véhicule, ou admin.
    if (statut === 'ANNULEE') {
      if (!isReservationOwner && !isVehicleOwner && !isAdmin) {
        throw new ForbiddenException('Vous ne pouvez pas annuler cette réservation');
      }
    }

    const res = await this.reservationModel
      .findByIdAndUpdate(reservationId, { $set: { statut } }, { new: true })
      .populate(POPULATE_VEHICLE_AND_DRIVER[0])
      .populate(POPULATE_VEHICLE_AND_DRIVER[1])
      .exec();
    if (!res) throw new NotFoundException('Réservation non trouvée');

    if (statut === 'ANNULEE') {
      await this.transportService.onVehicleReservationCancelled(res);
    }
    if (statut === 'TERMINEE') {
      await this.transportService.onVehicleReservationTerminated(res);
    }

    return res;
  }

  async remove(reservationId: string, actor: UserDocument) {
    const reservation = await this.reservationModel
      .findById(reservationId)
      .populate({ path: 'vehicleId', select: 'ownerId' })
      .exec();
    if (!reservation) throw new NotFoundException('Réservation non trouvée');

    const isAdmin = actor.role === Role.ADMIN;
    const isReservationOwner = reservation.userId?.toString() === actor._id?.toString();
    const vehicleOwnerId = (reservation.vehicleId as { ownerId?: Types.ObjectId })?.ownerId?.toString();
    const isVehicleOwner = vehicleOwnerId === actor._id?.toString();

    if (!isReservationOwner && !isVehicleOwner && !isAdmin) {
      throw new ForbiddenException('Vous ne pouvez pas annuler cette réservation');
    }

    await this.reservationModel
      .findByIdAndUpdate(
        reservationId,
        { $set: { statut: 'ANNULEE' } },
        { new: true },
      )
      .exec();

    if (reservation.transportId) {
      await this.transportService.onVehicleReservationCancelled(reservation);
    }
  }

  // ---------- Évaluations (reviews) ----------

  async createOrUpdateReview(reservationId: string, userId: string, dto: CreateVehicleReservationReviewDto) {
    const reservation = await this.reservationModel.findById(reservationId).exec();
    if (!reservation) throw new NotFoundException('Réservation non trouvée');
    if (reservation.userId.toString() !== userId) {
      throw new ForbiddenException('Vous ne pouvez évaluer que vos propres réservations');
    }
    if (reservation.statut !== 'TERMINEE') {
      throw new BadRequestException('Seules les réservations terminées peuvent être évaluées');
    }

    const payload: Record<string, unknown> = {
      vehicleReservationId: new Types.ObjectId(reservationId),
      userId: new Types.ObjectId(userId),
      note: dto.note,
      comment: dto.comment ?? null,
      vehicleId: dto.vehicleId ? new Types.ObjectId(dto.vehicleId) : null,
      driverId: dto.driverId ? new Types.ObjectId(dto.driverId) : null,
    };

    const existing = await this.reviewModel.findOne({ vehicleReservationId: new Types.ObjectId(reservationId) }).exec();
    if (existing) {
      const updated = await this.reviewModel
        .findByIdAndUpdate(existing._id, { $set: payload }, { new: true })
        .exec();
      return this.formatReviewResponse(updated!);
    }

    const created = await this.reviewModel.create(payload);
    return this.formatReviewResponse(created);
  }

  async getReviewByReservationId(reservationId: string, userId: string) {
    const reservation = await this.reservationModel.findById(reservationId).exec();
    if (!reservation) throw new NotFoundException('Réservation non trouvée');
    if (reservation.userId.toString() !== userId) {
      throw new ForbiddenException('Accès non autorisé à cette réservation');
    }

    const review = await this.reviewModel
      .findOne({ vehicleReservationId: new Types.ObjectId(reservationId) })
      .exec();
    if (!review) throw new NotFoundException('Aucune évaluation pour cette réservation');
    return this.formatReviewResponse(review);
  }

  private formatReviewResponse(review: VehicleReservationReviewDocument) {
    return {
      id: review._id?.toString(),
      reservationId: review.vehicleReservationId?.toString(),
      vehicleReservationId: review.vehicleReservationId?.toString(),
      note: review.note,
      comment: review.comment ?? undefined,
      vehicleId: review.vehicleId?.toString(),
      driverId: review.driverId?.toString(),
      createdAt: review.createdAt,
    };
  }
}
