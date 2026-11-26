import { Router } from 'express';
import {
  createPassengerRequestSchema,
  updatePassengerLocationSchema,
} from '../auth/schemas.js';
import { authenticate, getAuthUser, requireRoles } from '../auth/middleware.js';
import { conflict, notFound } from '../http/errors.js';
import { parseRequestBody } from '../http/validation.js';
import {
  createAuditLog,
  createPassengerRequest,
  findActivePassengerRequest,
  getPassengerRequestById,
  updatePassengerCurrentLocation,
} from '../users/repository.js';

function pathParam(value: string | string[] | undefined): string {
  if (Array.isArray(value)) {
    return value[0] ?? '';
  }
  return value ?? '';
}

export function createPassengerRouter(): Router {
  const router = Router();

  router.use(authenticate, requireRoles('passenger'));

  router.patch('/me/location', async (request, response) => {
    const payload = parseRequestBody(updatePassengerLocationSchema, request.body);
    const user = getAuthUser(request);
    const profile = await updatePassengerCurrentLocation(
      user.userId,
      payload.latitude,
      payload.longitude,
    );

    if (!profile) {
      throw notFound('PROFILE_NOT_FOUND', 'Passenger profile was not found');
    }

    await createAuditLog(
      user.userId,
      'PASSENGER_LOCATION_UPDATED',
      'passenger_profiles',
      profile.passengerId,
      {
        latitude: payload.latitude,
        longitude: payload.longitude,
      },
    );

    response.json({ profile });
  });

  router.post('/requests/waiting-here', async (request, response) => {
    const payload = parseRequestBody(createPassengerRequestSchema, request.body);
    const user = getAuthUser(request);

    if (!user.passengerId) {
      throw notFound('PROFILE_NOT_FOUND', 'Passenger profile was not found');
    }

    const activeRequest = await findActivePassengerRequest(user.passengerId);

    if (activeRequest) {
      throw conflict(
        'ACTIVE_REQUEST_EXISTS',
        'An active waiting request already exists',
      );
    }

    const passengerRequest = await createPassengerRequest({
      userId: user.userId,
      pickupLatitude: payload.pickupLatitude,
      pickupLongitude: payload.pickupLongitude,
      destinationName: payload.destinationName,
      destinationLatitude: payload.destinationLatitude,
      destinationLongitude: payload.destinationLongitude,
    });

    if (!passengerRequest) {
      throw notFound('PROFILE_NOT_FOUND', 'Passenger profile was not found');
    }

    await createAuditLog(
      user.userId,
      'WAITING_HERE_REQUEST_CREATED',
      'passenger_requests',
      passengerRequest.requestId,
      {
        destinationName: passengerRequest.destinationName,
        passengerClass: passengerRequest.passengerClass,
      },
    );

    response.status(201).json({ request: passengerRequest });
  });

  router.get('/requests/active', async (request, response) => {
    const user = getAuthUser(request);

    if (!user.passengerId) {
      throw notFound('PROFILE_NOT_FOUND', 'Passenger profile was not found');
    }

    const activeRequest = await findActivePassengerRequest(user.passengerId);
    response.json({ request: activeRequest });
  });

  router.get('/requests/:requestId', async (request, response) => {
    const user = getAuthUser(request);

    if (!user.passengerId) {
      throw notFound('PROFILE_NOT_FOUND', 'Passenger profile was not found');
    }

    const passengerRequest = await getPassengerRequestById(
      pathParam(request.params.requestId),
      user.passengerId,
    );

    if (!passengerRequest) {
      throw notFound('REQUEST_NOT_FOUND', 'Passenger request was not found');
    }

    response.json({ request: passengerRequest });
  });

  return router;
}
