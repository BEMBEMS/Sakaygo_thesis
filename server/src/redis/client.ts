import { Redis } from 'ioredis';
import { env } from '../config/env.js';

export const redis = new Redis(env.REDIS_URL, {
  lazyConnect: true,
  enableOfflineQueue: false,
  connectTimeout: 1_500,
    maxRetriesPerRequest: 1,
});

redis.on('error', () => undefined);

let pendingConnection
: Promise<void> | null = null;

async function ensureConnected(client: Redis): Promise<void> {
  if (client.status === 'ready') {
    return;
  }

  if (client.status === 'connecting' || client.status === 'reconnecting') {
    return;
  }

  if (!pendingConnection) {
    pendingConnection = client
      .connect()
      .then(() => undefined)
      .catch((error: unknown) => {
        if (error instanceof Error && error.message.includes('already connected')) {
          return;
        }
        throw error;
      })
      .finally(() => {
        pendingConnection = null;
      });
  }

  await pendingConnection;
}

export async function checkRedis(client: Redis = redis): Promise<boolean> {
  try {
    await ensureConnected(client);
    return (await client.ping()) === 'PONG';
  } catch {
    return false;
  }
}

export async function closeRedis(client: Redis = redis): Promise<void> {
  if (client.status !== 'end') {
    client.disconnect();
  }
}
