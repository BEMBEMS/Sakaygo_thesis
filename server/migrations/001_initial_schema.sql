CREATE EXTENSION IF NOT EXISTS pgcrypto;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
    CREATE TYPE user_role AS ENUM ('passenger', 'driver', 'admin', 'lgu', 'toda');
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'verification_status') THEN
    CREATE TYPE verification_status AS ENUM ('unverified', 'pending', 'verified', 'rejected', 'restricted');
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'driver_status') THEN
    CREATE TYPE driver_status AS ENUM ('offline', 'available', 'onboard', 'unavailable');
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'passenger_class') THEN
    CREATE TYPE passenger_class AS ENUM ('standard', 'priority');
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'request_status') THEN
    CREATE TYPE request_status AS ENUM (
      'searching',
      'offered',
      'accepted',
      'en_route',
      'pickup_arrived',
      'onboard',
      'completed',
      'cancelled',
      'expired',
      'unmatched'
    );
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'match_status') THEN
    CREATE TYPE match_status AS ENUM (
      'proposed',
      'offered',
      'accepted',
      'declined',
      'timeout',
      'superseded',
      'cancelled'
    );
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'document_type') THEN
    CREATE TYPE document_type AS ENUM ('driver_license', 'toda_membership', 'tricycle_permit');
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'document_status') THEN
    CREATE TYPE document_status AS ENUM ('pending', 'verified', 'rejected');
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'trip_status') THEN
    CREATE TYPE trip_status AS ENUM ('scheduled', 'active', 'completed', 'cancelled');
  END IF;
END
$$;

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE IF NOT EXISTS toda_organizations (
  toda_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  service_area_name TEXT NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS users (
  user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  username TEXT NOT NULL UNIQUE,
  email TEXT UNIQUE,
  phone_number TEXT UNIQUE,
  password_hash TEXT NOT NULL,
  role user_role NOT NULL,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS passenger_profiles (
  passenger_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES users(user_id) ON DELETE CASCADE,
  passenger_class passenger_class NOT NULL DEFAULT 'standard',
  current_latitude NUMERIC(10, 7),
  current_longitude NUMERIC(10, 7),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT passenger_latitude_range CHECK (
    current_latitude IS NULL OR current_latitude BETWEEN -90 AND 90
  ),
  CONSTRAINT passenger_longitude_range CHECK (
    current_longitude IS NULL OR current_longitude BETWEEN -180 AND 180
  )
);

CREATE TABLE IF NOT EXISTS driver_profiles (
  driver_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES users(user_id) ON DELETE CASCADE,
  toda_org_id UUID NOT NULL REFERENCES toda_organizations(toda_id),
  license_number VARCHAR(100) NOT NULL UNIQUE,
  toda_membership_id VARCHAR(100) NOT NULL UNIQUE,
  vehicle_plate_number VARCHAR(30) NOT NULL UNIQUE,
  verification_status verification_status NOT NULL DEFAULT 'pending',
  driver_status driver_status NOT NULL DEFAULT 'offline',
  capacity INTEGER NOT NULL DEFAULT 1 CHECK (capacity >= 1),
  current_latitude NUMERIC(10, 7),
  current_longitude NUMERIC(10, 7),
  last_location_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT driver_latitude_range CHECK (
    current_latitude IS NULL OR current_latitude BETWEEN -90 AND 90
  ),
  CONSTRAINT driver_longitude_range CHECK (
    current_longitude IS NULL OR current_longitude BETWEEN -180 AND 180
  )
);

CREATE TABLE IF NOT EXISTS driver_documents (
  document_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  driver_id UUID NOT NULL REFERENCES driver_profiles(driver_id) ON DELETE CASCADE,
  document_type document_type NOT NULL,
  file_url TEXT NOT NULL,
  status document_status NOT NULL DEFAULT 'pending',
  reviewed_by UUID REFERENCES users(user_id),
  reviewed_at TIMESTAMPTZ,
  uploaded_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT driver_document_unique UNIQUE (driver_id, document_type)
);

CREATE TABLE IF NOT EXISTS driver_locations (
  location_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  driver_id UUID NOT NULL REFERENCES driver_profiles(driver_id) ON DELETE CASCADE,
  latitude NUMERIC(10, 7) NOT NULL,
  longitude NUMERIC(10, 7) NOT NULL,
  recorded_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT location_latitude_range CHECK (latitude BETWEEN -90 AND 90),
  CONSTRAINT location_longitude_range CHECK (longitude BETWEEN -180 AND 180)
);

CREATE TABLE IF NOT EXISTS passenger_requests (
  request_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  passenger_id UUID NOT NULL REFERENCES passenger_profiles(passenger_id) ON DELETE CASCADE,
  pickup_latitude NUMERIC(10, 7) NOT NULL,
  pickup_longitude NUMERIC(10, 7) NOT NULL,
  destination_name VARCHAR(200) NOT NULL,
  destination_latitude NUMERIC(10, 7) NOT NULL,
  destination_longitude NUMERIC(10, 7) NOT NULL,
  passenger_class passenger_class NOT NULL DEFAULT 'standard',
  priority_score NUMERIC(5, 4) NOT NULL DEFAULT 0.0000 CHECK (priority_score BETWEEN 0 AND 1),
  status request_status NOT NULL DEFAULT 'searching',
  requested_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  matched_at TIMESTAMPTZ,
  picked_up_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  cancelled_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT pickup_latitude_range CHECK (pickup_latitude BETWEEN -90 AND 90),
  CONSTRAINT pickup_longitude_range CHECK (pickup_longitude BETWEEN -180 AND 180),
  CONSTRAINT destination_latitude_range CHECK (destination_latitude BETWEEN -90 AND 90),
  CONSTRAINT destination_longitude_range CHECK (destination_longitude BETWEEN -180 AND 180)
);

CREATE TABLE IF NOT EXISTS matching_runs (
  run_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  algorithm_name TEXT NOT NULL DEFAULT 'hungarian',
  algorithm_version TEXT NOT NULL DEFAULT 'phase1-foundation',
  trigger_reason TEXT NOT NULL,
  request_count INTEGER NOT NULL DEFAULT 0 CHECK (request_count >= 0),
  driver_count INTEGER NOT NULL DEFAULT 0 CHECK (driver_count >= 0),
  weights JSONB NOT NULL DEFAULT '{}'::jsonb,
  total_cost NUMERIC(14, 6),
  duration_ms INTEGER,
  triggered_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS matching_candidates (
  candidate_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  run_id UUID NOT NULL REFERENCES matching_runs(run_id) ON DELETE CASCADE,
  request_id UUID NOT NULL REFERENCES passenger_requests(request_id) ON DELETE CASCADE,
  driver_id UUID NOT NULL REFERENCES driver_profiles(driver_id) ON DELETE CASCADE,
  group_key TEXT,
  feasible BOOLEAN NOT NULL DEFAULT true,
  rejection_reason TEXT,
  distance_meters NUMERIC(12, 3),
  pickup_time_seconds NUMERIC(10, 3),
  waiting_time_seconds NUMERIC(10, 3),
  priority_score NUMERIC(5, 4),
  detour_meters NUMERIC(12, 3),
  cost_components JSONB NOT NULL DEFAULT '{}'::jsonb,
  total_cost NUMERIC(14, 6),
  rank INTEGER,
  selected BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS matches (
  match_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  run_id UUID NOT NULL REFERENCES matching_runs(run_id) ON DELETE CASCADE,
  request_id UUID NOT NULL REFERENCES passenger_requests(request_id) ON DELETE CASCADE,
  driver_id UUID NOT NULL REFERENCES driver_profiles(driver_id) ON DELETE CASCADE,
  group_key TEXT,
  status match_status NOT NULL DEFAULT 'proposed',
  pickup_distance_meters NUMERIC(12, 3),
  pickup_eta_seconds NUMERIC(10, 3),
  total_cost NUMERIC(14, 6),
  offered_at TIMESTAMPTZ,
  response_deadline_at TIMESTAMPTZ,
  responded_at TIMESTAMPTZ,
  accepted_at TIMESTAMPTZ,
  declined_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS trip_records (
  trip_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id UUID NOT NULL UNIQUE REFERENCES matches(match_id) ON DELETE CASCADE,
  request_id UUID NOT NULL REFERENCES passenger_requests(request_id) ON DELETE CASCADE,
  driver_id UUID NOT NULL REFERENCES driver_profiles(driver_id) ON DELETE CASCADE,
  status trip_status NOT NULL DEFAULT 'scheduled',
  route_geometry TEXT,
  distance_meters NUMERIC(12, 3),
  duration_seconds NUMERIC(10, 3),
  pickup_timestamp TIMESTAMPTZ,
  dropoff_timestamp TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS system_parameters (
  key TEXT PRIMARY KEY,
  value JSONB NOT NULL,
  description TEXT NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS audit_logs (
  log_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_user_id UUID REFERENCES users(user_id),
  action TEXT NOT NULL,
  entity_type TEXT NOT NULL,
  entity_id UUID,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_driver_profiles_status ON driver_profiles(driver_status);
CREATE INDEX IF NOT EXISTS idx_driver_profiles_verification ON driver_profiles(verification_status);
CREATE INDEX IF NOT EXISTS idx_driver_profiles_toda ON driver_profiles(toda_org_id);
CREATE INDEX IF NOT EXISTS idx_driver_locations_driver_time ON driver_locations(driver_id, recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_passenger_requests_status_time ON passenger_requests(status, requested_at);
CREATE INDEX IF NOT EXISTS idx_matching_runs_triggered_at ON matching_runs(triggered_at DESC);
CREATE INDEX IF NOT EXISTS idx_matching_candidates_run_rank ON matching_candidates(run_id, rank);
CREATE INDEX IF NOT EXISTS idx_matches_status ON matches(status);
CREATE INDEX IF NOT EXISTS idx_trip_records_driver ON trip_records(driver_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs(created_at DESC);

DROP TRIGGER IF EXISTS toda_organizations_set_updated_at ON toda_organizations;
CREATE TRIGGER toda_organizations_set_updated_at
BEFORE UPDATE ON toda_organizations
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS users_set_updated_at ON users;
CREATE TRIGGER users_set_updated_at
BEFORE UPDATE ON users
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS passenger_profiles_set_updated_at ON passenger_profiles;
CREATE TRIGGER passenger_profiles_set_updated_at
BEFORE UPDATE ON passenger_profiles
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS driver_profiles_set_updated_at ON driver_profiles;
CREATE TRIGGER driver_profiles_set_updated_at
BEFORE UPDATE ON driver_profiles
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS driver_documents_set_updated_at ON driver_documents;
CREATE TRIGGER driver_documents_set_updated_at
BEFORE UPDATE ON driver_documents
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS passenger_requests_set_updated_at ON passenger_requests;
CREATE TRIGGER passenger_requests_set_updated_at
BEFORE UPDATE ON passenger_requests
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trip_records_set_updated_at ON trip_records;
CREATE TRIGGER trip_records_set_updated_at
BEFORE UPDATE ON trip_records
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS system_parameters_set_updated_at ON system_parameters;
CREATE TRIGGER system_parameters_set_updated_at
BEFORE UPDATE ON system_parameters
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

INSERT INTO toda_organizations (code, name, service_area_name, is_active)
VALUES
  (
    'DEBTODA',
    'Del Monte, Batucan Tricycle Operators and Drivers Association',
    'Del Monte and Batucan service areas',
    true
  ),
  (
    'TATMODA',
    'Talacogon Tricycle and Motorcycle Operators and Drivers Association',
    'Talacogon service area',
    true
  )
ON CONFLICT (code) DO UPDATE SET
  name = EXCLUDED.name,
  service_area_name = EXCLUDED.service_area_name,
  is_active = EXCLUDED.is_active,
  updated_at = now();

INSERT INTO system_parameters (key, value, description)
VALUES
  (
    'matching.algorithm',
    '{"name":"hungarian","version":"phase1-foundation"}'::jsonb,
    'Configured passenger-driver assignment algorithm'
  ),
  (
    'matching.criteria',
    '["distance","pickup_time","waiting_time","priority"]'::jsonb,
    'Documented matching criteria for Phase 1'
  )
ON CONFLICT (key) DO UPDATE SET
  value = EXCLUDED.value,
  description = EXCLUDED.description,
  updated_at = now();
