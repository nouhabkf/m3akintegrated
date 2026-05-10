import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { NestExpressApplication } from '@nestjs/platform-express';
import { existsSync, mkdirSync } from 'fs';
import { AppModule } from './app.module';
import { getUploadsRoot } from './common/upload-paths';

async function bootstrap() {
  const uploadsDir = getUploadsRoot();
  if (!existsSync(uploadsDir)) {
    mkdirSync(uploadsDir, { recursive: true });
  }

  const app = await NestFactory.create<NestExpressApplication>(AppModule);

  const isProd = process.env.NODE_ENV === 'production';

  // En dev : CORS large pour Flutter web (port aléatoire), multiples localhost, etc.
  // En prod : restreindre avec CORS_ORIGINS.
  if (isProd) {
    app.enableCors({
      origin:
        process.env.CORS_ORIGINS?.split(',').map((o) => o.trim()) ?? true,
      credentials: true,
      methods: ['GET', 'HEAD', 'PUT', 'PATCH', 'POST', 'DELETE', 'OPTIONS'],
      allowedHeaders: ['Content-Type', 'Authorization', 'Accept', 'X-Requested-With'],
    });
  } else {
    app.enableCors({
      origin: true,
      credentials: true,
      methods: ['GET', 'HEAD', 'PUT', 'PATCH', 'POST', 'DELETE', 'OPTIONS'],
      allowedHeaders: ['Content-Type', 'Authorization', 'Accept', 'X-Requested-With'],
    });
  }

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  // Même répertoire physique que Multer (voir getUploadsRoot + contrôleurs).
  app.useStaticAssets(uploadsDir, {
    prefix: '/uploads/',
    index: false,
  });

  const config = new DocumentBuilder()
    .setTitle('Ma3ak API')
    .setDescription(
      "API REST pour l'application Ma3ak - Application mobile intelligente destinée aux personnes en situation de handicap en Tunisie et à leurs accompagnants. Facilite la mobilité, l'autonomie et l'inclusion sociale.",
    )
    .setVersion('1.0')
    .addBearerAuth()
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api', app, document);

  const port = process.env.PORT || 3000;
  // En dev : écouter sur toutes les interfaces pour l’émulateur Android (10.0.2.2) et un vrai téléphone (IP LAN).
  if (isProd) {
    await app.listen(port);
  } else {
    await app.listen(port, '0.0.0.0');
  }
  console.log(`Ma3ak API running on http://localhost:${port}`);
  console.log(`Swagger docs: http://localhost:${port}/api`);
}

bootstrap();
