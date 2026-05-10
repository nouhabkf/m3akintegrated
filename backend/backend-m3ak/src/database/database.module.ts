import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { MongooseModule } from '@nestjs/mongoose';

@Module({
  imports: [
    MongooseModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: async (configService: ConfigService) => {
        const uri = configService.get<string>('MONGODB_URI');
        if (uri) {
          return { uri };
        }

        const username = configService.get<string>('DB_USERNAME');
        const password = configService.get<string>('DB_PASSWORD');
        const cluster = configService.get<string>('DB_CLUSTER');
        const dbName = configService.get<string>('DB_NAME') || 'ma3ak';

        if (username && password && cluster) {
          const encodedPassword = encodeURIComponent(password);
          return {
            uri: `mongodb+srv://${username}:${encodedPassword}@${cluster}/${dbName}?retryWrites=true&w=majority`,
          };
        }

        return { uri: 'mongodb://localhost:27017/ma3ak' };
      },
      inject: [ConfigService],
    }),
  ],
})
export class DatabaseModule {}
