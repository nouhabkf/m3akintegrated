import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { HelpRequestController } from './help-request.controller';
import { HelpRequestService } from './help-request.service';
import { HelpRequest, HelpRequestSchema } from './schemas/help-request.schema';
import { ReputationModule } from '../reputation/reputation.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: HelpRequest.name, schema: HelpRequestSchema },
    ]),
    ReputationModule,
  ],
  controllers: [HelpRequestController],
  providers: [HelpRequestService],
  exports: [HelpRequestService],
})
export class HelpRequestModule {}

