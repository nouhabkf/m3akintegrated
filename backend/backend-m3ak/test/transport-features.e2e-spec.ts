import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { App } from 'supertest/types';

// eslint-disable-next-line @typescript-eslint/no-require-imports
const request = require('supertest') as typeof import('supertest');
import { AppModule } from '../src/app.module';

describe('Transport — partage, matching, tri available (e2e)', () => {
  let app: INestApplication<App>;
  const suffix = `${Date.now()}-${Math.random().toString(36).slice(2, 9)}`;
  const safe = suffix.replace(/[^a-z0-9]/gi, '');
  const pass = `Secret1!${suffix}`;
  const emailPassager = `passager.tf.${safe}@example.com`;
  const emailChauffeur = `chauffeur.tf.${safe}@example.com`;

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

  it('GET /transport/matching accepte besoinsAssistance en query', async () => {
    await request(app.getHttpServer())
      .post('/users/register')
      .send({
        nom: 'Passager',
        prenom: 'Test',
        email: emailPassager,
        password: pass,
        role: 'HANDICAPE',
      })
      .expect(201);

    const login = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email: emailPassager, password: pass })
      .expect(201);
    const token = login.body.access_token as string;

    const res = await request(app.getHttpServer())
      .get('/transport/matching')
      .query({
        latitude: 36.8065,
        longitude: 10.1815,
        besoinsAssistance: ['rampe', 'inconnu_xyz'],
      })
      .set('Authorization', `Bearer ${token}`)
      .expect(200);

    if (res.body?.source === 'nestjs') {
      expect(Array.isArray(res.body.accompagnants)).toBe(true);
      if (res.body.accompagnants[0]) {
        expect(res.body.accompagnants[0]).toHaveProperty('subscores');
        expect(res.body.accompagnants[0]).toHaveProperty('scoreMatching');
        expect(res.body.accompagnants[0]).toHaveProperty('vehicles');
      }
    }
  });

  it('POST /transport/matching + tri available (priorité médicale avant URGENCE)', async () => {
    await request(app.getHttpServer())
      .post('/users/register')
      .send({
        nom: 'Chauffeur',
        prenom: 'Test',
        email: emailChauffeur,
        password: pass,
        role: 'ACCOMPAGNANT',
        typeAccompagnant: 'Chauffeurs solidaires',
        disponible: true,
      })
      .expect(201);

    const loginC = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email: emailChauffeur, password: pass })
      .expect(201);
    const tokenC = loginC.body.access_token as string;

    const loginP = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email: emailPassager, password: pass })
      .expect(201);
    const tokenP = loginP.body.access_token as string;

    const postMatch = await request(app.getHttpServer())
      .post('/transport/matching')
      .set('Authorization', `Bearer ${tokenP}`)
      .send({
        latitude: 36.8065,
        longitude: 10.1815,
        besoinsAssistance: ['rampe'],
      })
      .expect(201);
    expect(postMatch.body.source === 'nestjs' || postMatch.body.source === 'flask').toBeTruthy();

    const iso = new Date(Date.now() + 3600_000).toISOString();
    await request(app.getHttpServer())
      .post('/transport')
      .set('Authorization', `Bearer ${tokenP}`)
      .send({
        typeTransport: 'URGENCE',
        depart: 'A',
        destination: 'B',
        latitudeDepart: 36.81,
        longitudeDepart: 10.19,
        latitudeArrivee: 36.82,
        longitudeArrivee: 10.2,
        dateHeure: iso,
      })
      .expect(201);

    await request(app.getHttpServer())
      .post('/transport')
      .set('Authorization', `Bearer ${tokenP}`)
      .send({
        typeTransport: 'QUOTIDIEN',
        prioriteMedicale: true,
        motifTrajet: 'MEDICAL',
        depart: 'C',
        destination: 'D',
        latitudeDepart: 36.815,
        longitudeDepart: 10.195,
        latitudeArrivee: 36.825,
        longitudeArrivee: 10.205,
        dateHeure: iso,
      })
      .expect(201);

    const avail = await request(app.getHttpServer())
      .get('/transport/available')
      .set('Authorization', `Bearer ${tokenC}`)
      .expect(200);

    expect(Array.isArray(avail.body)).toBe(true);
    const med = avail.body.findIndex((x: { prioriteMedicale?: boolean }) => x.prioriteMedicale === true);
    const urg = avail.body.findIndex(
      (x: { typeTransport?: string; prioriteMedicale?: boolean }) =>
        x.typeTransport === 'URGENCE' && !x.prioriteMedicale,
    );
    if (med >= 0 && urg >= 0) {
      expect(med).toBeLessThan(urg);
    }
  });
});
