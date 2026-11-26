import 'dotenv/config';
import { z } from 'zod';

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().int().positive().default(3000),
  DATABASE_URL: z
    .string()
    .min(1)
    .default('postgres://postgres@localhost:5432/tricycle_matching_dev'),
  REDIS_URL: z.string().min(1).default('redis://localhost:6379'),
  MATCHING_SERVICE_URL: z.string().min(1).default('http://127.0.0.1:8000'),
  CORS_ORIGIN: z
    .string()
    .min(1)
    .default(
      'http://localhost:5173,http://localhost:3000,http://127.0.0.1:3000',
    ),
  JWT_SECRET: z
    .string()
    .min(32)
    .default('development-only-jwt-secret-change-before-production-123456'),
  JWT_EXPIRES_IN: z.string().min(1).default('12h'),
  OSRM_BASE_URL: z
    .string()
    .min(1)
    .default('https://router.project-osrm.org'),
  ADMIN_BOOTSTRAP_USERNAME: z.string().min(1).optional(),
  ADMIN_BOOTSTRAP_PASSWORD: z.string().min(8).optional(),
  ADMIN_BOOTSTRAP_EMAIL: z.string().email().optional(),
  ADMIN_BOOTSTRAP_FIRST_NAME: z.string().min(1).optional(),
  ADMIN_BOOTSTRAP_LAST_NAME: z.string().min(1).optional(),
  ADMIN_BOOTSTRAP_ROLE: z
    .enum(['admin', 'lgu', 'toda'])
    .default('admin'),
});

export type Env = z.infer<typeof envSchema>;

export const env: Env = envSchema.parse(process.env);
