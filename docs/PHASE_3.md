# Phase 3 Documentation

Phase 3 completes the passenger request-entry workflow: passenger profile display, current GPS capture, destination entry, and the approved “I’m Waiting Here” waiting request. It preserves Phase 1 and Phase 2 behavior and does not implement matching, driver dispatch, notifications, or later-phase management features.

## Files Changed

### Backend
- `server/src/auth/schemas.ts`: added update-location and waiting-request validation schemas.
- `server/src/users/models.ts`: added `PassengerRequest` and status types.
- `server/src/users/repository.ts`: added passenger location update, active-request lookup, waiting-request creation, and ownership-checked request lookup.
- `server/src/routes/passenger.ts`: new passenger-only router.
- `server/src/app.ts`: mounted `/api/v1/passenger`.
- `server/tests/phase3.test.ts`: new Phase 3 integration tests.

### Flutter
- `apps/mobile/pubspec.yaml` and `apps/mobile/pubspec.lock`: added `geolocator`, `flutter_map`, and `latlong2`.
- `apps/mobile/android/app/src/main/AndroidManifest.xml`: added fine/coarse location permissions.
- `apps/mobile/ios/Runner/Info.plist`: added `NSLocationWhenInUseUsageDescription`.
- `apps/mobile/lib/src/features/passenger/domain/passenger_models.dart`: passenger profile/request and GPS result models.
- `apps/mobile/lib/src/features/passenger/domain/passenger_validators.dart`: coordinate and destination validators.
- `apps/mobile/lib/src/features/passenger/data/location_reader.dart`: device GPS abstraction with `Enable GPS` handling.
- `apps/mobile/lib/src/features/passenger/data/passenger_repository.dart`: authenticated passenger API client.
- `apps/mobile/lib/src/features/passenger/presentation/passenger_flow_page.dart`: Phase 3 passenger workflow screen with OSM map preview.
- `apps/mobile/lib/src/navigation/app_router.dart`: added protected `/passenger/request` route and marked Phase 3 complete.
- `apps/mobile/lib/src/features/dashboard/presentation/role_home_page.dart`: added passenger entry point.
- `apps/mobile/test/passenger_flow_test.dart`: new Phase 3 Flutter tests.

### Documentation
- `docs/PHASE_3.md`: this Phase 3 completion report.

## Features Implemented

### Backend
- Passenger-only current-location update stored in `passenger_profiles.current_latitude` and `current_longitude`.
- Waiting request creation in `passenger_requests` with:
  - passenger pickup coordinates,
  - destination name and coordinates,
  - passenger class copied from the profile,
  - `status = 'searching'`,
  - database-generated `requested_at` timestamp.
- Active waiting-request lookup for the authenticated passenger.
- Ownership-checked request detail lookup.
- Duplicate active-request prevention for non-terminal request statuses.
- Validation for coordinates and destination name.
- Audit logs for location updates and waiting-request creation.

### Flutter
- Passenger profile display.
- Device GPS capture with permission and disabled-service handling.
- Explicit `Enable GPS` prompt when location services are disabled.
- Manual coordinate entry fallback.
- OpenStreetMap preview of the captured pickup point.
- Destination name and coordinates entry.
- “I’m Waiting Here” submission.
- Active waiting-request summary.
- Passenger-home navigation into the workflow.
- Authenticated route guard for `/passenger/request`.

## API Endpoints

| Method | Endpoint | Access |
| --- | --- | --- |
| GET | `/api/v1/users/passenger/me` | Passenger |
| PATCH | `/api/v1/passenger/me/location` | Passenger |
| POST | `/api/v1/passenger/requests/waiting-here` | Passenger |
| GET | `/api/v1/passenger/requests/active` | Passenger |
| GET | `/api/v1/passenger/requests/:requestId` | Passenger owner |

## Database

No migration was added. Phase 1 already provided the required `passenger_profiles` and `passenger_requests` columns, including `request_status`, `requested_at`, coordinates, destination fields, and `passenger_class`. Existing Phase 1 and Phase 2 migrations were not modified.

Verified MPDC GeoJSON boundaries were not provided. `ZONE_1` and `ZONE_2` remain with `geojson = NULL`, and no coordinates or boundaries were fabricated.

## Test Results

- Backend: `npm test` — 12/12 tests passed, including 5 new Phase 3 tests.
- Backend typecheck: passed.
- Backend lint: passed.
- Flutter analyze: no issues.
- Flutter tests: 16/16 tests passed, including 5 new Phase 3 tests.
- Flutter web release build: succeeded.

## Remaining Issues

- Verified MPDC GeoJSON polygons and road networks for `ZONE_1` and `ZONE_2` remain pending.
- Real-device GPS behavior depends on platform permission settings and cannot be fully verified in automated tests.
- The OpenStreetMap tile preview emits the standard `flutter_map` public-tile advisory; production deployment should review the OSM Tile Usage Policy or use an approved tile provider.
- Flutter web build still reports non-fatal WASM dry-run findings from `flutter_secure_storage_web`.
- Matching status, driver assignment, notifications, cancellation, live monitoring, and analytics are intentionally deferred to later phases.
