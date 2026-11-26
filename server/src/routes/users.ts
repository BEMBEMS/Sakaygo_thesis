import { Router } from 'express';
import {
  authenticate,
  getAuthUser,
  requireRoles,
  requireVerifiedDriver,
} from '../auth/middleware.js';
import { notFound } from '../http/errors.js';
import {
  getDriverProfile,
  getPassengerProfile,
} from '../users/repository.js';

export function createUsersRouter(): Router {
  const router = Router();

  router.get(
    '/passenger/me',
    authenticate,
    requireRoles('passenger'),
    async (request, response) => {
      const user = getAuthUser(request);
      const profile = await getPassengerProfile(user.userId);

      if (!profile) {
        throw notFound('PROFILE_NOT_FOUND', 'Passenger profile was not found');
      }

      response.json({ user, profile });
    },
  );

  router.get(
    '/driver/me',
    authenticate,
    requireRoles('driver'),
    requireVerifiedDriver,
    async (request, response) => {
      const user = getAuthUser(request);
      const profile = await getDriverProfile(user.userId);

      if (!profile) {
        throw notFound('PROFILE_NOT_FOUND', 'Driver profile was not found');
      }

      response.json({ user, profile });
    },
  );

  return router;
}
