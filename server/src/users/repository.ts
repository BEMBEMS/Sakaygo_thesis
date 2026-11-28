import { pool } from '../db/pool.js';
import type {
  AuthUser,
  DriverProfile,
  PassengerProfile,
  PassengerRequest,
  PassengerRequestStatus,
  TodaOption,
  VerificationStatus,
} from './models.js';
import type { UserRole } from './roles.js';

export class TodaNotAuthorizedError extends Error {
  constructor() {
    super('Selected TODA is not active or has no active operating zone');
    this.name = 'TodaNotAuthorizedError';
  }
}

interface AuthUserRow {
  user_id: string;
  username: string;
  email: string | null;
  phone_number: string | null;
  role: UserRole;
  first_name: string;
  last_name: string;
  is_active: boolean;
  password_hash?: string;
  verification_status?: VerificationStatus | null;
  passenger_id?: string | null;
  driver_id?: string | null;
  toda_org_id?: string | null;
  operating_zone_id?: string | null;
  token_version?: number;
  failed_login_attempts?: number;
  locked_until?: Date | null;
}

interface TodaRow {
  toda_org_id: string;
  code: string;
  name: string;
  service_area_name: string;
  zone_code: string | null;
}

const AUTH_USER_SELECT = `
  SELECT
    u.user_id,
    u.username,
    u.email,
    u.phone_number,
    u.role,
    u.first_name,
    u.last_name,
    u.is_active,
    u.password_hash,
    u.token_version,
    u.failed_login_attempts,
    u.locked_until,
    pp.passenger_id,
    dp.driver_id,
    dp.verification_status,
    dp.toda_org_id,
    dp.operating_zone_id
  FROM users u
  LEFT JOIN passenger_profiles pp ON pp.user_id = u.user_id
  LEFT JOIN driver_profiles dp ON dp.user_id = u.user_id
`;

function mapAuthUser(row: AuthUserRow): AuthUser {
  return {
    userId: row.user_id,
    username: row.username,
    email: row.email,
    phoneNumber: row.phone_number,
    role: row.role,
    firstName: row.first_name,
    lastName: row.last_name,
    isActive: row.is_active,
    verificationStatus: row.verification_status ?? null,
    passengerId: row.passenger_id ?? null,
    driverId: row.driver_id ?? null,
    todaOrgId: row.toda_org_id ?? null,
    operatingZoneId: row.operating_zone_id ?? null,
  };
}

export interface LoginCredentials {
  user: AuthUser;
  passwordHash: string;
  tokenVersion: number;
  failedLoginAttempts: number;
  lockedUntil: Date | null;
}

export async function findCredentialsByIdentifier(
  identifier: string,
): Promise<LoginCredentials | null> {
  const result = await pool.query<AuthUserRow>(
    `${AUTH_USER_SELECT} WHERE u.username = $1 OR u.email = $1 LIMIT 1`,
    [identifier],
  );
  const row = result.rows[0];

  if (!row || !row.password_hash) {
    return null;
  }

  return {
    user: mapAuthUser(row),
    passwordHash: row.password_hash,
    tokenVersion: row.token_version ?? 0,
    failedLoginAttempts: row.failed_login_attempts ?? 0,
    lockedUntil: row.locked_until ?? null,
  };
}

export async function findAuthenticationContext(userId: string): Promise<{
  user: AuthUser;
  tokenVersion: number;
} | null> {
  const result = await pool.query<AuthUserRow>(
    `${AUTH_USER_SELECT} WHERE u.user_id = $1 LIMIT 1`,
    [userId],
  );
  const row = result.rows[0];
  return row
    ? { user: mapAuthUser(row), tokenVersion: row.token_version ?? 0 }
    : null;
}

export async function findAuthUserById(userId: string): Promise<AuthUser | null> {
  const result = await pool.query<AuthUserRow>(
    `${AUTH_USER_SELECT} WHERE u.user_id = $1 LIMIT 1`,
    [userId],
  );
  const row = result.rows[0];
  return row ? mapAuthUser(row) : null;
}

export async function resetLoginAttempts(userId: string): Promise<void> {
  await pool.query(
    `UPDATE users
     SET failed_login_attempts = 0, locked_until = NULL
     WHERE user_id = $1`,
    [userId],
  );
}

export async function recordFailedLogin(
  userId: string,
  maxAttempts: number,
  lockoutMinutes: number,
): Promise<Date | null> {
  const result = await pool.query<{ locked_until: Date | null }>(
    `UPDATE users
     SET failed_login_attempts = failed_login_attempts + 1,
         locked_until = CASE
           WHEN failed_login_attempts + 1 >= $2
             THEN now() + ($3::int || ' minutes')::interval
           ELSE locked_until
         END
     WHERE user_id = $1
       AND (locked_until IS NULL OR locked_until <= now())
     RETURNING locked_until`,
    [userId, maxAttempts, lockoutMinutes],
  );
  return result.rows[0]?.locked_until ?? null;
}

export async function revokeUserTokens(userId: string): Promise<void> {
  await pool.query(
    `UPDATE users
     SET token_version = token_version + 1,
         failed_login_attempts = 0,
         locked_until = NULL
     WHERE user_id = $1`,
    [userId],
  );
}

export interface PassengerRegistrationInput {
  username: string;
  passwordHash: string;
  firstName: string;
  lastName: string;
  email: string | null;
  phoneNumber: string | null;
  passengerClass: 'standard' | 'priority';
}

export async function createPassenger(
  input: PassengerRegistrationInput,
): Promise<AuthUser> {
  const client = await pool.connect();

  try {
    await client.query('BEGIN');
    const userResult = await client.query<AuthUserRow>(
      `
      INSERT INTO users (
        username, email, phone_number, password_hash, role, first_name, last_name
      )
      VALUES ($1, $2, $3, $4, 'passenger', $5, $6)
      RETURNING
        user_id, username, email, phone_number, role, first_name, last_name, is_active
      `,
      [
        input.username,
        input.email,
        input.phoneNumber,
        input.passwordHash,
        input.firstName,
        input.lastName,
      ],
    );
    const userRow = userResult.rows[0];

    if (!userRow) {
      throw new Error('Failed to create passenger account');
    }

    await client.query(
      `
      INSERT INTO passenger_profiles (user_id, passenger_class)
      VALUES ($1, $2)
      `,
      [userRow.user_id, input.passengerClass],
    );
    await client.query('COMMIT');
    return (await findAuthUserById(userRow.user_id)) ?? mapAuthUser(userRow);
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

export interface DriverRegistrationInput {
  username: string;
  passwordHash: string;
  firstName: string;
  lastName: string;
  email: string | null;
  phoneNumber: string | null;
  todaOrgId: string;
  licenseNumber: string;
  todaMembershipId: string;
  vehiclePlateNumber: string;
}

export async function findActiveTodaWithZone(todaOrgId: string): Promise<{
  todaOrgId: string;
  zoneId: string | null;
} | null> {
  const result = await pool.query<{
    toda_org_id: string;
    zone_id: string | null;
  }>(
    `
    SELECT
      t.toda_id AS toda_org_id,
      (
        SELECT z.zone_id
        FROM operating_zones z
        WHERE z.toda_org_id = t.toda_id
          AND z.zone_status = 'active'
        ORDER BY z.code
        LIMIT 1
      ) AS zone_id
    FROM toda_organizations t
    WHERE t.toda_id = $1 AND t.is_active = true
    LIMIT 1
    `,
    [todaOrgId],
  );
  const row = result.rows[0];

  if (!row) {
    return null;
  }

  return {
    todaOrgId: row.toda_org_id,
    zoneId: row.zone_id,
  };
}

export async function createDriver(
  input: DriverRegistrationInput,
): Promise<AuthUser> {
  const client = await pool.connect();

  try {
    await client.query('BEGIN');
    const userResult = await client.query<AuthUserRow>(
      `
      INSERT INTO users (
        username, email, phone_number, password_hash, role, first_name, last_name
      )
      VALUES ($1, $2, $3, $4, 'driver', $5, $6)
      RETURNING
        user_id, username, email, phone_number, role, first_name, last_name, is_active
      `,
      [
        input.username,
        input.email,
        input.phoneNumber,
        input.passwordHash,
        input.firstName,
        input.lastName,
      ],
    );
    const userRow = userResult.rows[0];

    if (!userRow) {
      throw new Error('Failed to create driver account');
    }

    const todaResult = await client.query<{
      toda_org_id: string;
      zone_id: string | null;
    }>(
      `
      SELECT
        t.toda_id AS toda_org_id,
        (
          SELECT z.zone_id
          FROM operating_zones z
          WHERE z.toda_org_id = t.toda_id
            AND z.zone_status = 'active'
          ORDER BY z.code
          LIMIT 1
        ) AS zone_id
      FROM toda_organizations t
      WHERE t.toda_id = $1 AND t.is_active = true
      LIMIT 1
      `,
      [input.todaOrgId],
    );
    const toda = todaResult.rows[0];

    if (!toda || !toda.zone_id) {
      throw new TodaNotAuthorizedError();
    }

    await client.query(
      `
      INSERT INTO driver_profiles (
        user_id,
        toda_org_id,
        operating_zone_id,
        license_number,
        toda_membership_id,
        vehicle_plate_number,
        verification_status,
        driver_status
      )
      VALUES ($1, $2, $3, $4, $5, $6, 'pending', 'offline')
      `,
      [
        userRow.user_id,
        toda.toda_org_id,
        toda.zone_id,
        input.licenseNumber,
        input.todaMembershipId,
        input.vehiclePlateNumber,
      ],
    );
    await client.query('COMMIT');
    return (await findAuthUserById(userRow.user_id)) ?? mapAuthUser(userRow);
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

export async function getPassengerProfile(
  userId: string,
): Promise<PassengerProfile | null> {
  const result = await pool.query<{
    passenger_id: string;
    passenger_class: 'standard' | 'priority';
    current_latitude: string | null;
    current_longitude: string | null;
  }>(
    `
    SELECT passenger_id, passenger_class, current_latitude, current_longitude
    FROM passenger_profiles
    WHERE user_id = $1
    LIMIT 1
    `,
    [userId],
  );
  const row = result.rows[0];

  if (!row) {
    return null;
  }

  return {
    passengerId: row.passenger_id,
    passengerClass: row.passenger_class,
    currentLatitude:
      row.current_latitude === null ? null : Number(row.current_latitude),
    currentLongitude:
      row.current_longitude === null ? null : Number(row.current_longitude),
  };
}

const ACTIVE_PASSENGER_REQUEST_STATUSES: PassengerRequestStatus[] = [
  'searching',
  'offered',
  'accepted',
  'en_route',
  'pickup_arrived',
  'onboard',
];

const PASSENGER_REQUEST_SELECT = `
  SELECT
    request_id,
    passenger_id,
    pickup_latitude,
    pickup_longitude,
    destination_name,
    destination_latitude,
    destination_longitude,
    passenger_class,
    priority_score,
    status,
    requested_at
  FROM passenger_requests
`;

interface PassengerRequestRow {
  request_id: string;
  passenger_id: string;
  pickup_latitude: string;
  pickup_longitude: string;
  destination_name: string;
  destination_latitude: string;
  destination_longitude: string;
  passenger_class: 'standard' | 'priority';
  priority_score: string;
  status: PassengerRequestStatus;
  requested_at: Date | string;
}

function mapPassengerRequest(row: PassengerRequestRow): PassengerRequest {
  return {
    requestId: row.request_id,
    passengerId: row.passenger_id,
    pickupLatitude: Number(row.pickup_latitude),
    pickupLongitude: Number(row.pickup_longitude),
    destinationName: row.destination_name,
    destinationLatitude: Number(row.destination_latitude),
    destinationLongitude: Number(row.destination_longitude),
    passengerClass: row.passenger_class,
    priorityScore: Number(row.priority_score),
    status: row.status,
    requestedAt: String(row.requested_at),
  };
}

export async function updatePassengerCurrentLocation(
  userId: string,
  latitude: number,
  longitude: number,
): Promise<PassengerProfile | null> {
  const result = await pool.query<{
    passenger_id: string;
    passenger_class: 'standard' | 'priority';
    current_latitude: string | null;
    current_longitude: string | null;
  }>(
    `
    UPDATE passenger_profiles
    SET current_latitude = $2, current_longitude = $3
    WHERE user_id = $1
    RETURNING passenger_id, passenger_class, current_latitude, current_longitude
    `,
    [userId, latitude, longitude],
  );
  const row = result.rows[0];

  if (!row) {
    return null;
  }

  return {
    passengerId: row.passenger_id,
    passengerClass: row.passenger_class,
    currentLatitude:
      row.current_latitude === null ? null : Number(row.current_latitude),
    currentLongitude:
      row.current_longitude === null ? null : Number(row.current_longitude),
  };
}

export async function findActivePassengerRequest(
  passengerId: string,
): Promise<PassengerRequest | null> {
  const result = await pool.query<PassengerRequestRow>(
    `${PASSENGER_REQUEST_SELECT}
    WHERE passenger_id = $1 AND status = ANY($2::request_status[])
    ORDER BY requested_at DESC
    LIMIT 1`,
    [passengerId, ACTIVE_PASSENGER_REQUEST_STATUSES],
  );
  const row = result.rows[0];
  return row ? mapPassengerRequest(row) : null;
}

export interface CreatePassengerRequestInput {
  userId: string;
  pickupLatitude: number;
  pickupLongitude: number;
  destinationName: string;
  destinationLatitude: number;
  destinationLongitude: number;
}

export async function createPassengerRequest(
  input: CreatePassengerRequestInput,
): Promise<PassengerRequest | null> {
  const client = await pool.connect();

  try {
    await client.query('BEGIN');
    const profile = await client.query<{
      passenger_id: string;
      passenger_class: 'standard' | 'priority';
    }>(
      `
      SELECT passenger_id, passenger_class
      FROM passenger_profiles
      WHERE user_id = $1
      LIMIT 1
      `,
      [input.userId],
    );
    const profileRow = profile.rows[0];

    if (!profileRow) {
      await client.query('ROLLBACK');
      return null;
    }

    const result = await client.query<PassengerRequestRow>(
      `
      INSERT INTO passenger_requests (
        passenger_id,
        pickup_latitude,
        pickup_longitude,
        destination_name,
        destination_latitude,
        destination_longitude,
        passenger_class,
        status
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7, 'searching')
      RETURNING
        request_id,
        passenger_id,
        pickup_latitude,
        pickup_longitude,
        destination_name,
        destination_latitude,
        destination_longitude,
        passenger_class,
        priority_score,
        status,
        requested_at
      `,
      [
        profileRow.passenger_id,
        input.pickupLatitude,
        input.pickupLongitude,
        input.destinationName,
        input.destinationLatitude,
        input.destinationLongitude,
        profileRow.passenger_class,
      ],
    );
    const row = result.rows[0];
    await client.query('COMMIT');
    return row ? mapPassengerRequest(row) : null;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

export async function getPassengerRequestById(
  requestId: string,
  passengerId: string,
): Promise<PassengerRequest | null> {
  const result = await pool.query<PassengerRequestRow>(
    `${PASSENGER_REQUEST_SELECT}
    WHERE request_id = $1 AND passenger_id = $2
    LIMIT 1`,
    [requestId, passengerId],
  );
  const row = result.rows[0];
  return row ? mapPassengerRequest(row) : null;
}

export async function getDriverProfile(
  userId: string,
): Promise<DriverProfile | null> {
  const result = await pool.query<{
    driver_id: string;
    toda_org_id: string;
    operating_zone_id: string | null;
    license_number: string;
    toda_membership_id: string;
    vehicle_plate_number: string;
    verification_status: VerificationStatus;
    driver_status: 'offline' | 'available' | 'onboard' | 'unavailable';
  }>(
    `
    SELECT
      driver_id,
      toda_org_id,
      operating_zone_id,
      license_number,
      toda_membership_id,
      vehicle_plate_number,
      verification_status,
      driver_status
    FROM driver_profiles
    WHERE user_id = $1
    LIMIT 1
    `,
    [userId],
  );
  const row = result.rows[0];

  if (!row) {
    return null;
  }

  return {
    driverId: row.driver_id,
    todaOrgId: row.toda_org_id,
    operatingZoneId: row.operating_zone_id,
    licenseNumber: row.license_number,
    todaMembershipId: row.toda_membership_id,
    vehiclePlateNumber: row.vehicle_plate_number,
    verificationStatus: row.verification_status,
    driverStatus: row.driver_status,
  };
}

export async function listActiveTodas(): Promise<TodaOption[]> {
  const result = await pool.query<TodaRow>(
    `
    SELECT
      t.toda_id AS toda_org_id,
      t.code,
      t.name,
      t.service_area_name,
      (
        SELECT z.code
        FROM operating_zones z
        WHERE z.toda_org_id = t.toda_id
          AND z.zone_status = 'active'
        ORDER BY z.code
        LIMIT 1
      ) AS zone_code
    FROM toda_organizations t
    WHERE t.is_active = true
    ORDER BY t.code
    `,
  );

  return result.rows.map((row) => ({
    todaId: row.toda_org_id,
    code: row.code,
    name: row.name,
    serviceAreaName: row.service_area_name,
    zoneCode: row.zone_code,
  }));
}

export async function createAuditLog(
  actorUserId: string | null,
  action: string,
  entityType: string,
  entityId: string | null,
  metadata: Record<string, unknown> = {},
): Promise<void> {
  await pool.query(
    `
    INSERT INTO audit_logs (
      actor_user_id, action, entity_type, entity_id, metadata
    )
    VALUES ($1, $2, $3, $4, $5::jsonb)
    `,
    [actorUserId, action, entityType, entityId, JSON.stringify(metadata)],
  );
}
