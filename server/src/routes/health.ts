import { Router } from 'express';
import { checkDatabase } from '../db/pool.js';
import { checkRedis } from '../redis/client.js';
import { checkMatchingService } from '../services/matchingClient.js';

export type HealthState = 'ok' | 'unavailable';

export interface HealthChecks {
  database: () => Promise<boolean>;
  redis: () => Promise<boolean>;
  matching: () => Promise<boolean>;
}

export const defaultHealthChecks: HealthChecks = {
  database: checkDatabase,
  redis: checkRedis,
  matching: checkMatchingService,
};

function toState(available: boolean): HealthState {
  return available ? 'ok' : 'unavailable';
}

export function createHealthRouter(checks: HealthChecks = defaultHealthChecks): Router {
  const router = Router();

  router.get('/', async (_request, response) => {
    const [database, redis, matching] = await Promise.all([
      checks.database(),
      checks.redis(),
      checks.matching(),
    ]);

    const healthChecks = {
      database: toState(database),
      redis: toState(redis),
      matchingService: toState(matching),
    };

    const status = Object.values(healthChecks).every((state) => state === 'ok')
      ? 'ok'
      : 'degraded';

    response.status(200).json({
      service: 'tricycle-matching-api',
      status,
      checks: healthChecks,
      timestamp: new Date().toISOString(),
    });
  });

  return router;
}
