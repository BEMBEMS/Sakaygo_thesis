import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import { after, describe, it } from 'node:test';
import request from 'supertest';

import { createApp } from '../src/app.js';
import { closeDatabase, pool } from '../src/db/pool.js';
import type { HealthChecks } from '../src/routes/health.js';

const healthyChecks: HealthChecks = {
  database: async () => true,
  redis: async () => true,
  matching: async () => true,
};

const app = createApp(healthyChecks);
const prefix = `phase3_${Date.now()}_${randomUUID().slice(0, 6)}`;

after(async () => {
  await pool.query('DELETE FROM users WHERE username LIKE $1', [`${prefix}%`]);
  await closeDatabase(pool);
});

async function createPassengerSession(label: string) {
  const username = `${prefix}_${label}`;
  await request(app)
    .post('/api/v1/auth/passenger/register')
    .send({
      username,
      password: 'Password123!',
      firstName: 'Phase',
      lastName: label,
      passengerClass: label === 'priority' ? 'priority' : 'standard',
    })
    .expect(201);

  const login = await request(app)
    .post('/api/v1/auth/login')
    .send({ identifier: username, password: 'Password123!' })
    .expect(200);

  return { username, token: login.body.token as string };
}

describe('phase 3 passenger workflow', () => {
  it('requires passenger authentication', async () => {
    await request(app).patch('/api/v1/passenger/me/location').expect(401);
    await request(app).get('/api/v1/passenger/requests/active').expect(401);
    await request(app)
      .post('/api/v1/passenger/requests/waiting-here')
      .send({})
      .expect(401);
  });

  it('stores the passenger current location', async () => {
    const passenger = await createPassengerSession('location');
    const response = await request(app)
      .patch('/api/v1/passenger/me/location')
      .set('Authorization', `Bearer ${passenger.token}`)
      .send({ latitude: 8.7286, longitude: 125.4944 })
      .expect(200);

    assert.equal(response.body.profile.currentLatitude, 8.7286);
    assert.equal(response.body.profile.currentLongitude, 125.4944);

    const profile = await request(app)
      .get('/api/v1/users/passenger/me')
      .set('Authorization', `Bearer ${passenger.token}`)
      .expect(200);

    assert.equal(profile.body.profile.currentLatitude, 8.7286);
    assert.equal(profile.body.profile.currentLongitude, 125.4944);
  });

  it('creates and reads a waiting-here request', async () => {
    const passenger = await createPassengerSession('priority');
    const response = await request(app)
      .post('/api/v1/passenger/requests/waiting-here')
      .set('Authorization', `Bearer ${passenger.token}`)
      .send({
        pickupLatitude: 8.7286,
        pickupLongitude: 125.4944,
        destinationName: 'Del Monte proper',
        destinationLatitude: 8.7412,
        destinationLongitude: 125.5071,
      })
      .expect(201);

    const created = response.body.request;

    assert.equal(created.pickupLatitude, 8.7286);
    assert.equal(created.pickupLongitude, 125.4944);
    assert.equal(created.destinationName, 'Del Monte proper');
    assert.equal(created.passengerClass, 'priority');
    assert.equal(created.status, 'searching');
    assert.ok(created.requestedAt);

    const active = await request(app)
      .get('/api/v1/passenger/requests/active')
      .set('Authorization', `Bearer ${passenger.token}`)
      .expect(200);

    assert.equal(active.body.request.requestId, created.requestId);

    const detail = await request(app)
      .get(`/api/v1/passenger/requests/${created.requestId}`)
      .set('Authorization', `Bearer ${passenger.token}`)
      .expect(200);

    assert.equal(detail.body.request.destinationName, 'Del Monte proper');
  });

  it('prevents duplicate active requests and isolates ownership', async () => {
    const first = await createPassengerSession('first');
    const second = await createPassengerSession('second');
    const payload = {
      pickupLatitude: 8.7286,
      pickupLongitude: 125.4944,
      destinationName: 'Talacogon Proper',
      destinationLatitude: 8.7301,
      destinationLongitude: 125.4956,
    };

    const created = await request(app)
      .post('/api/v1/passenger/requests/waiting-here')
      .set('Authorization', `Bearer ${first.token}`)
      .send(payload)
      .expect(201);

    const duplicate = await request(app)
      .post('/api/v1/passenger/requests/waiting-here')
      .set('Authorization', `Bearer ${first.token}`)
      .send(payload)
      .expect(409);

    assert.equal(duplicate.body.error, 'ACTIVE_REQUEST_EXISTS');

    await request(app)
      .get(`/api/v1/passenger/requests/${created.body.request.requestId}`)
      .set('Authorization', `Bearer ${second.token}`)
      .expect(404);
  });

  it('rejects invalid coordinates and empty destinations', async () => {
    const passenger = await createPassengerSession('validation');

    await request(app)
      .patch('/api/v1/passenger/me/location')
      .set('Authorization', `Bearer ${passenger.token}`)
      .send({ latitude: 91, longitude: 125 })
      .expect(400);

    const response = await request(app)
      .post('/api/v1/passenger/requests/waiting-here')
      .set('Authorization', `Bearer ${passenger.token}`)
      .send({
        pickupLatitude: 8.7286,
        pickupLongitude: 125.4944,
        destinationName: '   ',
        destinationLatitude: 8.7412,
        destinationLongitude: 125.5071,
      })
      .expect(400);

    assert.equal(response.body.error, 'VALIDATION_ERROR');
  });
});
