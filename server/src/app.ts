import cors from 'cors';
import express, { type ErrorRequestHandler, type RequestHandler } from 'express';
import helmet from 'helmet';
import { env } from './config/env.js';
import { HttpError } from './http/errors.js';
import { createAdminRouter } from './routes/admin.js';
import { createAuthRouter } from './routes/auth.js';
import {
  createHealthRouter,
  defaultHealthChecks,
  type HealthChecks,
} from './routes/health.js';
import { createTodasRouter } from './routes/todas.js';
import { createUsersRouter } from './routes/users.js';
import { createZonesRouter } from './routes/zones.js';

export function createApp(checks: HealthChecks = defaultHealthChecks): express.Express {
  const app = express();

  app.use(helmet());
  app.use(
    cors({
      origin: env.CORS_ORIGIN.split(',').map((origin) => origin.trim()),
    }),
  );
  app.use(express.json({ limit: '1mb' }));

  const healthRouter = createHealthRouter(checks);
  app.use('/health', healthRouter);
  app.use('/api/v1/health', healthRouter);

  app.use('/api/v1/auth', createAuthRouter());
  app.use('/api/v1/users', createUsersRouter());
  app.use('/api/v1/admin', createAdminRouter());
  app.use('/api/v1/todas', createTodasRouter());
  app.use('/api/v1/zones', createZonesRouter());

  const notFoundHandler: RequestHandler = (_request, response) => {
    response.status(404).json({ error: 'NOT_FOUND' });
  };

  const errorHandler: ErrorRequestHandler = (error, _request, response, _next) => {
    if (error instanceof HttpError) {
      response.status(error.status).json({
        error: error.code,
        message: error.message,
      });
      return;
    }

    if (
      error instanceof Error &&
      'code' in error &&
      error.code === '23505'
    ) {
      response.status(409).json({
        error: 'ACCOUNT_EXISTS',
        message: 'A unique record already exists',
      });
      return;
    }

    console.error(error);
    response.status(500).json({ error: 'INTERNAL_SERVER_ERROR' });
  };

  app.use(notFoundHandler);
  app.use(errorHandler);

  return app;
}
