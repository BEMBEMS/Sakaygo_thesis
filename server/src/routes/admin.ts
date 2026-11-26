import { Router } from 'express';
import { authenticate, getAuthUser, requireRoles } from '../auth/middleware.js';
import {
  findZoneByCode,
  isCrossZoneAllowed,
  listZones,
} from '../geo/zoneService.js';
import { notFound } from '../http/errors.js';
import { ADMIN_ROLES } from '../users/roles.js';

export function createAdminRouter(): Router {
  const router = Router();

  router.use(authenticate, requireRoles(...ADMIN_ROLES));

  router.get('/me', (request, response) => {
    response.json({ user: getAuthUser(request) });
  });

  router.get('/zones', async (_request, response) => {
    response.json({ zones: await listZones(true) });
  });

  router.get('/zones/:code', async (request, response) => {
    const zone = await findZoneByCode(request.params.code, true);

    if (!zone) {
      throw notFound('ZONE_NOT_FOUND', 'Operating zone was not found');
    }

    response.json({ zone });
  });

  router.get('/cross-zone-policy', async (_request, response) => {
    response.json({ crossZoneMatchingAllowed: await isCrossZoneAllowed() });
  });

  return router;
}
