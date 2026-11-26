import type { NextFunction, Request, RequestHandler, Response } from 'express';
import { forbidden, unauthorized } from '../http/errors.js';
import { verifyAccessToken } from './token.js';
import { findAuthUserById } from '../users/repository.js';
import type { AuthUser } from '../users/models.js';
import type { UserRole } from '../users/roles.js';

export const authenticate: RequestHandler = async (
  request: Request,
  _response: Response,
  next: NextFunction,
) => {
  try {
    const header = request.header('authorization');

    if (!header?.startsWith('Bearer ')) {
      throw unauthorized('AUTH_TOKEN_REQUIRED', 'Bearer token is required');
    }

    const token = header.slice(7).trim();

    if (!token) {
      throw unauthorized('AUTH_TOKEN_REQUIRED', 'Bearer token is required');
    }

    let verified;

    try {
      verified = verifyAccessToken(token);
    } catch {
      throw unauthorized('AUTH_TOKEN_INVALID', 'Access token is invalid');
    }

    const user = await findAuthUserById(verified.userId);

    if (!user || !user.isActive || user.role !== verified.role) {
      throw unauthorized('AUTH_USER_INVALID', 'Authenticated user is not active');
    }

    request.authUser = user;
    next();
  } catch (error) {
    next(error);
  }
};

export function requireRoles(...roles: UserRole[]): RequestHandler {
  return (request: Request, _response: Response, next: NextFunction) => {
    const user = request.authUser;

    if (!user) {
      next(unauthorized('AUTH_REQUIRED', 'Authentication is required'));
      return;
    }

    if (!roles.includes(user.role)) {
      next(forbidden('FORBIDDEN', 'This role cannot access the resource'));
      return;
    }

    next();
  };
}

export const requireVerifiedDriver: RequestHandler = (
  request: Request,
  _response: Response,
  next: NextFunction,
) => {
  const user = request.authUser;

  if (!user || user.role !== 'driver') {
    next(unauthorized('AUTH_REQUIRED', 'Driver authentication is required'));
    return;
  }

  if (user.verificationStatus !== 'verified') {
    next(
      forbidden(
        'DRIVER_NOT_VERIFIED',
        'Driver account is pending verification',
      ),
    );
    return;
  }

  next();
};

export function getAuthUser(request: Request): AuthUser {
  if (!request.authUser) {
    throw unauthorized('AUTH_REQUIRED', 'Authentication is required');
  }

  return request.authUser;
}
