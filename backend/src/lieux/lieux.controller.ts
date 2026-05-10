import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import { LieuxService } from './lieux.service';
import { CreateLieuDto } from './dto/create-lieu.dto';
// import { JwtAuthGuard } from '../auth/jwt-auth.guard'; // À décommenter quand le guard sera créé

@Controller('lieux')
export class LieuxController {
  constructor(private readonly lieuxService: LieuxService) {}

  @Get()
  findAll() {
    return this.lieuxService.findAll();
  }

  @Get('nearby')
  findNearby(
    @Query('latitude') latitude: string,
    @Query('longitude') longitude: string,
    @Query('maxDistance') maxDistance?: string,
  ) {
    const lat = parseFloat(latitude);
    const lng = parseFloat(longitude);
    const maxDist = maxDistance ? parseFloat(maxDistance) : 10;
    return this.lieuxService.findNearby(lat, lng, maxDist);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.lieuxService.findOne(id);
  }

  @Post()
  // @UseGuards(JwtAuthGuard) // À décommenter quand le guard sera créé
  create(@Body() createDto: CreateLieuDto, @Request() req: any) {
    // Temporaire: utiliser req.body.userId ou req.user.id quand JWT sera implémenté
    const userId = req.user?.id || req.user?._id || req.body.userId || 'temp-user-id';
    return this.lieuxService.create(userId, createDto);
  }
}





