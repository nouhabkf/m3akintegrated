import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { LieuxController } from './lieux.controller';
import { LieuxService } from './lieux.service';
import { Lieu, LieuSchema } from './schemas/lieu.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Lieu.name, schema: LieuSchema },
    ]),
  ],
  controllers: [LieuxController],
  providers: [LieuxService],
  exports: [LieuxService],
})
export class LieuxModule {}





