import { Controller, Get, Post, Delete, Body, Param, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery, ApiBody } from '@nestjs/swagger';
import { VehicleReservationService } from './vehicle-reservation.service';
import { CreateVehicleReservationDto } from './dto/create-vehicle-reservation.dto';
import { CreateVehicleReservationReviewDto } from './dto/create-vehicle-reservation-review.dto';
import { UpdateVehicleReservationStatutDto } from './dto/update-vehicle-reservation-statut.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { UserDocument } from '../user/schemas/user.schema';

@ApiTags('Réservations Véhicules')
@Controller('vehicle-reservations')
export class VehicleReservationController {
  constructor(private readonly vehicleReservationService: VehicleReservationService) {}

  @Post()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Créer une réservation de véhicule' })
  async create(@CurrentUser() user: UserDocument, @Body() dto: CreateVehicleReservationDto) {
    return this.vehicleReservationService.create(user._id.toString(), dto);
  }

  @Get('me')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Mes réservations de véhicules (véhicule + chauffeur peuplés)' })
  async getMine(@CurrentUser() user: UserDocument) {
    return this.vehicleReservationService.findByUser(user._id.toString());
  }

  @Get('me/history')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Historique des déplacements (réservations terminées, tri date décroissante)' })
  @ApiQuery({ name: 'statut', required: false, description: 'Filtrer par statut (ex. TERMINEE)' })
  async getMyHistory(@CurrentUser() user: UserDocument, @Query('statut') statut?: string) {
    return this.vehicleReservationService.findHistoryByUser(user._id.toString(), statut);
  }

  @Get('vehicle/:vehicleId')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Réservations d\'un véhicule' })
  async getByVehicle(@Param('vehicleId') vehicleId: string) {
    return this.vehicleReservationService.findByVehicle(vehicleId);
  }

  @Get(':id/review')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Récupérer l\'évaluation d\'une réservation terminée' })
  async getReview(@CurrentUser() user: UserDocument, @Param('id') id: string) {
    return this.vehicleReservationService.getReviewByReservationId(id, user._id.toString());
  }

  @Post(':id/review')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Créer ou mettre à jour l\'évaluation d\'un trajet terminé' })
  async createOrUpdateReview(
    @CurrentUser() user: UserDocument,
    @Param('id') id: string,
    @Body() dto: CreateVehicleReservationReviewDto,
  ) {
    return this.vehicleReservationService.createOrUpdateReview(id, user._id.toString(), dto);
  }

  @Get(':id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Détail d\'une réservation' })
  async findOne(@Param('id') id: string) {
    return this.vehicleReservationService.findOne(id);
  }

  @Post(':id/statut')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Mettre à jour le statut d\'une réservation' })
  @ApiBody({ type: UpdateVehicleReservationStatutDto })
  async updateStatut(
    @Param('id') id: string,
    @Body() body: UpdateVehicleReservationStatutDto,
    @CurrentUser() user: UserDocument,
  ) {
    return this.vehicleReservationService.updateStatut(id, body.statut, user);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Annuler une réservation' })
  async remove(@Param('id') id: string, @CurrentUser() user: UserDocument) {
    await this.vehicleReservationService.remove(id, user);
    return { message: 'Réservation annulée' };
  }
}
