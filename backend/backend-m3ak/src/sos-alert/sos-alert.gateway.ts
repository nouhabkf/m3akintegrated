import { Logger } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import {
  ConnectedSocket,
  OnGatewayDisconnect,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { Role } from '../user/enums/role.enum';

@WebSocketGateway({
  cors: { origin: '*', credentials: true },
  namespace: '/sos',
})
export class SosAlertGateway implements OnGatewayDisconnect {
  @WebSocketServer()
  server!: Server;

  private readonly logger = new Logger(SosAlertGateway.name);

  constructor(private readonly jwtService: JwtService) {}

  handleDisconnect(client: Socket): void {
    this.logger.log(`Client déconnecté : ${client.id}`);
  }

  @SubscribeMessage('join_sos_feed')
  handleJoinSosFeed(@ConnectedSocket() client: Socket): void {
    const token = this.extractBearerToken(client);
    if (!token) {
      client.emit('error', { message: 'Token manquant' });
      return;
    }
    try {
      const payload = this.jwtService.verify<{ sub: string; role?: string }>(token);
      if (payload.role !== Role.ACCOMPAGNANT) {
        client.emit('error', { message: 'Réservé aux accompagnants' });
        return;
      }
      client.join(`accompagnant_${payload.sub}`);
      this.logger.log(`Client ${client.id} a rejoint accompagnant_${payload.sub}`);
    } catch {
      client.emit('error', { message: 'Token invalide' });
    }
  }

  emitSosCreatedForAccompagnant(accompagnantId: string, payload: Record<string, unknown>): void {
    this.server
      .to(`accompagnant_${accompagnantId}`)
      .emit('sos_alert_created', payload);
  }

  private extractBearerToken(client: Socket): string | null {
    const authHeader = client.handshake.headers.authorization;
    if (typeof authHeader === 'string' && authHeader.startsWith('Bearer ')) {
      return authHeader.slice(7);
    }
    const auth = client.handshake.auth as { token?: string } | undefined;
    if (auth?.token && typeof auth.token === 'string') {
      return auth.token.startsWith('Bearer ') ? auth.token.slice(7) : auth.token;
    }
    return null;
  }
}
