import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { TransportReview, TransportReviewDocument } from './schemas/transport-review.schema';
import { TransportRequest, TransportRequestDocument } from '../transport/schemas/transport-request.schema';
import { CreateTransportReviewDto } from './dto/create-transport-review.dto';
import { UserService } from '../user/user.service';

@Injectable()
export class TransportReviewService {
  constructor(
    @InjectModel(TransportReview.name) private transportReviewModel: Model<TransportReviewDocument>,
    @InjectModel(TransportRequest.name) private transportModel: Model<TransportRequestDocument>,
    private userService: UserService,
  ) {}

  async create(transportId: string, userId: string, dto: CreateTransportReviewDto) {
    const transport = await this.transportModel
      .findById(transportId)
      .populate('accompagnantId')
      .exec();
    if (!transport) throw new NotFoundException('Transport non trouvé');
    if (transport.statut !== 'ACCEPTEE' && transport.statut !== 'TERMINEE') {
      throw new ForbiddenException('Vous ne pouvez évaluer que des transports terminés ou acceptés');
    }
    if (transport.demandeurId.toString() !== userId) {
      throw new ForbiddenException('Seul le demandeur peut évaluer');
    }

    const existing = await this.transportReviewModel
      .findOne({ transportId: new Types.ObjectId(transportId) })
      .exec();
    if (existing) throw new ForbiddenException('Évaluation déjà envoyée pour ce transport');

    const review = await this.transportReviewModel.create({
      transportId: new Types.ObjectId(transportId),
      note: dto.note,
      commentaire: dto.commentaire ?? null,
    });

    const accompagnantId = (transport.accompagnantId as { _id?: Types.ObjectId })?._id;
    if (accompagnantId) {
      await this.updateAccompagnantNoteMoyenne(accompagnantId.toString());
    }

    return review;
  }

  private async updateAccompagnantNoteMoyenne(accompagnantId: string) {
    const transports = await this.transportModel
      .find({ accompagnantId: new Types.ObjectId(accompagnantId) })
      .exec();
    const transportIds = transports.map((t) => t._id);

    const reviews = await this.transportReviewModel
      .find({ transportId: { $in: transportIds } })
      .exec();

    if (reviews.length === 0) return;
    const avg = reviews.reduce((s, r) => s + r.note, 0) / reviews.length;
    await this.userService.updateNoteMoyenne(accompagnantId, Math.round(avg * 10) / 10);
  }

  async findByTransport(transportId: string) {
    return this.transportReviewModel
      .find({ transportId: new Types.ObjectId(transportId) })
      .exec();
  }
}
