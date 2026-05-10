import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { App } from 'supertest/types';

// eslint-disable-next-line @typescript-eslint/no-require-imports
const request = require('supertest') as typeof import('supertest');
import { AppModule } from '../src/app.module';

describe('Santé — SOS notifie les contacts urgence (e2e)', () => {
  let app: INestApplication<App>;
  const suffix = `${Date.now()}-${Math.random().toString(36).slice(2, 9)}`;
  const safe = suffix.replace(/[^a-z0-9]/gi, '');
  const emailHandi = `sos.handi.${safe}@example.com`;
  const emailAcc = `sos.acc.${safe}@example.com`;
  const pass = `Secret1!${suffix}`;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
      }),
    );
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  it('POST /sos-alerts crée une alerte et une notification SOS_ALERT chez chaque contact urgence', async () => {
    await request(app.getHttpServer())
      .post('/users/register')
      .send({
        nom: 'Handi',
        prenom: 'SOS',
        email: emailHandi,
        password: pass,
        role: 'HANDICAPE',
      })
      .expect(201);

    await request(app.getHttpServer())
      .post('/users/register')
      .send({
        nom: 'Acc',
        prenom: 'SOS',
        email: emailAcc,
        password: pass,
        role: 'ACCOMPAGNANT',
      })
      .expect(201);

    const loginAcc = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email: emailAcc, password: pass })
      .expect(201);
    const accId = loginAcc.body.user._id as string;
    const tokenAcc = loginAcc.body.access_token as string;

    const loginHandi = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email: emailHandi, password: pass })
      .expect(201);
    const tokenHandi = loginHandi.body.access_token as string;

    await request(app.getHttpServer())
      .post('/emergency-contacts')
      .set('Authorization', `Bearer ${tokenHandi}`)
      .send({ accompagnantId: accId, ordrePriorite: 1 })
      .expect(201);

    await request(app.getHttpServer())
      .post('/sos-alerts')
      .set('Authorization', `Bearer ${tokenHandi}`)
      .send({ latitude: 36.8065, longitude: 10.1815 })
      .expect(201);

    const notifs = await request(app.getHttpServer())
      .get('/notifications')
      .set('Authorization', `Bearer ${tokenAcc}`)
      .expect(200);

    expect(notifs.body.data?.length).toBeGreaterThanOrEqual(1);
    const sosNotif = notifs.body.data.find(
      (n: { type?: string }) => n.type === 'SOS_ALERT',
    );
    expect(sosNotif).toBeDefined();
    expect(String(sosNotif.message)).toContain('36.80650');
  });
});
