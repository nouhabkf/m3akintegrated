import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { TransportReviewController } from './transport-review.controller';
import { TransportReviewService } from './transport-review.service';
import { TransportReview, TransportReviewSchema } from './schemas/transport-review.schema';
import { TransportRequest, TransportRequestSchema } from '../transport/schemas/transport-request.schema';
import { UserModule } from '../user/user.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: TransportReview.name, schema: TransportReviewSchema },
      { name: TransportRequest.name, schema: TransportRequestSchema },
    ]),
    UserModule,
  ],
  controllers: [TransportReviewController],
  providers: [TransportReviewService],
  exports: [TransportReviewService],
})
export class TransportReviewModule {}
