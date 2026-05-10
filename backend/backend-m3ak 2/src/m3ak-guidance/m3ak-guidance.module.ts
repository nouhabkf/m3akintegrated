import { Module } from '@nestjs/common';
import { M3akGuidanceController } from './m3ak-guidance.controller';
import { M3akGuidanceService } from './m3ak-guidance.service';

@Module({
  controllers: [M3akGuidanceController],
  providers: [M3akGuidanceService],
})
export class M3akGuidanceModule {}

