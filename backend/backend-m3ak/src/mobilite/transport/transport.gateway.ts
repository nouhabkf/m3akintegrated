import { Logger, Inject, forwardRef } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import {
  ConnectedSocket,
  MessageBody,
  OnGatewayDisconnect,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { TransportService } from '../../transport/transport.service';
import { TransportStatut } from '../../transport/enums/transport-statut.enum';

/**
 * Gateway WebSocket — suivi temps réel des courses (namespace /transport).
 */
@WebSocketGateway({
  cors: { origin: '*', credentials: true },
  namespace: '/transport',
})
export class TransportGateway implements OnGatewayDisconnect {
  @WebSocketServer()
  server!: Server;

  private readonly logger = new Logger(TransportGateway.name);

  private readonly statutsActifsMiseAJourPosition: string[] = [
    TransportStatut.ACCEPTEE,
    TransportStatut.EN_ROUTE,
    TransportStatut.ARRIVEE,
    TransportStatut.EN_COURS,
  ];

  constructor(
    @Inject(forwardRef(() => TransportService))
    private readonly transportService: TransportService,
    private readonly jwtService: JwtService,
  ) {}

  handleDisconnect(client: Socket): void {
    this.logger.log(`Client déconnecté : ${client.id}`);
  }

  @SubscribeMessage('join_ride')
  async handleJoinRide(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: { rideId: string; shareToken?: string },
  ): Promise<void> {
    const rideId = payload?.rideId;
    if (!rideId) {
      client.emit('error', { message: 'rideId requis' });
      return;
    }

    if (payload.shareToken && typeof payload.shareToken === 'string' && payload.shareToken.trim()) {
      const ok = await this.transportService.verifyShareToken(rideId, payload.shareToken.trim());
      if (!ok) {
        client.emit('error', { message: 'Lien de partage invalide ou expiré' });
        return;
      }
      client.join(`ride_${rideId}`);
      this.logger.log(`Client ${client.id} (invité partage) a rejoint ride_${rideId}`);
      return;
    }

    const bearer = this.extractBearerToken(client);
    if (!bearer) {
      client.emit('error', {
        message:
          'JWT (Authorization: Bearer dans le handshake) ou shareToken dans le corps join_ride requis',
      });
      return;
    }
    let userId: string;
    try {
      const jwtPayload = this.jwtService.verify<{ sub: string }>(bearer);
      userId = jwtPayload.sub;
    } catch {
      client.emit('error', { message: 'Token JWT invalide' });
      return;
    }

    const ride = await this.transportService.findTransportDocumentById(rideId);
    if (!ride) {
      client.emit('error', { message: 'Course introuvable' });
      return;
    }
    const allowed =
      ride.demandeurId.toString() === userId || ride.accompagnantId?.toString() === userId;
    if (!allowed) {
      client.emit('error', { message: 'Non autorisé pour rejoindre cette course' });
      return;
    }
    client.join(`ride_${rideId}`);
    this.logger.log(`Client ${client.id} (JWT) a rejoint ride_${rideId}`);
  }

  private extractBearerToken(client: Socket): string | null {
    const authHeader = client.handshake.headers.authorization;
    if (typeof authHeader === 'string' && authHeader.startsWith('Bearer ')) {
      return authHeader.split(' ')[1] ?? null;
    }
    const auth = client.handshake.auth as { token?: string } | undefined;
    if (auth?.token && typeof auth.token === 'string') {
      const t = auth.token;
      return t.startsWith('Bearer ') ? t.slice(7) : t;
    }
    return null;
  }

  @SubscribeMessage('driver_location')
  async handleDriverLocation(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: { rideId: string; lat: number; lng: number },
  ): Promise<void> {
    const token = this.extractBearerToken(client);
    if (!token) {
      client.emit('error', { message: 'Token manquant' });
      return;
    }
    let userId: string;
    try {
      const payloadJwt = this.jwtService.verify<{ sub: string }>(token);
      userId = payloadJwt.sub;
    } catch {
      client.emit('error', { message: 'Token invalide' });
      return;
    }

    const ride = await this.transportService.findTransportDocumentById(payload.rideId);
    if (!ride) {
      client.emit('error', { message: 'Course introuvable' });
      return;
    }
    if (ride.accompagnantId?.toString() !== userId) {
      client.emit('error', {
        message: 'Non autorisé — vous n\'êtes pas le chauffeur de cette course',
      });
      return;
    }

    if (!this.statutsActifsMiseAJourPosition.includes(ride.statut)) {
      client.emit('error', {
        message: `Mise à jour position impossible — statut : ${ride.statut}`,
      });
      return;
    }

    await this.transportService.updateDriverLocation(payload.rideId, payload.lat, payload.lng);

    this.server.to(`ride_${payload.rideId}`).emit('location_update', {
      lat: payload.lat,
      lng: payload.lng,
      timestamp: new Date().toISOString(),
    });
  }

  broadcastStatusUpdate(rideId: string, statut: string): void {
    this.server.to(`ride_${rideId}`).emit('ride_status_update', {
      rideId,
      statut,
      timestamp: new Date().toISOString(),
    });
    this.logger.log(`Statut broadcast ride_${rideId} : ${statut}`);
  }
}
