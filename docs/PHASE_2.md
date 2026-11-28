# Phase 2 Documentation

Phase 2 adds authentication, role-based access, TODA/zone foundations, and an administrative web login surface without changing the Phase 1 system boundaries.

> Scope note: the repository also contains Phase 3 passenger-request code. It is documented separately in `docs/PHASE_3.md` and is not part of the Phase 2 completion criteria below.

## Completed

- Database migrations:
  - `server/migrations/002_phase2_auth_and_zones.sql`:
    - `operating_zones` with `active`/`inactive` status, nullable `geojson`, and source metadata.
    - `driver_profiles.operating_zone_id`.
    - Audit log actor foreign key updated to `ON DELETE SET NULL`.
    - Active zones `ZONE_1` (TATMODA) and `ZONE_2` (DEBTODA), both with `geojson = NULL`.
    - System parameters for weights, priority classes, 30-second driver timeout, OSRM routing, disabled cross-zone matching, and FCM provider metadata.
  - `server/migrations/003_phase2_session_hardening.sql`:
    - `users.token_version` for server-side token revocation on logout.
    - `users.failed_login_attempts` and `users.locked_until` for login lockout.
    - Removes unverified barangay/road claims from zone descriptions.
    - Removes inactive `ZONE_3`–`ZONE_5` reference rows because the thesis scope covers only TATMODA and DEBTODA.
- Backend authentication:
  - Passenger and driver registration with bcrypt hashing and a 72-byte password limit.
  - Passenger, driver, and administrative login.
  - JWT access tokens pinned to HS256 with issuer, audience, expiry, `jti`, and token version.
  - Production startup rejects an unset or default `JWT_SECRET`.
  - Failed-login lockout after 5 attempts for 15 minutes.
  - `/api/v1/auth/logout` increments the user's token version so issued tokens stop working immediately.
  - `/api/v1/auth/me` session restoration.
  - Audit logs for registration, successful/failed/locked login, logout, admin login denial, and admin bootstrap.
- Backend RBAC:
  - Roles: `passenger`, `driver`, `admin`, `lgu`, `toda`.
  - Admin routes require `admin`, `lgu`, or `toda`.
  - Driver profile routes require the `driver` role and verified status.
  - Authentication reloads active user, role, and token version from the database on every protected request.
  - Driver registration checks TODA activation and zone assignment inside the same transaction, eliminating the earlier check-then-insert race.
- Backend zone and TODA APIs:
  - Public TODA list.
  - Public zone list and zone detail.
  - Authenticated coordinate validation endpoint.
  - Administrative zone list/detail and global cross-zone policy endpoint.
  - `hasBoundary` is true only when GeoJSON contains a usable Polygon or MultiPolygon.
- Backend profile APIs:
  - Passenger profile for passenger roles.
  - Driver profile for verified driver roles.
- Secure admin bootstrap script:
  - `npm run admin:create`
  - Values supplied through `ADMIN_BOOTSTRAP_*` environment variables.
- Flutter mobile/web client:
  - Passenger registration/login, driver registration/login, and admin login.
  - Native secure token storage through `flutter_secure_storage`.
  - Auth controller with session restore, local sign-out, and server-side logout.
  - Transient network failures during restore no longer destroy the stored token; explicit auth failures do.
  - Missing, malformed, and expired responses are handled without crashing startup.
  - Role-guarded routes; pending drivers are denied the driver dashboard.
  - Passenger/driver home screens.
  - Administrative dashboard shell with zone list, loading/empty/error states, boundary status, and the global cross-zone policy from `/api/v1/admin/cross-zone-policy`.
  - Android release builds now include the `INTERNET` permission.
- Automated tests:
  - Backend Phase 2 integration coverage for registration, login, duplicate accounts, unverified driver blocking, admin RBAC, zone/TODA association, cross-zone policy, unconfigured boundaries, usable-geometry detection, logout revocation, login lockout, and malformed bearer tokens.
  - Flutter tests for validators, auth/zone models, API exceptions/status codes, auth shell, session restore, logout, route guards, and admin dashboard states.

## Partially Completed

- Zone geometry:
  - Zone metadata, TODA links, and point-validation logic are implemented.
  - `geojson` is intentionally `NULL` for every zone because no verified MPDC GeoJSON was supplied.
  - Validation returns `boundary_not_configured` until verified geometry is loaded.
  - No API exists yet for loading verified GeoJSON; it must be loaded by a future migration or admin workflow.
- FCM:
  - Provider source is recorded as environment-based configuration.
  - Notification delivery is pending a later phase.
- Admin dashboard:
  - Authentication and zone oversight shell are implemented.
  - User management, driver verification, live fleet views, GeoJSON upload, and analytics remain later-phase work.
- Web token storage:
  - Native platforms use Keychain/Keystore.
  - `flutter_secure_storage_web` encrypts tokens but stores the ciphertext and key in browser `localStorage`; HttpOnly cookie sessions are not implemented.

## Pending

- Load verified MPDC GeoJSON polygons and road networks for `ZONE_1` and `ZONE_2`.
- Implement driver verification workflows.
- Implement driver availability and matching flows. Passenger request entry is Phase 3.
- Implement OSRM route calculation and FCM notifications.
- Implement the multi-criteria Hungarian matching algorithm in Phase 5.
- Keep cross-zone matching disabled until explicitly authorized. The global `system_parameters.matching.allow_cross_zone` value is authoritative; the legacy per-zone flag is informational and not yet enforced.

## API Endpoints

| Method | Endpoint | Access |
| --- | --- | --- |
| POST | `/api/v1/auth/passenger/register` | Public |
| POST | `/api/v1/auth/driver/register` | Public |
| POST | `/api/v1/auth/login` | Public |
| POST | `/api/v1/auth/admin/login` | Public |
| POST | `/api/v1/auth/logout` | Authenticated |
| GET | `/api/v1/auth/me` | Authenticated |
| GET | `/api/v1/todas` | Public |
| GET | `/api/v1/zones` | Public |
| GET | `/api/v1/zones/:code` | Public |
| POST | `/api/v1/zones/:code/validate-location` | Authenticated |
| GET | `/api/v1/users/passenger/me` | Passenger |
| GET | `/api/v1/users/driver/me` | Verified driver |
| GET | `/api/v1/admin/me` | Admin/LGU/TODA |
| GET | `/api/v1/admin/zones` | Admin/LGU/TODA |
| GET | `/api/v1/admin/zones/:code` | Admin/LGU/TODA |
| GET | `/api/v1/admin/cross-zone-policy` | Admin/LGU/TODA |

## Verification

Setup:

```bash
npm install --prefix server
npm run db:migrate
npm run db:migrate:test
npm run admin:create
```

`npm run admin:create` requires the `ADMIN_BOOTSTRAP_*` environment variables and is account setup, not a verification command.

Verification commands:

```bash
npm test --prefix server
npm run typecheck --prefix server
npm run lint --prefix server
npm run build --prefix server
cd apps/mobile && flutter pub get && flutter analyze && flutter test && flutter build web --release
```

Verified results in this environment:

- Backend: 16 tests passed (3 health, 8 Phase 2, 5 Phase 3), 0 failed.
- Backend typecheck, lint, and production build passed.
- Database migrations 001–003 applied successfully to development and test databases; rerunning the migration command made no changes.
- Production configuration check rejected the default/unset `JWT_SECRET` and accepted an explicit secret.
- Flutter: 24 tests passed, 0 failed.
- Flutter analyze: no issues.
- Flutter web release build: succeeded. The build printed non-fatal WebAssembly dry-run warnings from `flutter_secure_storage_web` (`dart:html`, `dart:js_util`, and `package:js` are not Wasm-compatible).

Redis may remain unavailable locally when Docker is not running; health reports `degraded` without affecting authentication or zone endpoints.
