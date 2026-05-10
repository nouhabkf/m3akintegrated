import { Controller, Get, Post, Body, Param, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { LieuReservationService } from './lieu-reservation.service';
import { CreateLieuReservationDto } from './dto/create-lieu-reservation.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { UserDocument } from '../user/schemas/user.schema';

@ApiTags('Lieu Reservations')
@Controller('lieu-reservations')
export class LieuReservationController {
  constructor(private readonly lieuReservationService: LieuReservationService) {}

  @Post()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Créer une réservation' })
  async create(@CurrentUser() user: UserDocument, @Body() dto: CreateLieuReservationDto) {
    return this.lieuReservationService.create(user._id.toString(), dto);
  }

  @Get('me')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Mes réservations' })
  async getMine(@CurrentUser() user: UserDocument) {
    return this.lieuReservationService.findByUser(user._id.toString());
  }

  @Get('lieu/:lieuId')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Réservations d\'un lieu' })
  async getByLieu(@Param('lieuId') lieuId: string) {
    return this.lieuReservationService.findByLieu(lieuId);
  }

  @Post(':id/statut')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Mettre à jour le statut' })
  async updateStatut(@Param('id') id: string, @Body('statut') statut: string) {
    return this.lieuReservationService.updateStatut(id, statut);
  }
}
