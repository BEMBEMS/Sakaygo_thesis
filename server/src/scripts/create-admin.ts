import { env } from '../config/env.js';
import { hashPassword } from '../auth/password.js';
import { closeDatabase, pool } from '../db/pool.js';
import { createAuditLog } from '../users/repository.js';

async function createAdmin(): Promise<void> {
  const username = env.ADMIN_BOOTSTRAP_USERNAME;
  const password = env.ADMIN_BOOTSTRAP_PASSWORD;
  const email = env.ADMIN_BOOTSTRAP_EMAIL;
  const firstName = env.ADMIN_BOOTSTRAP_FIRST_NAME;
  const lastName = env.ADMIN_BOOTSTRAP_LAST_NAME;

  if (!username || !password || !email || !firstName || !lastName) {
    throw new Error(
      'Set ADMIN_BOOTSTRAP_USERNAME, PASSWORD, EMAIL, FIRST_NAME, and LAST_NAME',
    );
  }

  const existing = await pool.query(
    'SELECT 1 FROM users WHERE username = $1 OR email = $2 LIMIT 1',
    [username, email],
  );

  if (existing.rowCount) {
    throw new Error('Bootstrap username or email is already registered');
  }

  const passwordHash = await hashPassword(password);
  const result = await pool.query<{ user_id: string }>(
    `
    INSERT INTO users (
      username, email, password_hash, role, first_name, last_name
    )
    VALUES ($1, $2, $3, $4, $5, $6)
    RETURNING user_id
    `,
    [
      username,
      email,
      passwordHash,
      env.ADMIN_BOOTSTRAP_ROLE,
      firstName,
      lastName,
    ],
  );

  const userId = result.rows[0]?.user_id;

  if (!userId) {
    throw new Error('Failed to create bootstrap account');
  }

  await createAuditLog(null, 'ADMIN_BOOTSTRAPPED', 'users', userId, {
    role: env.ADMIN_BOOTSTRAP_ROLE,
  });

  console.log(`Created ${env.ADMIN_BOOTSTRAP_ROLE} account: ${username}`);
}

createAdmin()
  .then(async () => {
    await closeDatabase(pool);
  })
  .catch(async (error: unknown) => {
    console.error(error);
    await closeDatabase(pool);
    process.exitCode = 1;
  });
