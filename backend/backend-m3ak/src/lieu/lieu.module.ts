import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { LieuController } from './lieu.controller';
import { LieuService } from './lieu.service';
import { Lieu, LieuSchema } from './schemas/lieu.schema';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: Lieu.name, schema: LieuSchema }]),
  ],
  controllers: [LieuController],
  providers: [LieuService],
  exports: [LieuService],
})
export class LieuModule {}
