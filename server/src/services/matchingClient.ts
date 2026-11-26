import { env } from '../config/env.js';

export async function checkMatchingService(
  baseUrl: string = env.MATCHING_SERVICE_URL,
): Promise<boolean> {
  const url = `${baseUrl.replace(/\/$/, '')}/health`;

  try {
    const response = await fetch(url, {
      signal: AbortSignal.timeout(1_500),
    });
    return response.ok;
  } catch {
    return false;
  }
}
