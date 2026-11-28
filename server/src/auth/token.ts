import { randomUUID } from 'node:crypto';
import jwt from 'jsonwebtoken';
import { env } from '../config/env.js';
import { USER_ROLES, type UserRole } from '../users/roles.js';

const ISSUER = 'tricycle-matching-api';
const AUDIENCE = 'tricycle-matching-client';

export interface AccessTokenPayload {
  sub: string;
  username: string;
  role: UserRole;
  tokenVersion: number;
}

export interface VerifiedAccessToken {
  userId: string;
  username: string;
  role: UserRole;
  tokenVersion: number;
  jti: string;
}

export function signAccessToken(payload: AccessTokenPayload): string {
  return jwt.sign(
    {
      username: payload.username,
      role: payload.role,
      tokenVersion: payload.tokenVersion,
    },
    env.JWT_SECRET,
    {
      subject: payload.sub,
      jwtid: randomUUID(),
      expiresIn: env.JWT_EXPIRES_IN as jwt.SignOptions['expiresIn'],
      issuer: ISSUER,
      audience: AUDIENCE,
      algorithm: 'HS256',
    },
  );
}

export function verifyAccessToken(token: string): VerifiedAccessToken {
  const decoded = jwt.verify(token, env.JWT_SECRET, {
    issuer: ISSUER,
    audience: AUDIENCE,
    algorithms: ['HS256'],
  });

  if (
    typeof decoded !== 'object' ||
    decoded === null ||
    typeof decoded.sub !== 'string' ||
    typeof decoded.username !== 'string' ||
    typeof decoded.role !== 'string' ||
    typeof decoded.tokenVersion !== 'number' ||
    typeof decoded.jti !== 'string' ||
    !USER_ROLES.includes(decoded.role as UserRole)
  ) {
    throw new Error('Invalid access token payload');
  }

  return {
    userId: decoded.sub,
    username: decoded.username,
    role: decoded.role as UserRole,
    tokenVersion: decoded.tokenVersion,
    jti: decoded.jti,
  };
}
