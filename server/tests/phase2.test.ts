import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import { after, describe, it } from 'node:test';
import request from 'supertest';

import { createApp } from '../src/app.js';
import { hashPassword } from '../src/auth/password.js';
import { closeDatabase, pool } from '../src/db/pool.js';
import { hasUsableBoundary, pointInGeoJson } from '../src/geo/zoneService.js';
import type { HealthChecks } from '../src/routes/health.js';

const healthyChecks: HealthChecks = {
  database: async () => true,
  redis: async () => true,
  matching: async () => true,
};

const app = createApp(healthyChecks);
const prefix = `phase2_${Date.now()}_${randomUUID().slice(0, 6)}`;

after(async () => {
  await pool.query('DELETE FROM users WHERE username LIKE $1', [`${prefix}%`]);
  await closeDatabase(pool);
});

async function registerPassenger(roleLabel = 'passenger') {
  const username = `${prefix}_${roleLabel}`;
  const response = await request(app)
    .post('/api/v1/auth/passenger/register')
    .send({
      username,
      password: 'Password123!',
      firstName: 'Test',
      lastName: 'Passenger',
      passengerClass: 'priority',
    })
    .expect(201);

  assert.equal(response.body.user.role, 'passenger');

  const login = await request(app)
    .post('/api/v1/auth/login')
    .send({ identifier: username, password: 'Password123!' })
    .expect(200);

  return { username, token: login.body.token as string };
}

describe('phase 2 authentication', () => {
  it('registers, logs in, and reads the current passenger', async () => {
    const account = await registerPassenger('me');

    const me = await request(app)
      .get('/api/v1/auth/me')
      .set('Authorization', `Bearer ${account.token}`)
      .expect(200);

    assert.equal(me.body.user.username, account.username);

    const duplicate = await request(app)
      .post('/api/v1/auth/passenger/register')
      .send({
        username: account.username,
        password: 'Password123!',
        firstName: 'Test',
        lastName: 'Passenger',
      })
      .expect(409);

    assert.equal(duplicate.body.error, 'ACCOUNT_EXISTS');
  });

  it('blocks unverified drivers from driver-only endpoints', async () => {
    const toda = await pool.query<{ toda_org_id: string }>(
      "SELECT toda_id AS toda_org_id FROM toda_organizations WHERE code = 'TATMODA' LIMIT 1",
    );
    const todaOrgId = toda.rows[0]?.toda_org_id;
    assert.ok(todaOrgId);

    const username = `${prefix}_driver`;
    const registration = await request(app)
      .post('/api/v1/auth/driver/register')
      .send({
        username,
        password: 'Password123!',
        firstName: 'Test',
        lastName: 'Driver',
        todaOrgId,
        licenseNumber: `${prefix}-LIC`,
        todaMembershipId: `${prefix}-MEM`,
        vehiclePlateNumber: `${prefix.slice(0, 6)}-PLT`,
      })
      .expect(201);

    const zone = await pool.query<{ zone_id: string }>(
      "SELECT zone_id FROM operating_zones WHERE code = 'ZONE_1' LIMIT 1",
    );

    assert.equal(registration.body.user.role, 'driver');
    assert.equal(registration.body.user.verificationStatus, 'pending');
    assert.equal(registration.body.user.todaOrgId, todaOrgId);
    assert.equal(registration.body.user.operatingZoneId, zone.rows[0]?.zone_id);

    const login = await request(app)
      .post('/api/v1/auth/login')
      .send({ identifier: username, password: 'Password123!' })
      .expect(200);

    await request(app)
      .get('/api/v1/users/driver/me')
      .set('Authorization', `Bearer ${login.body.token}`)
      .expect(403);

    await pool.query(
      "UPDATE driver_profiles SET verification_status = 'verified' WHERE user_id = $1",
      [registration.body.user.userId],
    );

    const verifiedLogin = await request(app)
      .post('/api/v1/auth/login')
      .send({ identifier: username, password: 'Password123!' })
      .expect(200);

    const profile = await request(app)
      .get('/api/v1/users/driver/me')
      .set('Authorization', `Bearer ${verifiedLogin.body.token}`)
      .expect(200);

    assert.equal(profile.body.user.verificationStatus, 'verified');
    assert.equal(profile.body.profile.verificationStatus, 'verified');
  });

  it('enforces administrative role access and zone visibility', async () => {
    const passenger = await registerPassenger('forbidden');
    const username = `${prefix}_admin`;
    const passwordHash = await hashPassword('Password123!');

    await pool.query(
      `
      INSERT INTO users (
        username, email, password_hash, role, first_name, last_name
      )
      VALUES ($1, $2, $3, 'lgu', 'Test', 'Admin')
      `,
      [username, `${username}@example.test`, passwordHash],
    );

    const passengerAdminLogin = await request(app)
      .post('/api/v1/auth/admin/login')
      .send({ identifier: passenger.username, password: 'Password123!' })
      .expect(403);

    assert.equal(passengerAdminLogin.body.error, 'ADMIN_ACCESS_DENIED');

    const login = await request(app)
      .post('/api/v1/auth/admin/login')
      .send({ identifier: username, password: 'Password123!' })
      .expect(200);

    await request(app)
      .get('/api/v1/admin/zones')
      .set('Authorization', `Bearer ${passenger.token}`)
      .expect(403);

    const zones = await request(app)
      .get('/api/v1/admin/zones')
      .set('Authorization', `Bearer ${login.body.token}`)
      .expect(200);

    assert.equal(zones.body.zones.length, 2);

    const zone1 = zones.body.zones.find(
      (zone: { code: string }) => zone.code === 'ZONE_1',
    );
    const zone2 = zones.body.zones.find(
      (zone: { code: string }) => zone.code === 'ZONE_2',
    );

    const toda = await pool.query<{ toda_org_id: string }>(
      "SELECT toda_id AS toda_org_id FROM toda_organizations WHERE code = 'TATMODA' LIMIT 1",
    );

    assert.equal(zone1.zoneStatus, 'active');
    assert.equal(zone1.hasBoundary, false);
    assert.equal(zone1.todaOrgId, toda.rows[0]?.toda_org_id);
    assert.equal(zone2.zoneStatus, 'active');
    assert.equal(zone2.hasBoundary, false);

    const policy = await request(app)
      .get('/api/v1/admin/cross-zone-policy')
      .set('Authorization', `Bearer ${login.body.token}`)
      .expect(200);

    assert.equal(policy.body.crossZoneMatchingAllowed, false);
  });

  it('reports unconfigured boundaries without fabricating geometry', async () => {
    const passenger = await registerPassenger('zone');
    const response = await request(app)
      .post('/api/v1/zones/ZONE_1/validate-location')
      .set('Authorization', `Bearer ${passenger.token}`)
      .send({ latitude: 8.8, longitude: 125.5 })
      .expect(200);

    assert.equal(response.body.status, 'boundary_not_configured');
    assert.equal(response.body.within, null);
  });

  it('revokes access tokens on logout', async () => {
    const account = await registerPassenger('logout');

    await request(app)
      .post('/api/v1/auth/logout')
      .set('Authorization', `Bearer ${account.token}`)
      .expect(200);

    const afterLogout = await request(app)
      .get('/api/v1/auth/me')
      .set('Authorization', `Bearer ${account.token}`)
      .expect(401);

    assert.equal(afterLogout.body.error, 'AUTH_USER_INVALID');
  });

  it('locks an account after repeated failed logins', async () => {
    const account = await registerPassenger('lockout');

    for (let attempt = 0; attempt < 5; attempt += 1) {
      await request(app)
        .post('/api/v1/auth/login')
        .send({ identifier: account.username, password: 'WrongPassword123!' })
        .expect(401);
    }

    const locked = await request(app)
      .post('/api/v1/auth/login')
      .send({ identifier: account.username, password: 'Password123!' })
      .expect(401);

    assert.equal(locked.body.error, 'ACCOUNT_LOCKED');
  });

  it('rejects missing and malformed bearer tokens', async () => {
    await request(app).get('/api/v1/auth/me').expect(401);

    const malformed = await request(app)
      .get('/api/v1/auth/me')
      .set('Authorization', 'Bearer not-a-jwt')
      .expect(401);

    assert.equal(malformed.body.error, 'AUTH_TOKEN_INVALID');
  });

  it('validates usable GeoJSON boundaries before reporting them', () => {
    assert.equal(hasUsableBoundary(null), false);
    assert.equal(hasUsableBoundary({}), false);
    assert.equal(
      hasUsableBoundary({
        type: 'Polygon',
        coordinates: [
          [
            [0, 0],
            [1, 0],
            [1, 1],
            [0, 1],
            [0, 0],
          ],
        ],
      }),
      true,
    );
    assert.equal(
      pointInGeoJson(
        {
          type: 'Polygon',
          coordinates: [
            [
              [0, 0],
              [1, 0],
              [1, 1],
              [0, 1],
              [0, 0],
            ],
          ],
        },
        0.5,
        0.5,
      ),
      true,
    );
  });
});
