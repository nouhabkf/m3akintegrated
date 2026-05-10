import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { EducationController } from './education.controller';
import { EducationService } from './education.service';
import { EduModule, EducationModuleSchema } from './schemas/education-module.schema';
import { EducationProgress, EducationProgressSchema } from './schemas/education-progress.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: EduModule.name, schema: EducationModuleSchema },
      { name: EducationProgress.name, schema: EducationProgressSchema },
    ]),
  ],
  controllers: [EducationController],
  providers: [EducationService],
  exports: [EducationService],
})
export class EducationModule {}
