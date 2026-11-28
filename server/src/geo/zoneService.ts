import { pool } from '../db/pool.js';
import type { ZoneSummary } from '../users/models.js';

interface ZoneRow {
  zone_id: string;
  code: string;
  name: string;
  toda_org_id: string | null;
  zone_status: 'active' | 'inactive';
  coverage_description: string;
  geojson: unknown;
  geojson_source: string;
  allow_cross_zone: boolean;
}

type Point = [number, number];
type Ring = Point[];
type Polygon = Ring[];

function asRecord(value: unknown): Record<string, unknown> | null {
  return typeof value === 'object' && value !== null
    ? (value as Record<string, unknown>)
    : null;
}

function asPoint(value: unknown): Point | null {
  if (!Array.isArray(value) || value.length < 2) {
    return null;
  }

  const longitude = Number(value[0]);
  const latitude = Number(value[1]);

  if (!Number.isFinite(longitude) || !Number.isFinite(latitude)) {
    return null;
  }

  return [longitude, latitude];
}

function asRing(value: unknown): Ring | null {
  if (!Array.isArray(value)) {
    return null;
  }

  const points: Point[] = [];

  for (const item of value) {
    const point = asPoint(item);

    if (!point) {
      return null;
    }

    points.push(point);
  }

  return points.length >= 3 ? points : null;
}

function asPolygon(value: unknown): Polygon | null {
  if (!Array.isArray(value)) {
    return null;
  }

  const rings: Ring[] = [];

  for (const item of value) {
    const ring = asRing(item);

    if (!ring) {
      return null;
    }

    rings.push(ring);
  }

  return rings.length > 0 ? rings : null;
}

function extractPolygons(value: unknown): Polygon[] {
  const record = asRecord(value);

  if (!record) {
    return [];
  }

  if (record.type === 'FeatureCollection' && Array.isArray(record.features)) {
    return record.features.flatMap((feature) => extractPolygons(feature));
  }

  if (record.type === 'Feature') {
    return extractPolygons(record.geometry);
  }

  if (record.type === 'Polygon') {
    const polygon = asPolygon(record.coordinates);
    return polygon ? [polygon] : [];
  }

  if (record.type === 'MultiPolygon' && Array.isArray(record.coordinates)) {
    const polygons: Polygon[] = [];

    for (const coordinates of record.coordinates) {
      const polygon = asPolygon(coordinates);

      if (polygon) {
        polygons.push(polygon);
      }
    }

    return polygons;
  }

  return [];
}

function pointInRing(latitude: number, longitude: number, ring: Ring): boolean {
  let inside = false;

  for (let index = 0, previous = ring.length - 1; index < ring.length; previous = index++) {
    const [currentLongitude, currentLatitude] = ring[index];
    const [previousLongitude, previousLatitude] = ring[previous];
    const crosses =
      currentLatitude > latitude !== previousLatitude > latitude;

    if (
      crosses &&
      longitude <
        ((previousLongitude - currentLongitude) * (latitude - currentLatitude)) /
          (previousLatitude - currentLatitude) +
          currentLongitude
    ) {
      inside = !inside;
    }
  }

  return inside;
}

function pointInPolygon(latitude: number, longitude: number, polygon: Polygon): boolean {
  const outerRing = polygon[0];

  if (!outerRing || !pointInRing(latitude, longitude, outerRing)) {
    return false;
  }

  for (let index = 1; index < polygon.length; index += 1) {
    const hole = polygon[index];

    if (hole && pointInRing(latitude, longitude, hole)) {
      return false;
    }
  }

  return true;
}

export function hasUsableBoundary(geojson: unknown): boolean {
  return extractPolygons(geojson).length > 0;
}

export function pointInGeoJson(
  geojson: unknown,
  latitude: number,
  longitude: number,
): boolean | null {
  const polygons = extractPolygons(geojson);

  if (polygons.length === 0) {
    return null;
  }

  return polygons.some((polygon) => pointInPolygon(latitude, longitude, polygon));
}

function mapZone(row: ZoneRow, includeGeoJson: boolean): ZoneSummary & {
  geojson?: unknown;
} {
  const summary: ZoneSummary = {
    zoneId: row.zone_id,
    code: row.code,
    name: row.name,
    todaOrgId: row.toda_org_id,
    zoneStatus: row.zone_status,
    coverageDescription: row.coverage_description,
    geojsonSource: row.geojson_source,
    hasBoundary: hasUsableBoundary(row.geojson),
    allowCrossZone: row.allow_cross_zone,
  };

  if (!includeGeoJson) {
    return summary;
  }

  return {
    ...summary,
    geojson: row.geojson ?? null,
  };
}

export async function listZones(includeGeoJson = false): Promise<
  Array<ZoneSummary & { geojson?: unknown }>
> {
  const result = await pool.query<ZoneRow>(
    `
    SELECT
      zone_id,
      code,
      name,
      toda_org_id,
      zone_status,
      coverage_description,
      geojson,
      geojson_source,
      allow_cross_zone
    FROM operating_zones
    ORDER BY code
    `,
  );

  return result.rows.map((row) => mapZone(row, includeGeoJson));
}

export async function findZoneByCode(
  code: string,
  includeGeoJson = false,
): Promise<(ZoneSummary & { geojson?: unknown }) | null> {
  const result = await pool.query<ZoneRow>(
    `
    SELECT
      zone_id,
      code,
      name,
      toda_org_id,
      zone_status,
      coverage_description,
      geojson,
      geojson_source,
      allow_cross_zone
    FROM operating_zones
    WHERE code = $1
    LIMIT 1
    `,
    [code],
  );
  const row = result.rows[0];
  return row ? mapZone(row, includeGeoJson) : null;
}

export async function findActiveZoneByToda(
  todaOrgId: string,
): Promise<ZoneSummary | null> {
  const result = await pool.query<ZoneRow>(
    `
    SELECT
      zone_id,
      code,
      name,
      toda_org_id,
      zone_status,
      coverage_description,
      geojson,
      geojson_source,
      allow_cross_zone
    FROM operating_zones
    WHERE toda_org_id = $1 AND zone_status = 'active'
    ORDER BY code
    LIMIT 1
    `,
    [todaOrgId],
  );
  const row = result.rows[0];
  return row ? mapZone(row, false) : null;
}

export async function isCrossZoneAllowed(): Promise<boolean> {
  const result = await pool.query<{ value: unknown }>(
    `SELECT value FROM system_parameters WHERE key = 'matching.allow_cross_zone' LIMIT 1`,
  );
  return result.rows[0]?.value === true;
}

export interface ZoneValidationResult {
  zone: ZoneSummary;
  status: 'within' | 'outside' | 'boundary_not_configured' | 'zone_inactive';
  within: boolean | null;
}

export async function validateLocationInZone(
  code: string,
  latitude: number,
  longitude: number,
): Promise<ZoneValidationResult | null> {
  const zone = await findZoneByCode(code, true);

  if (!zone) {
    return null;
  }

  if (zone.zoneStatus !== 'active') {
    return {
      zone: mapZoneForResult(zone),
      status: 'zone_inactive',
      within: null,
    };
  }

  if (!zone.hasBoundary) {
    return {
      zone: mapZoneForResult(zone),
      status: 'boundary_not_configured',
      within: null,
    };
  }

  const within = pointInGeoJson(zone.geojson, latitude, longitude);

  return {
    zone: mapZoneForResult(zone),
    status: within === null ? 'boundary_not_configured' : within ? 'within' : 'outside',
    within,
  };
}

function mapZoneForResult(
  zone: ZoneSummary & { geojson?: unknown },
): ZoneSummary {
  return {
    zoneId: zone.zoneId,
    code: zone.code,
    name: zone.name,
    todaOrgId: zone.todaOrgId,
    zoneStatus: zone.zoneStatus,
    coverageDescription: zone.coverageDescription,
    geojsonSource: zone.geojsonSource,
    hasBoundary: zone.hasBoundary,
    allowCrossZone: zone.allowCrossZone,
  };
}
