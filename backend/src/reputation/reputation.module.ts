import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ReputationController } from './reputation.controller';
import { ReputationService } from './reputation.service';
import { Rating, RatingSchema } from './schemas/rating.schema';
import { User, UserSchema } from '../user/schemas/user.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Rating.name, schema: RatingSchema },
      { name: User.name, schema: UserSchema },
    ]),
  ],
  controllers: [ReputationController],
  providers: [ReputationService],
  exports: [ReputationService],
})
export class ReputationModule {}




