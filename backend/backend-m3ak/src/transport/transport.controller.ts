import {
  Controller,
  Get,
  Post,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  Req,
  Headers,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import type { Request } from 'express';
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiQuery,
  ApiBody,
  ApiHeader,
} from '@nestjs/swagger';
import { TransportService } from './transport.service';
import {
  AcceptTransportDto,
  CancelTransportDto,
  CreateTransportDto,
  TerminerTransportDto,
  TransportMatchingBodyDto,
  TransportMatchingQueryDto,
  TransportHistoryQueryDto,
  UpdateTransportStatutDto,
} from './dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { UserDocument } from '../user/schemas/user.schema';
import { ChauffeurSolidaireGuard } from '../mobilite/guards/chauffeur-solidaire.guard';
import { TransportShareRateLimitService } from './transport-share-rate-limit.service';

@ApiTags('Transport')
@Controller('transport')
export class TransportController {
  constructor(
    private readonly transportService: TransportService,
    private readonly shareRateLimit: TransportShareRateLimitService,
  ) {}

  private shareTokenFromRequest(
    req: Request,
    queryToken?: string,
    headerToken?: string,
  ): string | undefined {
    const h = headerToken ?? req.headers['x-transport-share-token'];
    if (typeof h === 'string' && h.trim()) return h.trim();
    if (queryToken && typeof queryToken === 'string' && queryToken.trim()) return queryToken.trim();
    return undefined;
  }

  private assertSharePublicRate(req: Request, suffix: string): void {
    const ip = req.ip ?? req.socket?.remoteAddress ?? 'unknown';
    if (!this.shareRateLimit.tryConsume(`share-public:${suffix}:${ip}`, 45, 60_000)) {
      throw new HttpException('Trop de requêtes', HttpStatus.TOO_MANY_REQUESTS);
    }
  }

  @Post()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Créer une demande de transport' })
  async create(@CurrentUser() user: UserDocument, @Body() dto: CreateTransportDto) {
    return this.transportService.create(user._id.toString(), dto);
  }

  @Post('matching')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary:
      'Matching (corps JSON) — même logique que GET /transport/matching ; utile pour besoinsAssistance[] sans URL longue',
  })
  async postMatching(@Body() body: TransportMatchingBodyDto) {
    return this.transportService.findMatchingChauffeurs(
      body.latitude,
      body.longitude,
      body.typeHandicap,
      body.urgence ?? false,
      body.rayonKm,
      body.besoinsAssistance,
    );
  }

  @Get('history')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary:
      'Historique unifié (transport + réservations véhicule) — fenêtre récente fusionnée, voir champ `note`',
  })
  async getHistory(@CurrentUser() user: UserDocument, @Query() q: TransportHistoryQueryDto) {
    return this.transportService.findUnifiedHistory(
      user._id.toString(),
      q.page ?? 1,
      q.limit ?? 20,
    );
  }

  @Get('matching')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary:
      'Matching accompagnants (Flask optionnel puis algorithme NestJS : proximité, véhicules, sous-scores, score)',
  })
  @ApiQuery({ name: 'latitude', required: true })
  @ApiQuery({ name: 'longitude', required: true })
  @ApiQuery({ name: 'typeHandicap', required: false, description: 'Type handicap du demandeur' })
  @ApiQuery({ name: 'urgence', required: false, description: 'true pour prioriser urgences' })
  @ApiQuery({ name: 'rayonKm', required: false, description: 'Rayon max de recherche (par défaut 15 km)' })
  @ApiQuery({
    name: 'besoinsAssistance',
    required: false,
    isArray: true,
    description: 'Répéter le param ou CSV',
  })
  async getMatching(@Query() query: TransportMatchingQueryDto) {
    return this.transportService.findMatchingChauffeurs(
      query.latitude,
      query.longitude,
      query.typeHandicap,
      query.urgence ?? false,
      query.rayonKm,
      query.besoinsAssistance,
    );
  }

  @Get('me')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Mes demandes de transport' })
  async getMine(@CurrentUser() user: UserDocument) {
    const [asDemandeur, asAccompagnant] = await Promise.all([
      this.transportService.findByDemandeur(user._id.toString()),
      this.transportService.findByAccompagnant(user._id.toString()),
    ]);
    return { asDemandeur, asAccompagnant };
  }

  @Get('available')
  @UseGuards(JwtAuthGuard, ChauffeurSolidaireGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary:
      'Demandes en attente — Chauffeurs solidaires uniquement ; tri : priorité médicale > URGENCE > autres puis date',
  })
  async getAvailable(@CurrentUser() user: UserDocument) {
    return this.transportService.findAvailable(user._id.toString());
  }

  @Get(':id/matching-candidates')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary:
      'Matching basé sur une demande existante (coords + besoins du document). Demandeur toujours ; chauffeur solidaire si course EN_ATTENTE.',
  })
  @ApiQuery({ name: 'typeHandicap', required: false })
  async getMatchingForTransport(
    @Param('id') id: string,
    @CurrentUser() user: UserDocument,
    @Query('typeHandicap') typeHandicap?: string,
  ) {
    const matching = await this.transportService.findMatchingCandidatesForTransport(
      id,
      user._id.toString(),
      typeHandicap,
    );
    return { transportId: id, matching };
  }

  @Get(':id/suivi/public')
  @ApiOperation({
    summary:
      'Suivi lecture seule (invité) — token query `token` ou header `X-Transport-Share-Token` ; pas de JWT',
  })
  @ApiHeader({ name: 'X-Transport-Share-Token', required: false })
  @ApiQuery({ name: 'token', required: false, description: 'Jeton opaque retourné par POST /transport/:id/share' })
  async getSuiviPublic(
    @Param('id') id: string,
    @Query('token') token: string | undefined,
    @Headers('x-transport-share-token') headerToken: string | undefined,
    @Req() req: Request,
  ) {
    this.assertSharePublicRate(req, `suivi:${id}`);
    const plain = this.shareTokenFromRequest(req, token, headerToken);
    if (!plain) {
      throw new HttpException('Token de partage requis', HttpStatus.UNAUTHORIZED);
    }
    return this.transportService.getSuiviPublic(id, plain);
  }

  @Get(':id/eta/public')
  @ApiOperation({
    summary: 'ETA lecture seule (invité) — même auth par token que suivi/public',
  })
  @ApiHeader({ name: 'X-Transport-Share-Token', required: false })
  @ApiQuery({ name: 'token', required: false })
  async getEtaPublic(
    @Param('id') id: string,
    @Query('token') token: string | undefined,
    @Headers('x-transport-share-token') headerToken: string | undefined,
    @Req() req: Request,
  ) {
    this.assertSharePublicRate(req, `eta:${id}`);
    const plain = this.shareTokenFromRequest(req, token, headerToken);
    if (!plain) {
      throw new HttpException('Token de partage requis', HttpStatus.UNAUTHORIZED);
    }
    return this.transportService.getEtaPublic(id, plain);
  }

  @Post(':id/share')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary:
      'Émettre un jeton de partage (opaque, TTL jusqu’à fin estimée + marge). Demandeur ou chauffeur assigné.',
  })
  async postShare(@Param('id') id: string, @CurrentUser() user: UserDocument) {
    return this.transportService.issueShareToken(id, user._id.toString());
  }

  @Delete(':id/share')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Révoquer le jeton de partage' })
  async deleteShare(@Param('id') id: string, @CurrentUser() user: UserDocument) {
    await this.transportService.revokeShareToken(id, user._id.toString());
    return { revoked: true };
  }

  @Post(':id/accept')
  @UseGuards(JwtAuthGuard, ChauffeurSolidaireGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Accepter une demande (Chauffeurs solidaires uniquement)' })
  async accept(
    @Param('id') id: string,
    @CurrentUser() user: UserDocument,
    @Body() body: AcceptTransportDto,
  ) {
    return this.transportService.accept(id, user._id.toString(), {
      scoreMatching: body.scoreMatching,
      vehicleId: body.vehicleId,
      matchingSubscores: body.matchingSubscores,
    });
  }

  @Post(':id/termine')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Marquer un transport comme terminé (durée optionnelle)' })
  async terminer(
    @Param('id') id: string,
    @CurrentUser() user: UserDocument,
    @Body() dto: TerminerTransportDto,
  ) {
    return this.transportService.terminate(
      id,
      user._id.toString(),
      dto.dureeMinutes,
      dto.dateHeureArrivee,
    );
  }

  @Post(':id/cancel')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Annuler une demande de transport' })
  @ApiBody({ type: CancelTransportDto, required: false })
  async cancel(
    @Param('id') id: string,
    @CurrentUser() user: UserDocument,
    @Body() body: CancelTransportDto,
  ) {
    return this.transportService.cancel(id, user._id.toString(), body.raison);
  }

  @Get(':id/price-estimate')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary:
      'Estimation distance, durée et prix (TND) — cache, OSRM ou repli Haversine, persistance MongoDB',
  })
  async getPriceEstimate(@Param('id') id: string) {
    return this.transportService.getPriceEstimate(id);
  }

  @Get(':id/eta')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Estimation temps d\'arrivée du chauffeur (trajet accepté)' })
  async getEta(@Param('id') id: string) {
    return this.transportService.getEta(id);
  }

  @Get(':id/suivi')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary:
      'Suivi trajet : position chauffeur (WebSocket), profil chauffeur, libellé statut, ETA, itinéraire OSRM',
  })
  async getSuivi(@Param('id') id: string) {
    return this.transportService.getSuivi(id);
  }

  @Post(':id/statut')
  @UseGuards(JwtAuthGuard, ChauffeurSolidaireGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Mettre à jour le statut de la course (chauffeur solidaire assigné)' })
  async updateStatut(
    @Param('id') id: string,
    @CurrentUser() user: UserDocument,
    @Body() dto: UpdateTransportStatutDto,
  ) {
    return this.transportService.updateStatut(id, user._id.toString(), dto.statut);
  }

  @Get(':id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Détail d\'une demande de transport' })
  async getOne(@Param('id') id: string) {
    return this.transportService.findById(id);
  }
}
