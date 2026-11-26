import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import request from 'supertest';
import { createApp } from '../src/app.js';
import type { HealthChecks } from '../src/routes/health.js';

const healthyChecks: HealthChecks = {
  database: async () => true,
  redis: async () => true,
  matching: async () => true,
};

describe('health endpoint', () => {
  it('reports ok when all dependency checks pass', async () => {
    const app = createApp(healthyChecks);
    const response = await request(app).get('/health').expect(200);

    assert.equal(response.body.service, 'tricycle-matching-api');
    assert.equal(response.body.status, 'ok');
    assert.equal(response.body.checks.database, 'ok');
    assert.equal(response.body.checks.redis, 'ok');
    assert.equal(response.body.checks.matchingService, 'ok');
  });

  it('reports degraded when a dependency is unavailable', async () => {
    const app = createApp({
      ...healthyChecks,
      redis: async () => false,
    });
    const response = await request(app).get('/api/v1/health').expect(200);

    assert.equal(response.body.status, 'degraded');
    assert.equal(response.body.checks.redis, 'unavailable');
  });

  it('returns a not-found response for unknown routes', async () => {
    const app = createApp(healthyChecks);
    const response = await request(app).get('/unknown').expect(404);

    assert.equal(response.body.error, 'NOT_FOUND');
  });
});
