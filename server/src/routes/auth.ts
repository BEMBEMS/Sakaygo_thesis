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
  recordFailedLogin,
  resetLoginAttempts,
  revokeUserTokens,
  TodaNotAuthorizedError,
  type LoginCredentials,
} from '../users/repository.js';

const MAX_FAILED_LOGIN_ATTEMPTS = 5;
const LOGIN_LOCKOUT_MINUTES = 15;
const INVALID_CREDENTIALS_MESSAGE = 'Invalid credentials';

function isUniqueViolation(error: unknown): boolean {
  return error instanceof Error && 'code' in error && error.code === '23505';
}

function isLocked(credentials: LoginCredentials): boolean {
  if (!credentials.lockedUntil) {
    return false;
  }

  return new Date(credentials.lockedUntil).getTime() > Date.now();
}

async function authenticateCredentials(
  identifier: string,
  password: string,
): Promise<LoginCredentials> {
  const credentials = await findCredentialsByIdentifier(identifier);

  if (!credentials) {
    await createAuditLog(null, 'LOGIN_FAILED', 'users', null, {
      reason: 'UNKNOWN_IDENTIFIER',
    });
    throw unauthorized('INVALID_CREDENTIALS', INVALID_CREDENTIALS_MESSAGE);
  }

  if (isLocked(credentials)) {
    await createAuditLog(
      credentials.user.userId,
      'LOGIN_LOCKED',
      'users',
      credentials.user.userId,
    );
    throw unauthorized(
      'ACCOUNT_LOCKED',
      'Account is temporarily locked. Try again later.',
    );
  }

  const passwordMatches = await verifyPassword(password, credentials.passwordHash);

  if (!credentials.user.isActive || !passwordMatches) {
    if (credentials.user.isActive) {
      await recordFailedLogin(
        credentials.user.userId,
        MAX_FAILED_LOGIN_ATTEMPTS,
        LOGIN_LOCKOUT_MINUTES,
      );
    }

    await createAuditLog(
      credentials.user.userId,
      'LOGIN_FAILED',
      'users',
      credentials.user.userId,
      { reason: credentials.user.isActive ? 'BAD_PASSWORD' : 'INACTIVE_ACCOUNT' },
    );
    throw unauthorized('INVALID_CREDENTIALS', INVALID_CREDENTIALS_MESSAGE);
  }

  await resetLoginAttempts(credentials.user.userId);
  return credentials;
}

function issueAccessToken(credentials: LoginCredentials): string {
  return signAccessToken({
    sub: credentials.user.userId,
    username: credentials.user.username,
    role: credentials.user.role,
    tokenVersion: credentials.tokenVersion,
  });
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
      if (error instanceof TodaNotAuthorizedError) {
        throw forbidden(
          'TODA_NOT_AUTHORIZED',
          'Selected TODA is not active or has no active operating zone',
        );
      }
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
    const credentials = await authenticateCredentials(
      payload.identifier,
      payload.password,
    );
    const token = issueAccessToken(credentials);

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
    const credentials = await authenticateCredentials(
      payload.identifier,
      payload.password,
    );

    if (!isAdminRole(credentials.user.role)) {
      await createAuditLog(
        credentials.user.userId,
        'ADMIN_LOGIN_DENIED',
        'users',
        credentials.user.userId,
        { role: credentials.user.role },
      );
      throw forbidden(
        'ADMIN_ACCESS_DENIED',
        'Account is not authorized for the admin dashboard',
      );
    }

    const token = issueAccessToken(credentials);

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

  router.post('/logout', authenticate, async (request, response) => {
    const user = getAuthUser(request);
    await revokeUserTokens(user.userId);

    await createAuditLog(
      user.userId,
      'LOGOUT',
      'users',
      user.userId,
    );

    response.json({ success: true });
  });

  router.get('/me', authenticate, (request, response) => {
    response.json({ user: getAuthUser(request) });
  });

  return router;
}
