import { Module } from '@nestjs/common';
import { HelpPriorityService } from './help-priority.service';

@Module({
  providers: [HelpPriorityService],
  exports: [HelpPriorityService],
})
export class HelpPriorityModule {}
