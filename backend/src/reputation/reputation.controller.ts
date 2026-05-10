import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Request,
} from '@nestjs/common';
import { ReputationService } from './reputation.service';
import { CreateRatingDto } from './dto/create-rating.dto';

@Controller('reputation')
export class ReputationController {
  constructor(private readonly reputationService: ReputationService) {}

  @Post('ratings/:userId')
  createRating(
    @Param('userId') userId: string,
    @Body() createDto: CreateRatingDto,
    @Request() req: any,
  ) {
    const raterUserId = req.user?.id || req.user?._id || req.body.userId; // Temporaire
    return this.reputationService.createRating(userId, raterUserId, createDto);
  }

  @Get('ratings/user/:userId')
  getRatingsByUser(@Param('userId') userId: string) {
    return this.reputationService.getRatingsByUser(userId);
  }

  @Get('ratings/:id')
  getRatingById(@Param('id') id: string) {
    return this.reputationService.getRatingById(id);
  }

  @Get('user/:userId')
  getUserReputation(@Param('userId') userId: string) {
    return this.reputationService.getUserReputation(userId);
  }
}




