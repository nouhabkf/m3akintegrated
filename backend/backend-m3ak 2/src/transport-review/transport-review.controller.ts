import { Controller, Get, Post, Body, Param, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { TransportReviewService } from './transport-review.service';
import { CreateTransportReviewDto } from './dto/create-transport-review.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { UserDocument } from '../user/schemas/user.schema';

@ApiTags('Transport Reviews')
@Controller('transport-reviews')
export class TransportReviewController {
  constructor(private readonly transportReviewService: TransportReviewService) {}

  @Post('transport/:transportId')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Évaluer un transport (demandeur)' })
  async create(
    @Param('transportId') transportId: string,
    @CurrentUser() user: UserDocument,
    @Body() dto: CreateTransportReviewDto,
  ) {
    return this.transportReviewService.create(transportId, user._id.toString(), dto);
  }

  @Get('transport/:transportId')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Évaluations d\'un transport' })
  async findByTransport(@Param('transportId') transportId: string) {
    return this.transportReviewService.findByTransport(transportId);
  }
}
