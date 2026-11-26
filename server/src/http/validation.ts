import type { ZodType } from 'zod';
import { badRequest } from './errors.js';

export function parseRequestBody<T>(schema: ZodType<T>, data: unknown): T {
  const result = schema.safeParse(data);

  if (!result.success) {
    const message = result.error.issues
      .map((issue) => issue.message)
      .join('; ');
    throw badRequest('VALIDATION_ERROR', message || 'Invalid request body');
  }

  return result.data;
}
