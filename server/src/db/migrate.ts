import { createHash } from 'node:crypto';
import { readFile, readdir } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { pool } from './pool.js';

const currentDirectory = path.dirname(fileURLToPath(import.meta.url));
const migrationsDirectory = path.resolve(
  currentDirectory,
  '..',
  '..',
  'migrations',
);

async function migrate(): Promise<void> {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS schema_migrations (
      name TEXT PRIMARY KEY,
      checksum TEXT NOT NULL,
      applied_at TIMESTAMPTZ NOT NULL DEFAULT now()
    )
  `);

  const files = (await readdir(migrationsDirectory))
    .filter((file) => file.endsWith('.sql'))
    .sort();

  for (const file of files) {
    const filePath = path.join(migrationsDirectory, file);
    const sql = await readFile(filePath, 'utf8');
    const checksum = createHash('sha256').update(sql).digest('hex');
    const existing = await pool.query(
      'SELECT checksum FROM schema_migrations WHERE name = $1',
      [file],
    );

    if (existing.rowCount) {
      if (existing.rows[0]?.checksum !== checksum) {
        throw new Error(`Migration checksum changed: ${file}`);
      }
      continue;
    }

    const client = await pool.connect();

    try {
      await client.query('BEGIN');
      await client.query(sql);
      await client.query(
        'INSERT INTO schema_migrations (name, checksum) VALUES ($1, $2)',
        [file, checksum],
      );
      await client.query('COMMIT');
      console.log(`Applied migration: ${file}`);
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }
}

migrate()
  .then(async () => {
    await pool.end();
  })
  .catch(async (error: unknown) => {
    console.error(error);
    await pool.end();
    process.exitCode = 1;
  });
