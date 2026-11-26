import { Router } from 'express';
import { authenticate } from '../auth/middleware.js';
import { locationValidationSchema } from '../auth/schemas.js';
import {
  findZoneByCode,
  listZones,
  validateLocationInZone,
} from '../geo/zoneService.js';
import { notFound } from '../http/errors.js';
import { parseRequestBody } from '../http/validation.js';

function pathParam(value: string | string[] | undefined): string {
  if (Array.isArray(value)) {
    return value[0] ?? '';
  }
  return value ?? '';
}

export function createZonesRouter(): Router {
  const router = Router();

  router.get('/', async (_request, response) => {
    response.json({ zones: await listZones(false) });
  });

  router.get('/:code', async (request, response) => {
    const zone = await findZoneByCode(pathParam(request.params.code), false);

    if (!zone) {
      throw notFound('ZONE_NOT_FOUND', 'Operating zone was not found');
    }

    response.json({ zone });
  });

  router.post('/:code/validate-location', authenticate, async (request, response) => {
    const payload = parseRequestBody(locationValidationSchema, request.body);
    const result = await validateLocationInZone(
      pathParam(request.params.code),
      payload.latitude,
      payload.longitude,
    );

    if (!result) {
      throw notFound('ZONE_NOT_FOUND', 'Operating zone was not found');
    }

    response.json(result);
  });

  return router;
}
