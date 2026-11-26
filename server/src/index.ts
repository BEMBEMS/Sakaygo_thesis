import { env } from './config/env.js';
import { createApp } from './app.js';
import { checkDatabase, closeDatabase, pool } from './db/pool.js';
import { checkRedis, closeRedis, redis } from './redis/client.js';
import { checkMatchingService } from './services/matchingClient.js';

const app = createApp({
  database: () => checkDatabase(pool),
  redis: () => checkRedis(redis),
  matching: () => checkMatchingService(env.MATCHING_SERVICE_URL),
});

const server = app.listen(env.PORT, () => {
  console.log(`API listening on http://localhost:${env.PORT}`);
});

async function shutdown(): Promise<void> {
  server.close(async () => {
    await closeRedis(redis);
    await closeDatabase(pool);
    process.exit(0);
  });
}

process.on('SIGINT', () => {
  void shutdown();
});

process.on('SIGTERM', () => {
  void shutdown();
});
