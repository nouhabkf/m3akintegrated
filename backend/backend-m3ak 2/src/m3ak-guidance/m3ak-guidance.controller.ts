import { Body, Controller, Post } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { GuidanceFrameDto } from './dto/guidance-frame.dto';
import { GuidanceSessionDto } from './dto/guidance-session.dto';
import { M3akGuidanceService } from './m3ak-guidance.service';

@ApiTags('m3ak-guidance')
@Controller('m3ak/guidance')
export class M3akGuidanceController {
  constructor(private readonly guidance: M3akGuidanceService) {}

  @Post('session')
  createSession(@Body() body: GuidanceSessionDto) {
    return this.guidance.createSession(body.clientHint);
  }

  @Post('frame')
  async analyzeFrame(@Body() body: GuidanceFrameDto) {
    return await this.guidance.analyzeFrame(body.sessionId, body.imageBase64);
  }
}

