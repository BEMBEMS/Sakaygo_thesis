# Phase 2 Documentation

Phase 2 adds authentication, role-based access, TODA/zone foundations, and an administrative web login surface without changing the Phase 1 system boundaries.

## Completed

- PostgreSQL migration `server/migrations/002_phase2_auth_and_zones.sql`:
  - `operating_zones` with `active`/`inactive` status, nullable `geojson`, and source metadata.
  - `driver_profiles.operating_zone_id`.
  - Audit log actor foreign key updated to `ON DELETE SET NULL`.
  - Active zones `ZONE_1` (TATMODA, Talacogon Proper/Poblacion) and `ZONE_2` (DEBTODA, Del Monte–Batucan).
  - Inactive future reference zones `ZONE_3`–`ZONE_5`.
  - Configurable system parameters for weights, priority classes, 30-second driver timeout, OSRM routing, disabled cross-zone matching, and FCM environment credentials.
- Backend authentication:
  - Passenger and driver registration with bcrypt password hashing.
  - Passenger, driver, and administrative login.
  - JWT access tokens using `JWT_SECRET` and `JWT_EXPIRES_IN`.
  - `/api/v1/auth/me` session restoration.
  - Role guards and verified-driver guard.
  - Audit logs for registration, login, admin login, and admin bootstrap.
- Backend zone and TODA APIs:
  - Public TODA list.
  - Public zone list and zone detail.
  - Authenticated coordinate validation endpoint.
  - Administrative zone list/detail and cross-zone policy endpoint.
- Backend profile APIs:
  - Passenger profile for passenger roles.
  - Driver profile for verified driver roles.
- Secure admin bootstrap script:
  - `npm run admin:create`
  - Values supplied through `ADMIN_BOOTSTRAP_*` environment variables.
- Flutter mobile/web client:
  - Passenger registration/login, driver registration/login, admin login.
  - Secure token storage.
  - Auth controller with session restore and logout.
  - Role-guarded routes.
  - Passenger/driver home screens.
  - Administrative dashboard shell showing zones, boundary status, and cross-zone policy.
- Automated tests:
  - Backend Phase 2 integration coverage for registration, login, duplicate accounts, unverified driver blocking, admin RBAC, zone visibility, cross-zone policy, and unconfigured boundaries.
  - Flutter tests for validators, auth/zone models, API exceptions, and the auth shell.

## Partially Completed

- Zone geometry:
  - Zone metadata, coverage descriptions, TODA links, and point-validation logic are implemented.
  - `geojson` is intentionally `NULL` for every zone because no verified MPDC GeoJSON was supplied.
  - Validation returns `boundary_not_configured` until verified geometry is loaded.
- FCM:
  - Provider and credential source are recorded as environment-based configuration.
  - Notification delivery is pending a later phase.
- Admin dashboard:
  - Authentication and zone oversight shell are implemented.
  - User management, driver verification, live fleet views, and analytics remain Phase 7–8 work.

## Pending

- Load verified MPDC GeoJSON polygons and road networks for `ZONE_1` and `ZONE_2`.
- Implement driver verification workflows.
- Implement passenger request, driver availability, and matching flows.
- Implement OSRM route calculation and FCM notifications.
- Implement the multi-criteria Hungarian matching algorithm in Phase 5.
- Keep cross-zone matching disabled until explicitly authorized.

## API Endpoints

| Method | Endpoint | Access |
| --- | --- | --- |
| POST | `/api/v1/auth/passenger/register` | Public |
| POST | `/api/v1/auth/driver/register` | Public |
| POST | `/api/v1/auth/login` | Public |
| POST | `/api/v1/auth/admin/login` | Public |
| GET | `/api/v1/auth/me` | Authenticated |
| GET | `/api/v1/todas` | Public |
| GET | `/api/v1/zones` | Public |
| GET | `/api/v1/zones/:code` | Public |
| POST | `/api/v1/zones/:code/validate-location` | Authenticated |
| GET | `/api/v1/users/passenger/me` | Passenger |
| GET | `/api/v1/users/driver/me` | Verified driver |
| GET | `/api/v1/admin/zones` | Admin/LGU/TODA |
| GET | `/api/v1/admin/zones/:code` | Admin/LGU/TODA |
| GET | `/api/v1/admin/cross-zone-policy` | Admin/LGU/TODA |

## Verification

```bash
npm install --prefix server
npm run db:migrate
npm run db:migrate:test
npm test
npm run typecheck --prefix server
npm run lint --prefix server
npm run build --prefix server
cd apps/mobile && flutter pub get && flutter analyze && flutter test && flutter build web --release
npm run admin:create
```

Redis may remain unavailable locally when Docker is not running; health will report `degraded` without affecting authentication or zone endpoints.
