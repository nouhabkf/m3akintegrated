import { Module } from '@nestjs/common';
import { AccessibilityController } from './accessibility.controller';
import { AccessibilityCompatController } from './accessibility-compat.controller';
import { AccessibilityService } from './accessibility.service';

@Module({
  controllers: [AccessibilityController, AccessibilityCompatController],
  providers: [AccessibilityService],
  exports: [AccessibilityService],
})
export class AccessibilityModule {}
