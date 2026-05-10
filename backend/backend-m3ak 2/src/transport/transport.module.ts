import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { TransportController } from './transport.controller';
import { TransportService } from './transport.service';
import { TransportRequest, TransportRequestSchema } from './schemas/transport-request.schema';
import { UserModule } from '../user/user.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: TransportRequest.name, schema: TransportRequestSchema },
    ]),
    UserModule,
  ],
  controllers: [TransportController],
  providers: [TransportService],
  exports: [TransportService],
})
export class TransportModule {}
