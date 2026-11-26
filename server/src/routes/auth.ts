import { Router } from 'express';
import { authenticate, getAuthUser } from '../auth/middleware.js';
import { hashPassword, verifyPassword } from '../auth/password.js';
import {
  driverRegistrationSchema,
  loginSchema,
  passengerRegistrationSchema,
} from '../auth/schemas.js';
import { signAccessToken } from '../auth/token.js';
import { conflict, forbidden, unauthorized } from '../http/errors.js';
import { parseRequestBody } from '../http/validation.js';
import { isAdminRole } from '../users/roles.js';
import {
  createAuditLog,
  createDriver,
  createPassenger,
  findCredentialsByIdentifier,
  findActiveTodaWithZone,
} from '../users/repository.js';

function isUniqueViolation(error: unknown): boolean {
  return (
    error instanceof Error &&
    'code' in error &&
    error.code === '23505'
  );
}

function requireActiveToda(todaOrgId: string): Promise<{
  todaOrgId: string;
  zoneId: string | null;
} | null> {
  return findActiveTodaWithZone(todaOrgId);
}

export function createAuthRouter(): Router {
  const router = Router();

  router.post('/passenger/register', async (request, response) => {
    const payload = parseRequestBody(
      passengerRegistrationSchema,
      request.body,
    );

    try {
      const user = await createPassenger({
        username: payload.username,
        passwordHash: await hashPassword(payload.password),
        firstName: payload.firstName,
        lastName: payload.lastName,
        email: payload.email ?? null,
        phoneNumber: payload.phoneNumber ?? null,
        passengerClass: payload.passengerClass,
      });

      await createAuditLog(
        user.userId,
        'PASSENGER_REGISTERED',
        'users',
        user.userId,
        { passengerId: user.passengerId },
      );

      response.status(201).json({
        user,
        passengerId: user.passengerId,
      });
    } catch (error) {
      if (isUniqueViolation(error)) {
        throw conflict(
          'ACCOUNT_EXISTS',
          'Username, email, or phone number is already registered',
        );
      }
      throw error;
    }
  });

  router.post('/driver/register', async (request, response) => {
    const payload = parseRequestBody(driverRegistrationSchema, request.body);

    const toda = await requireActiveToda(payload.todaOrgId);

    if (!toda) {
      throw forbidden(
        'TODA_NOT_AUTHORIZED',
        'Selected TODA is not active or authorized',
      );
    }

    try {
      const user = await createDriver({
        username: payload.username,
        passwordHash: await hashPassword(payload.password),
        firstName: payload.firstName,
        lastName: payload.lastName,
        email: payload.email ?? null,
        phoneNumber: payload.phoneNumber ?? null,
        todaOrgId: payload.todaOrgId,
        licenseNumber: payload.licenseNumber,
        todaMembershipId: payload.todaMembershipId,
        vehiclePlateNumber: payload.vehiclePlateNumber,
      });

      await createAuditLog(
        user.userId,
        'DRIVER_REGISTERED',
        'users',
        user.userId,
        { driverId: user.driverId, zoneId: user.operatingZoneId },
      );

      response.status(201).json({
        user,
        driverId: user.driverId,
      });
    } catch (error) {
      if (isUniqueViolation(error)) {
        throw conflict(
          'ACCOUNT_EXISTS',
          'Username, email, phone number, license, membership ID, or plate number is already registered',
        );
      }
      throw error;
    }
  });

  router.post('/login', async (request, response) => {
    const payload = parseRequestBody(loginSchema, request.body);
    const credentials = await findCredentialsByIdentifier(payload.identifier);

    if (
      !credentials ||
      !credentials.user.isActive ||
      !(await verifyPassword(payload.password, credentials.passwordHash))
    ) {
      throw unauthorized('INVALID_CREDENTIALS', 'Invalid credentials');
    }

    const token = signAccessToken({
      sub: credentials.user.userId,
      username: credentials.user.username,
      role: credentials.user.role,
    });

    await createAuditLog(
      credentials.user.userId,
      'LOGIN',
      'users',
      credentials.user.userId,
      { role: credentials.user.role },
    );

    response.json({
      token,
      tokenType: 'Bearer',
      user: credentials.user,
    });
  });

  router.post('/admin/login', async (request, response) => {
    const payload = parseRequestBody(loginSchema, request.body);
    const credentials = await findCredentialsByIdentifier(payload.identifier);

    if (
      !credentials ||
      !credentials.user.isActive ||
      !(await verifyPassword(payload.password, credentials.passwordHash))
    ) {
      throw unauthorized('INVALID_CREDENTIALS', 'Invalid credentials');
    }

    if (!isAdminRole(credentials.user.role)) {
      throw forbidden(
        'ADMIN_ACCESS_DENIED',
        'Account is not authorized for the admin dashboard',
      );
    }

    const token = signAccessToken({
      sub: credentials.user.userId,
      username: credentials.user.username,
      role: credentials.user.role,
    });

    await createAuditLog(
      credentials.user.userId,
      'ADMIN_LOGIN',
      'users',
      credentials.user.userId,
      { role: credentials.user.role },
    );

    response.json({
      token,
      tokenType: 'Bearer',
      user: credentials.user,
    });
  });

  router.get('/me', authenticate, (request, response) => {
    response.json({ user: getAuthUser(request) });
  });

  return router;
}
