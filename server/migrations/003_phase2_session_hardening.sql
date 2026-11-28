ALTER TABLE users
ADD COLUMN IF NOT EXISTS token_version INTEGER NOT NULL DEFAULT 0;

ALTER TABLE users
ADD COLUMN IF NOT EXISTS failed_login_attempts INTEGER NOT NULL DEFAULT 0;

ALTER TABLE users
ADD COLUMN IF NOT EXISTS locked_until TIMESTAMPTZ;

UPDATE operating_zones
SET coverage_description = 'Talacogon service area (TATMODA). Verified MPDC boundaries are not yet loaded; no barangay-level coverage is asserted.',
    updated_at = now()
WHERE code = 'ZONE_1';

UPDATE operating_zones
SET coverage_description = 'Del Monte and Batucan service area (DEBTODA). Verified MPDC boundaries are not yet loaded; no road-level coverage is asserted.',
    updated_at = now()
WHERE code = 'ZONE_2';

UPDATE driver_profiles
SET operating_zone_id = NULL,
    updated_at = now()
WHERE operating_zone_id IN (
  SELECT zone_id
  FROM operating_zones
  WHERE code IN ('ZONE_3', 'ZONE_4', 'ZONE_5')
);

DELETE FROM operating_zones
WHERE code IN ('ZONE_3', 'ZONE_4', 'ZONE_5')
  AND zone_status = 'inactive';
