import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Query,
  UseGuards,
  ForbiddenException,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { SosAlertService } from './sos-alert.service';
import { CreateSosAlertDto } from './dto/create-sos-alert.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { UserDocument } from '../user/schemas/user.schema';
import { Role } from '../user/enums/role.enum';

@ApiTags('SOS Alerts')
@Controller('sos-alerts')
export class SosAlertController {
  constructor(private readonly sosAlertService: SosAlertService) {}

  @Post()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary: 'Envoyer une alerte SOS',
    description:
      'Enregistre l’alerte et notifie (in-app + push FCM si configuré) chaque accompagnant configuré comme contact d’urgence.',
  })
  async create(@CurrentUser() user: UserDocument, @Body() dto: CreateSosAlertDto) {
    return this.sosAlertService.create(user._id.toString(), dto);
  }

  @Get('me')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Mes alertes SOS' })
  async getMyAlerts(@CurrentUser() user: UserDocument) {
    return this.sosAlertService.findByUser(user._id.toString());
  }

  @Get('for-accompagnant')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary:
      'Alertes SOS des bénéficiaires (voix, position…) pour accompagnants liés',
  })
  async getForAccompagnant(@CurrentUser() user: UserDocument) {
    if (user.role !== Role.ACCOMPAGNANT) {
      throw new ForbiddenException('Réservé aux comptes accompagnant');
    }
    return this.sosAlertService.findForAccompagnant(user._id.toString());
  }

  @Get('nearby')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Alertes SOS à proximité' })
  async getNearby(
    @Query('latitude') latitude: string,
    @Query('longitude') longitude: string,
  ) {
    return this.sosAlertService.findNearby(parseFloat(latitude), parseFloat(longitude));
  }

  @Post(':id/statut')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Mettre à jour le statut d\'une alerte' })
  async updateStatut(@Param('id') id: string, @Body('statut') statut: string) {
    return this.sosAlertService.updateStatut(id, statut);
  }
}
