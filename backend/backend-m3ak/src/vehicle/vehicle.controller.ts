import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiQuery,
} from '@nestjs/swagger';
import { VehicleService } from './vehicle.service';
import { CreateVehicleDto } from './dto/create-vehicle.dto';
import { UpdateVehicleDto } from './dto/update-vehicle.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { UserDocument } from '../user/schemas/user.schema';

@ApiTags('Véhicules')
@Controller('vehicles')
export class VehicleController {
  constructor(private readonly vehicleService: VehicleService) {}

  @Post()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Créer un véhicule' })
  async create(@Body() dto: CreateVehicleDto, @CurrentUser() user: UserDocument) {
    return this.vehicleService.create(dto, user);
  }

  @Get()
  @ApiOperation({ summary: 'Liste des véhicules (pagination)' })
  @ApiQuery({ name: 'ownerId', required: false, description: 'Filtrer par propriétaire' })
  @ApiQuery({ name: 'statut', required: false, enum: ['EN_ATTENTE', 'VALIDE', 'REFUSE'] })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({
    name: 'latitude',
    required: false,
    description: 'Latitude du demandeur — avec longitude, filtre à maxDistanceKm du propriétaire du véhicule',
  })
  @ApiQuery({ name: 'longitude', required: false })
  @ApiQuery({
    name: 'maxDistanceKm',
    required: false,
    description: 'Rayon en km (défaut 10 si latitude/longitude fournis)',
  })
  async findAll(
    @Query('ownerId') ownerId?: string,
    @Query('statut') statut?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
    @Query('latitude') latitude?: string,
    @Query('longitude') longitude?: string,
    @Query('maxDistanceKm') maxDistanceKm?: string,
  ) {
    const lat = latitude != null ? parseFloat(latitude) : undefined;
    const lon = longitude != null ? parseFloat(longitude) : undefined;
    const maxKm = maxDistanceKm != null ? parseFloat(maxDistanceKm) : undefined;
    return this.vehicleService.findAll({
      ownerId,
      statut,
      page: page ? parseInt(page, 10) : undefined,
      limit: limit ? parseInt(limit, 10) : undefined,
      nearLatitude: lat != null && Number.isFinite(lat) ? lat : undefined,
      nearLongitude: lon != null && Number.isFinite(lon) ? lon : undefined,
      maxDistanceKm: maxKm != null && Number.isFinite(maxKm) && maxKm > 0 ? maxKm : undefined,
    });
  }

  @Get('owner/:ownerId')
  @ApiOperation({ summary: 'Véhicules d\'un propriétaire' })
  async findByOwner(@Param('ownerId') ownerId: string) {
    return this.vehicleService.findByOwner(ownerId);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Détail d\'un véhicule' })
  async findOne(@Param('id') id: string) {
    return this.vehicleService.findOne(id);
  }

  @Patch(':id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Modifier un véhicule (propriétaire, admin, ou Chauffeurs solidaires pour le statut)' })
  async update(
    @Param('id') id: string,
    @Body() dto: UpdateVehicleDto,
    @CurrentUser() user: UserDocument,
  ) {
    return this.vehicleService.update(id, dto, user);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Supprimer un véhicule' })
  async remove(@Param('id') id: string, @CurrentUser() user: UserDocument) {
    await this.vehicleService.remove(id, user);
    return { message: 'Véhicule supprimé' };
  }
}
