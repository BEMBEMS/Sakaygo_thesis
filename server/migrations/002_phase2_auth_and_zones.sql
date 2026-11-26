DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'zone_status') THEN
    CREATE TYPE zone_status AS ENUM ('active', 'inactive');
  END IF;
END
$$;

CREATE TABLE IF NOT EXISTS operating_zones (
  zone_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  toda_org_id UUID REFERENCES toda_organizations(toda_id),
  zone_status zone_status NOT NULL DEFAULT 'inactive',
  coverage_description TEXT NOT NULL,
  geojson JSONB,
  geojson_source TEXT NOT NULL DEFAULT 'awaiting_verified_mpdc_geojson',
  geojson_updated_at TIMESTAMPTZ,
  allow_cross_zone BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE driver_profiles
ADD COLUMN IF NOT EXISTS operating_zone_id UUID REFERENCES operating_zones(zone_id);

CREATE INDEX IF NOT EXISTS idx_operating_zones_status ON operating_zones(zone_status);
CREATE INDEX IF NOT EXISTS idx_operating_zones_toda ON operating_zones(toda_org_id);
CREATE INDEX IF NOT EXISTS idx_driver_profiles_zone ON driver_profiles(operating_zone_id);

DROP TRIGGER IF EXISTS operating_zones_set_updated_at ON operating_zones;
CREATE TRIGGER operating_zones_set_updated_at
BEFORE UPDATE ON operating_zones
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'audit_logs_actor_user_id_fkey'
  ) THEN
    ALTER TABLE audit_logs DROP CONSTRAINT audit_logs_actor_user_id_fkey;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'audit_logs_actor_user_id_fkey'
  ) THEN
    ALTER TABLE audit_logs
    ADD CONSTRAINT audit_logs_actor_user_id_fkey
    FOREIGN KEY (actor_user_id) REFERENCES users(user_id) ON DELETE SET NULL;
  END IF;
END
$$;

INSERT INTO operating_zones (
  code,
  name,
  toda_org_id,
  zone_status,
  coverage_description,
  geojson_source,
  allow_cross_zone
)
SELECT
  'ZONE_1',
  'Zone 1 – TATMODA',
  toda_id,
  'active'::zone_status,
  'Talacogon Proper / Poblacion; San Isidro, San Nicolas, and San Agustin boundaries; designated roads shown in the MPDC enlargement section.',
  'awaiting_verified_mpdc_geojson',
  false
FROM toda_organizations
WHERE code = 'TATMODA'
ON CONFLICT (code) DO UPDATE SET
  name = EXCLUDED.name,
  toda_org_id = EXCLUDED.toda_org_id,
  zone_status = EXCLUDED.zone_status,
  coverage_description = EXCLUDED.coverage_description,
  updated_at = now();

INSERT INTO operating_zones (
  code,
  name,
  toda_org_id,
  zone_status,
  coverage_description,
  geojson_source,
  allow_cross_zone
)
SELECT
  'ZONE_2',
  'Zone 2 – DEBTODA',
  toda_id,
  'active'::zone_status,
  'Del Monte–Batucan; red-highlighted roads in Del Monte proper, dense Del Monte street network, and the connecting road toward Batucan.',
  'awaiting_verified_mpdc_geojson',
  false
FROM toda_organizations
WHERE code = 'DEBTODA'
ON CONFLICT (code) DO UPDATE SET
  name = EXCLUDED.name,
  toda_org_id = EXCLUDED.toda_org_id,
  zone_status = EXCLUDED.zone_status,
  coverage_description = EXCLUDED.coverage_description,
  updated_at = now();

INSERT INTO operating_zones (
  code,
  name,
  toda_org_id,
  zone_status,
  coverage_description,
  geojson_source,
  allow_cross_zone
)
VALUES
  (
    'ZONE_3',
    'Zone 3 – Zillovia–Poblacion',
    NULL,
    'inactive'::zone_status,
    'Future reference zone: Zillovia–Poblacion.',
    'awaiting_authorization_and_verified_mpdc_geojson',
    false
  ),
  (
    'ZONE_4',
    'Zone 4 – Causwagan–Labnig–Poblacion–Batucan',
    NULL,
    'inactive'::zone_status,
    'Future reference zone: Causwagan–Labnig–Poblacion–Batucan.',
    'awaiting_authorization_and_verified_mpdc_geojson',
    false
  ),
  (
    'ZONE_5',
    'Zone 5 – La Flora–Buena Gracia–Bataran–Desamparados',
    NULL,
    'inactive'::zone_status,
    'Future reference zone: La Flora–Buena Gracia–Bataran–Desamparados.',
    'awaiting_authorization_and_verified_mpdc_geojson',
    false
  )
ON CONFLICT (code) DO UPDATE SET
  name = EXCLUDED.name,
  toda_org_id = EXCLUDED.toda_org_id,
  zone_status = EXCLUDED.zone_status,
  coverage_description = EXCLUDED.coverage_description,
  updated_at = now();

INSERT INTO system_parameters (key, value, description)
VALUES
  (
    'matching.weights',
    '{"distance":0.30,"pickup_time":0.30,"waiting_time":0.25,"priority":0.15}'::jsonb,
    'Approved provisional weights for the multi-criteria matching cost'
  ),
  (
    'passenger.priority_classes',
    '["standard","priority"]'::jsonb,
    'Approved passenger priority classifications'
  ),
  (
    'driver.response_timeout_seconds',
    '30'::jsonb,
    'Driver response timeout for an assignment offer'
  ),
  (
    'routing.provider',
    '{"provider":"osrm","base_url_env":"OSRM_BASE_URL"}'::jsonb,
    'OSM/OSRM routing configuration'
  ),
  (
    'matching.allow_cross_zone',
    'false'::jsonb,
    'Cross-zone matching is disabled until explicitly authorized'
  ),
  (
    'notifications.provider',
    '{"provider":"fcm","credentials_source":"environment"}'::jsonb,
    'FCM credentials must be supplied through environment variables'
  )
ON CONFLICT (key) DO UPDATE SET
  value = EXCLUDED.value,
  description = EXCLUDED.description,
  updated_at = now();
