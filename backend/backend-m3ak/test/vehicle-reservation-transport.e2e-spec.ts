import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { App } from 'supertest/types';

// supertest v7 + ts-jest : export CJS, éviter default import
// eslint-disable-next-line @typescript-eslint/no-require-imports
const request = require('supertest') as typeof import('supertest');
import { AppModule } from '../src/app.module';

describe('Vehicle reservation → transport available (e2e)', () => {
  let app: INestApplication<App>;
  const suffix = `${Date.now()}-${Math.random().toString(36).slice(2, 9)}`;
  const passHandi = `Secret1!${suffix}`;
  const passDriver = `Secret2!${suffix}`;
  const safe = suffix.replace(/[^a-z0-9]/gi, '');
  const emailHandi = `handi.vr.${safe}@example.com`;
  const emailDriver = `driver.vr.${safe}@example.com`;

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

  it('POST vehicle-reservation puis GET transport/available (proprio véhicule) non vide', async () => {
    await request(app.getHttpServer())
      .post('/users/register')
      .send({
        nom: 'Benef',
        prenom: 'Test',
        email: emailHandi,
        password: passHandi,
        role: 'HANDICAPE',
      })
      .expect(201);

    await request(app.getHttpServer())
      .post('/users/register')
      .send({
        nom: 'Chauffeur',
        prenom: 'Test',
        email: emailDriver,
        password: passDriver,
        role: 'ACCOMPAGNANT',
        typeAccompagnant: 'Chauffeurs solidaires',
        disponible: true,
      })
      .expect(201);

    const loginDriver = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email: emailDriver, password: passDriver })
      .expect(201);
    const tokenDriver = loginDriver.body.access_token as string;

    const createVeh = await request(app.getHttpServer())
      .post('/vehicles')
      .set('Authorization', `Bearer ${tokenDriver}`)
      .send({
        marque: 'Peugeot',
        modele: 'Partner',
        immatriculation: `VR-E2E-${suffix}`,
        statut: 'VALIDE',
        accessibilite: { rampeAcces: true },
      })
      .expect(201);
    const vehicleId = createVeh.body._id as string;

    const loginHandi = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email: emailHandi, password: passHandi })
      .expect(201);
    const tokenHandi = loginHandi.body.access_token as string;

    const dateStr = new Date().toISOString().slice(0, 10);
    await request(app.getHttpServer())
      .post('/vehicle-reservations')
      .set('Authorization', `Bearer ${tokenHandi}`)
      .send({
        vehicleId,
        date: dateStr,
        heure: '15:30',
        lieuDepart: 'Tunis centre',
        lieuDestination: 'La Marsa',
        besoinsSpecifiques: 'rampe',
      })
      .expect(201);

    const avail = await request(app.getHttpServer())
      .get('/transport/available')
      .set('Authorization', `Bearer ${tokenDriver}`)
      .expect(200);

    expect(Array.isArray(avail.body)).toBe(true);
    expect(avail.body.length).toBeGreaterThanOrEqual(1);
    const linked = avail.body.find(
      (t: { vehicleId?: { _id?: string } }) =>
        t.vehicleId && String(t.vehicleId._id ?? t.vehicleId) === vehicleId,
    );
    expect(linked).toBeDefined();
    expect(linked.typeTransport).toBe('QUOTIDIEN');
  });

  it('POST /transport classique reste utilisable (organisateur)', async () => {
    const s = `${Date.now()}-${Math.random().toString(36).slice(2, 9)}`;
    const em = `solo.${s.replace(/[^a-z0-9]/gi, '')}@example.com`;
    await request(app.getHttpServer())
      .post('/users/register')
      .send({
        nom: 'Solo',
        prenom: 'Handi',
        email: em,
        password: `Pw12345!${s.replace(/[^a-z0-9]/gi, '')}`,
        role: 'HANDICAPE',
      })
      .expect(201);

    const login = await request(app.getHttpServer())
      .post('/auth/login')
      .send({
        email: em,
        password: `Pw12345!${s.replace(/[^a-z0-9]/gi, '')}`,
      })
      .expect(201);

    const res = await request(app.getHttpServer())
      .post('/transport')
      .set('Authorization', `Bearer ${login.body.access_token}`)
      .send({
        typeTransport: 'QUOTIDIEN',
        depart: 'A',
        destination: 'B',
        latitudeDepart: 36.8,
        longitudeDepart: 10.18,
        latitudeArrivee: 36.81,
        longitudeArrivee: 10.19,
        dateHeure: new Date().toISOString(),
        besoinsAssistance: [],
      })
      .expect(201);

    expect(res.body.statut).toBe('EN_ATTENTE');
    expect(res.body.vehicleId).toBeNull();
  });
});
