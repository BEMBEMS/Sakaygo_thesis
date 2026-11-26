import { Router } from 'express';
import { listActiveTodas } from '../users/repository.js';

export function createTodasRouter(): Router {
  const router = Router();

  router.get('/', async (_request, response) => {
    response.json({ todas: await listActiveTodas() });
  });

  return router;
}
