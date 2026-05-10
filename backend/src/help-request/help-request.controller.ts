import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import { HelpRequestService } from './help-request.service';
import { CreateHelpRequestDto } from './dto/create-help-request.dto';
import { UpdateHelpRequestStatusDto } from './dto/update-help-request-status.dto';

// Note: Vous devrez créer un AuthGuard pour protéger les routes
// @UseGuards(JwtAuthGuard)

@Controller('community/help-requests')
export class HelpRequestController {
  constructor(private readonly helpRequestService: HelpRequestService) {}

  @Post()
  create(@Body() createDto: CreateHelpRequestDto, @Request() req: any) {
    // req.user sera défini par le JwtAuthGuard
    const userId = req.user?.id || req.user?._id || req.body.userId; // Temporaire pour tests
    return this.helpRequestService.create(userId, createDto);
  }

  @Get()
  async findAll(
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    const pageNum = page ? parseInt(page, 10) : 1;
    const limitNum = limit ? parseInt(limit, 10) : 20;
    
    return this.helpRequestService.findAll(pageNum, limitNum);
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
    return this.helpRequestService.findNearby(lat, lng, maxDist);
  }

  @Get('me')
  findMyRequests(@Request() req: any) {
    const userId = req.user?.id || req.user?._id || req.body.userId; // Temporaire
    return this.helpRequestService.findByUser(userId);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.helpRequestService.findOne(id);
  }

  @Patch(':id/statut')
  updateStatus(
    @Param('id') id: string,
    @Body() updateDto: UpdateHelpRequestStatusDto,
    @Request() req: any,
  ) {
    const acceptedBy = req.user?.id || req.user?._id;
    return this.helpRequestService.updateStatus(id, updateDto, acceptedBy);
  }

  @Post(':id/accept')
  acceptRequest(@Param('id') id: string, @Request() req: any) {
    const volunteerId = req.user?.id || req.user?._id || req.body.userId; // Temporaire
    return this.helpRequestService.acceptRequest(id, volunteerId);
  }

  @Delete(':id')
  remove(@Param('id') id: string, @Request() req: any) {
    const userId = req.user?.id || req.user?._id || req.body.userId; // Temporaire
    return this.helpRequestService.delete(id, userId);
  }
}




