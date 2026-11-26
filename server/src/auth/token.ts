import jwt from 'jsonwebtoken';
import { env } from '../config/env.js';
import { USER_ROLES, type UserRole } from '../users/roles.js';

const ISSUER = 'tricycle-matching-api';
const AUDIENCE = 'tricycle-matching-client';

export interface AccessTokenPayload {
  sub: string;
  username: string;
  role: UserRole;
}

export interface VerifiedAccessToken {
  userId: string;
  username: string;
  role: UserRole;
}

export function signAccessToken(payload: AccessTokenPayload): string {
  return jwt.sign(
    {
      username: payload.username,
      role: payload.role,
    },
    env.JWT_SECRET,
    {
      subject: payload.sub,
      expiresIn: env.JWT_EXPIRES_IN,
      issuer: ISSUER,
      audience: AUDIENCE,
    },
  );
}

export function verifyAccessToken(token: string): VerifiedAccessToken {
  const decoded = jwt.verify(token, env.JWT_SECRET, {
    issuer: ISSUER,
    audience: AUDIENCE,
  });

  if (
    typeof decoded !== 'object' ||
    decoded === null ||
    typeof decoded.sub !== 'string' ||
    typeof decoded.username !== 'string' ||
    typeof decoded.role !== 'string' ||
    !USER_ROLES.includes(decoded.role as UserRole)
  ) {
    throw new Error('Invalid access token payload');
  }

  return {
    userId: decoded.sub,
    username: decoded.username,
    role: decoded.role as UserRole,
  };
}
