export class HttpError extends Error {
  constructor(
    readonly status: number,
    readonly code: string,
    message: string,
  ) {
    super(message);
    this.name = 'HttpError';
  }
}

export function badRequest(code: string, message: string): HttpError {
  return new HttpError(400, code, message);
}

export function unauthorized(code: string, message: string): HttpError {
  return new HttpError(401, code, message);
}

export function forbidden(code: string, message: string): HttpError {
  return new HttpError(403, code, message);
}

export function conflict(code: string, message: string): HttpError {
  return new HttpError(409, code, message);
}

export function notFound(code: string, message: string): HttpError {
  return new HttpError(404, code, message);
}
