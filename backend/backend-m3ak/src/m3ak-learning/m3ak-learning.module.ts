import { Module } from '@nestjs/common';
import { M3akLearningController } from './m3ak-learning.controller';
import { M3akLearningService } from './m3ak-learning.service';
import { M3akVisionController } from './m3ak-vision.controller';
import { M3akVisionService } from './m3ak-vision.service';

@Module({
  controllers: [M3akLearningController, M3akVisionController],
  providers: [M3akLearningService, M3akVisionService],
  exports: [M3akLearningService, M3akVisionService],
})
export class M3akLearningModule {}
