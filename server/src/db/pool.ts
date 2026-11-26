import pg from 'pg';
import { env } from '../config/env.js';

export const pool = new pg.Pool({
  connectionString: env.DATABASE_URL,
  max: 10,
  idleTimeoutMillis: 30_000,
  connectionTimeoutMillis: 5_000,
});

export type Database = pg.Pool;

export async function checkDatabase(db: Database = pool): Promise<boolean> {
  const result = await db.query<{ ok: number | boolean }>('SELECT 1 AS ok');
  return result.rows[0]?.ok === 1 || result.rows[0]?.ok === true;
}

export async function closeDatabase(db: Database = pool): Promise<void> {
  await db.end();
}
