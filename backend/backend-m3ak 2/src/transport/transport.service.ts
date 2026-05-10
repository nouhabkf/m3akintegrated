import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { TransportRequest, TransportRequestDocument } from './schemas/transport-request.schema';
import { CreateTransportDto } from './dto/create-transport.dto';
import { UserService } from '../user/user.service';
import { Role } from '../user/enums/role.enum';

@Injectable()
export class TransportService {
  constructor(
    @InjectModel(TransportRequest.name) private transportModel: Model<TransportRequestDocument>,
    private userService: UserService,
  ) {}

  async create(demandeurId: string, dto: CreateTransportDto) {
    return this.transportModel.create({
      demandeurId: new Types.ObjectId(demandeurId),
      accompagnantId: null,
      typeTransport: dto.typeTransport,
      depart: dto.depart,
      destination: dto.destination,
      latitudeDepart: dto.latitudeDepart,
      longitudeDepart: dto.longitudeDepart,
      latitudeArrivee: dto.latitudeArrivee,
      longitudeArrivee: dto.longitudeArrivee,
      dateHeure: new Date(dto.dateHeure),
      statut: 'EN_ATTENTE',
    });
  }

  async findMatchingChauffeurs(_latitudeDepart: number, _longitudeDepart: number) {
    const accompagnants = await this.userService.findAccompagnantsDisponibles();
    return accompagnants.sort((a, b) => (b.noteMoyenne ?? 0) - (a.noteMoyenne ?? 0));
  }

  async accept(transportId: string, accompagnantId: string, scoreMatching?: number) {
    const transport = await this.transportModel.findById(transportId).exec();
    if (!transport) throw new NotFoundException('Demande de transport non trouvée');
    if (transport.statut !== 'EN_ATTENTE') {
      throw new BadRequestException('Cette demande n\'est plus disponible');
    }

    const accompagnant = await this.userService.findByIdWithPassword(accompagnantId);
    if (!accompagnant) throw new NotFoundException('Accompagnant non trouvé');
    if (accompagnant.role !== Role.ACCOMPAGNANT || !accompagnant.disponible) {
      throw new BadRequestException('Accompagnant non disponible');
    }

    return this.transportModel
      .findByIdAndUpdate(
        transportId,
        {
          $set: {
            accompagnantId: new Types.ObjectId(accompagnantId),
            statut: 'ACCEPTEE',
            scoreMatching: scoreMatching ?? null,
          },
        },
        { new: true },
      )
      .populate('demandeurId accompagnantId', '-password')
      .exec();
  }

  async cancel(transportId: string, userId: string) {
    const transport = await this.transportModel.findById(transportId).exec();
    if (!transport) throw new NotFoundException('Demande de transport non trouvée');

    const isDemandeur = transport.demandeurId.toString() === userId;
    const isAccompagnant = transport.accompagnantId?.toString() === userId;
    if (!isDemandeur && !isAccompagnant) {
      throw new ForbiddenException('Vous ne pouvez pas annuler cette demande');
    }

    return this.transportModel
      .findByIdAndUpdate(transportId, { $set: { statut: 'ANNULEE' } }, { new: true })
      .exec();
  }

  async findByDemandeur(demandeurId: string) {
    return this.transportModel
      .find({ demandeurId: new Types.ObjectId(demandeurId) })
      .populate('accompagnantId', '-password')
      .sort({ createdAt: -1 })
      .exec();
  }

  async findByAccompagnant(accompagnantId: string) {
    return this.transportModel
      .find({ accompagnantId: new Types.ObjectId(accompagnantId) })
      .populate('demandeurId', '-password')
      .sort({ createdAt: -1 })
      .exec();
  }

  async findAvailable() {
    return this.transportModel
      .find({ statut: 'EN_ATTENTE' })
      .populate('demandeurId', '-password')
      .sort({ dateHeure: 1 })
      .exec();
  }
}
