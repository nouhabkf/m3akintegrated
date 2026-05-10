import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Notification, NotificationDocument } from './schemas/notification.schema';

@Injectable()
export class NotificationService {
  constructor(
    @InjectModel(Notification.name) private notificationModel: Model<NotificationDocument>,
  ) {}

  async create(userId: string, titre: string, message: string, type: string) {
    return this.notificationModel.create({
      userId: new Types.ObjectId(userId),
      titre,
      message,
      type,
      lu: false,
    });
  }

  async findByUser(userId: string, page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    const [data, total, unreadCount] = await Promise.all([
      this.notificationModel
        .find({ userId: new Types.ObjectId(userId) })
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .exec(),
      this.notificationModel.countDocuments({ userId: new Types.ObjectId(userId) }).exec(),
      this.notificationModel.countDocuments({ userId: new Types.ObjectId(userId), lu: false }).exec(),
    ]);
    return { data, total, page, limit, totalPages: Math.ceil(total / limit), unreadCount };
  }

  async markAsRead(userId: string, notificationId: string) {
    const notif = await this.notificationModel.findOneAndUpdate(
      { _id: notificationId, userId: new Types.ObjectId(userId) },
      { $set: { lu: true } },
      { new: true },
    ).exec();
    if (!notif) throw new NotFoundException('Notification non trouvée');
    return notif;
  }

  async markAllAsRead(userId: string) {
    await this.notificationModel.updateMany(
      { userId: new Types.ObjectId(userId) },
      { $set: { lu: true } },
    ).exec();
    return { message: 'Toutes les notifications ont été marquées comme lues' };
  }
}
