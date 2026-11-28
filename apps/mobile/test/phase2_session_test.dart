import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:tricycle_matching/src/features/auth/data/api_exception.dart';
import 'package:tricycle_matching/src/features/auth/data/auth_repository.dart';
import 'package:tricycle_matching/src/features/auth/data/secure_token_store.dart';
import 'package:tricycle_matching/src/features/auth/domain/auth_models.dart';
import 'package:tricycle_matching/src/features/auth/presentation/auth_controller.dart';
import 'package:tricycle_matching/src/features/dashboard/presentation/admin_dashboard_page.dart';
import 'package:tricycle_matching/src/features/zone/domain/zone.dart';
import 'package:tricycle_matching/src/navigation/app_router.dart';

class FakeTokenStore extends SecureTokenStore {
  FakeTokenStore({this.token});

  String? token;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> writeToken(String value) async => token = value;

  @override
  Future<void> clear() async => token = null;
}

class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository({
    this.user,
    this.authError,
    this.zoneError,
    this.zones = const <ZoneSummary>[],
    this.crossZoneAllowed = false,
  });

  AuthUser? user;
  ApiException? authError;
  Object? zoneError;
  List<ZoneSummary> zones;
  bool crossZoneAllowed;
  int logoutCalls = 0;

  @override
  Future<AuthSession> login({
    required String identifier,
    required String password,
    bool admin = false,
  }) async {
    if (authError != null) {
      throw authError!;
    }
    return AuthSession(token: 'test-token', user: user ?? _adminUser);
  }

  @override
  Future<AuthUser> fetchCurrentUser(String token) async {
    if (authError != null) {
      throw authError!;
    }
    return user ?? _adminUser;
  }

  @override
  Future<void> logout(String token) async {
    logoutCalls += 1;
  }

  @override
  Future<List<ZoneSummary>> fetchZones({
    required String token,
    bool admin = false,
  }) async {
    if (zoneError != null) {
      throw zoneError!;
    }
    return zones;
  }

  @override
  Future<bool> fetchCrossZonePolicy(String token) async =>
      crossZoneAllowed;
}

const AuthUser _passengerUser = AuthUser(
  userId: 'passenger-1',
  username: 'passenger',
  role: AppRole.passenger,
  firstName: 'Test',
  lastName: 'Passenger',
  isActive: true,
);

const AuthUser _adminUser = AuthUser(
  userId: 'admin-1',
  username: 'admin',
  role: AppRole.admin,
  firstName: 'Test',
  lastName: 'Admin',
  isActive: true,
);

const AuthUser _pendingDriverUser = AuthUser(
  userId: 'driver-1',
  username: 'driver',
  role: AppRole.driver,
  firstName: 'Test',
  lastName: 'Driver',
  isActive: true,
  verificationStatus: 'pending',
);

const AuthUser _verifiedDriverUser = AuthUser(
  userId: 'driver-2',
  username: 'driver2',
  role: AppRole.driver,
  firstName: 'Test',
  lastName: 'Driver',
  isActive: true,
  verificationStatus: 'verified',
);

Future<AuthController> signedInController(AuthUser user) async {
  final controller = AuthController(
    repository: FakeAuthRepository(user: user),
    store: FakeTokenStore(),
  );
  await controller.login(identifier: user.username, password: 'Password123!');
  return controller;
}

void main() {
  group('Phase 2 session handling', () {
    test('restore clears the token only for explicit auth failures', () async {
      final store = FakeTokenStore(token: 'stale-token');
      final controller = AuthController(
        repository: FakeAuthRepository(
          authError: const ApiException(
            code: 'AUTH_TOKEN_INVALID',
            message: 'Access token is invalid',
            statusCode: 401,
          ),
        ),
        store: store,
      );

      await controller.restore();

      expect(controller.status, AuthStatus.unauthenticated);
      expect(store.token, isNull);
    });

    test('restore preserves the stored token on network errors', () async {
      final store = FakeTokenStore(token: 'saved-token');
      final controller = AuthController(
        repository: FakeAuthRepository(
          authError: const ApiException(
            code: 'NETWORK_ERROR',
            message: 'Unable to connect to the server.',
          ),
        ),
        store: store,
      );

      await controller.restore();

      expect(controller.status, AuthStatus.unauthenticated);
      expect(store.token, 'saved-token');
    });

    test('logout revokes the server session and clears local storage', () async {
      final store = FakeTokenStore();
      final repository = FakeAuthRepository(user: _passengerUser);
      final controller = AuthController(repository: repository, store: store);

      await controller.login(identifier: 'passenger', password: 'Password123!');
      await controller.logout();

      expect(repository.logoutCalls, 1);
      expect(store.token, isNull);
      expect(controller.status, AuthStatus.unauthenticated);
    });

    test('API client exposes HTTP status for unauthorized responses', () async {
      final client = MockClient((request) async {
        return http.Response(
          '{"error":"AUTH_TOKEN_INVALID","message":"Access token is invalid"}',
          401,
          headers: {'content-type': 'application/json'},
        );
      });
      final repository = AuthRepository(
        client: client,
        baseUrl: 'http://test.invalid',
      );

      try {
        await repository.fetchCurrentUser('bad-token');
        fail('Expected an ApiException');
      } on ApiException catch (error) {
        expect(error.statusCode, 401);
        expect(error.isAuthFailure, isTrue);
      }
    });
  });

  group('Phase 2 route guards', () {
    test('unknown and anonymous sessions cannot render protected routes',
        () async {
      final unknown = AuthController(
        repository: FakeAuthRepository(),
        store: FakeTokenStore(),
      );
      final anonymous = AuthController(
        repository: FakeAuthRepository(),
        store: FakeTokenStore(),
      );
      await anonymous.restore();

      expect(resolveAuthRedirect(unknown, '/admin/dashboard'), '/');
      expect(resolveAuthRedirect(unknown, '/'), isNull);
      expect(resolveAuthRedirect(anonymous, '/admin/dashboard'), '/admin/login');
      expect(resolveAuthRedirect(anonymous, '/driver/home'), '/driver/login');
    });

    test('roles and driver verification are enforced', () async {
      final passenger = await signedInController(_passengerUser);
      final admin = await signedInController(_adminUser);
      final pendingDriver = await signedInController(_pendingDriverUser);
      final verifiedDriver = await signedInController(_verifiedDriverUser);

      expect(
        resolveAuthRedirect(passenger, '/admin/dashboard'),
        '/unauthorized',
      );
      expect(resolveAuthRedirect(passenger, '/passenger/home'), isNull);
      expect(resolveAuthRedirect(admin, '/admin/dashboard'), isNull);
      expect(resolveAuthRedirect(pendingDriver, '/driver/home'),
          '/unauthorized');
      expect(resolveAuthRedirect(verifiedDriver, '/driver/home'), isNull);
    });
  });

  group('Phase 2 admin dashboard states', () {
    Future<void> pumpDashboard(
      WidgetTester tester, {
      required AuthController controller,
      required AuthRepository repository,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthController>.value(
            value: controller,
            child: AdminDashboardPage(repository: repository),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders empty state and global cross-zone policy', (
      tester,
    ) async {
      final repository = FakeAuthRepository();
      final controller = await signedInController(_adminUser);

      await pumpDashboard(
        tester,
        controller: controller,
        repository: repository,
      );

      expect(find.text('No operating zones are configured.'), findsOneWidget);
      expect(find.text('Cross-zone matching: disabled'), findsOneWidget);
    });

    testWidgets('renders a readable error state', (tester) async {
      final repository = FakeAuthRepository(
        zoneError: const ApiException(
          code: 'NETWORK_ERROR',
          message: 'Unable to connect to the server.',
        ),
      );
      final controller = await signedInController(_adminUser);

      await pumpDashboard(
        tester,
        controller: controller,
        repository: repository,
      );

      expect(find.text('Unable to connect to the server.'), findsOneWidget);
    });
  });
}
