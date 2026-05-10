import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { TransportService } from './transport.service';
import { CreateTransportDto } from './dto/create-transport.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { UserDocument } from '../user/schemas/user.schema';

@ApiTags('Transport')
@Controller('transport')
export class TransportController {
  constructor(private readonly transportService: TransportService) {}

  @Post()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Créer une demande de transport' })
  async create(@CurrentUser() user: UserDocument, @Body() dto: CreateTransportDto) {
    return this.transportService.create(user._id.toString(), dto);
  }

  @Get('matching')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Trouver les accompagnants les plus proches' })
  async getMatching(
    @Query('latitude') latitude: string,
    @Query('longitude') longitude: string,
  ) {
    return this.transportService.findMatchingChauffeurs(
      parseFloat(latitude),
      parseFloat(longitude),
    );
  }

  @Post(':id/accept')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Accepter une demande de transport (accompagnant)' })
  async accept(
    @Param('id') id: string,
    @CurrentUser() user: UserDocument,
    @Body('scoreMatching') scoreMatching?: number,
  ) {
    return this.transportService.accept(id, user._id.toString(), scoreMatching);
  }

  @Post(':id/cancel')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Annuler une demande de transport' })
  async cancel(@Param('id') id: string, @CurrentUser() user: UserDocument) {
    return this.transportService.cancel(id, user._id.toString());
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
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Demandes en attente (accompagnants)' })
  async getAvailable() {
    return this.transportService.findAvailable();
  }
}
