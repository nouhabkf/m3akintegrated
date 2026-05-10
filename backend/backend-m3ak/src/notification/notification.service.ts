import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { InjectModel, InjectConnection } from '@nestjs/mongoose';
import { HttpService } from '@nestjs/axios';
import { ConfigService } from '@nestjs/config';
import { Connection, Model, Types } from 'mongoose';
import { firstValueFrom } from 'rxjs';
import { Notification, NotificationDocument } from './schemas/notification.schema';

@Injectable()
export class NotificationService {
  private readonly logger = new Logger(NotificationService.name);

  constructor(
    @InjectModel(Notification.name) private notificationModel: Model<NotificationDocument>,
    @InjectConnection() private readonly connection: Connection,
    private readonly httpService: HttpService,
    private readonly configService: ConfigService,
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
    const notif = await this.notificationModel
      .findOneAndUpdate(
        { _id: notificationId, userId: new Types.ObjectId(userId) },
        { $set: { lu: true } },
        { new: true },
      )
      .exec();
    if (!notif) throw new NotFoundException('Notification non trouvée');
    return notif;
  }

  async markAllAsRead(userId: string) {
    await this.notificationModel
      .updateMany({ userId: new Types.ObjectId(userId) }, { $set: { lu: true } })
      .exec();
    return { message: 'Toutes les notifications ont été marquées comme lues' };
  }

  /** Lecture FCM depuis MongoDB (champ optionnel hors schéma strict User). */
  async getFcmTokenForUser(userId: string): Promise<string | null> {
    const doc = await this.connection.collection('users').findOne(
      { _id: new Types.ObjectId(userId) },
      { projection: { fcmToken: 1 } },
    );
    const token = doc?.fcmToken;
    return typeof token === 'string' && token.length > 0 ? token : null;
  }

  async sendPushToUser(
    fcmToken: string,
    title: string,
    body: string,
    data?: Record<string, string>,
  ): Promise<void> {
    const key = this.configService.get<string>('FCM_SERVER_KEY');
    if (!key) {
      this.logger.warn('FCM_SERVER_KEY absent — push ignoré');
      return;
    }
    if (!fcmToken) {
      this.logger.warn('fcmToken vide — push ignoré');
      return;
    }

    try {
      await firstValueFrom(
        this.httpService.post(
          'https://fcm.googleapis.com/fcm/send',
          {
            to: fcmToken,
            notification: { title, body, sound: 'default' },
            data: data ?? {},
            priority: 'high',
          },
          {
            headers: {
              Authorization: `key=${key}`,
              'Content-Type': 'application/json',
            },
          },
        ),
      );
      this.logger.log(`Push envoyé → ${title}`);
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      this.logger.error(`Erreur FCM : ${msg}`);
    }
  }

  async sendPushToDriver(
    fcmToken: string,
    ride: {
      _id: string;
      depart: string;
      destination: string;
      distanceEstimeeKm: number;
      besoinsAssistance: string[];
      typeTransport: string;
    },
  ): Promise<void> {
    const besoins = ride.besoinsAssistance?.join(', ') || 'aucun';
    await this.sendPushToUser(
      fcmToken,
      `Nouvelle course ♿ — ${ride.typeTransport}`,
      `De : ${ride.depart} | ${ride.distanceEstimeeKm?.toFixed(1)} km | Besoins : ${besoins}`,
      {
        rideId: ride._id.toString(),
        type: 'NOUVELLE_COURSE',
        destination: ride.destination,
      },
    );
  }

  async notifyPassager(
    demandeurId: string,
    title: string,
    body: string,
    type: string,
    rideId: string,
  ): Promise<void> {
    try {
      await this.notificationModel.create({
        userId: new Types.ObjectId(demandeurId),
        titre: title,
        message: body,
        type,
        lu: false,
      });

      const fcmToken = await this.getFcmTokenForUser(demandeurId);
      if (fcmToken) {
        await this.sendPushToUser(fcmToken, title, body, { rideId, type });
      }
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      this.logger.error(`notifyPassager échoué : ${msg}`);
    }
  }

  async notifyDriver(
    driverUserId: string,
    title: string,
    body: string,
    type: string,
    rideId: string,
  ): Promise<void> {
    try {
      await this.notificationModel.create({
        userId: new Types.ObjectId(driverUserId),
        titre: title,
        message: body,
        type,
        lu: false,
      });

      const fcmToken = await this.getFcmTokenForUser(driverUserId);
      if (fcmToken) {
        await this.sendPushToUser(fcmToken, title, body, { rideId, type });
      }
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      this.logger.error(`notifyDriver échoué : ${msg}`);
    }
  }
}
