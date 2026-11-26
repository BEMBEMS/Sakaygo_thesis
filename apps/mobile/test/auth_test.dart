import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tricycle_matching/src/features/auth/data/api_exception.dart';
import 'package:tricycle_matching/src/features/auth/domain/auth_models.dart';
import 'package:tricycle_matching/src/features/auth/domain/auth_validators.dart';
import 'package:tricycle_matching/src/features/auth/presentation/auth_shell.dart';
import 'package:tricycle_matching/src/features/zone/domain/zone.dart';

void main() {
  group('auth validators', () {
    test('accepts valid credentials and rejects weak passwords', () {
      expect(validateUsername('driver_1'), isNull);
      expect(validatePassword('Password123!'), isNull);
      expect(validatePassword('short'), isNotNull);
      expect(validateUsername('bad name'), isNotNull);
    });

    test('allows optional contact details but rejects invalid values', () {
      expect(validateEmail(''), isNull);
      expect(validateEmail('not-an-email'), isNotNull);
      expect(validatePhone(''), isNull);
      expect(validatePhone('123'), isNotNull);
    });
  });

  test('auth models map API field names', () {
    final user = AuthUser.fromJson({
      'user_id': 'user-1',
      'username': 'driver_1',
      'role': 'driver',
      'first_name': 'Juan',
      'last_name': 'Dela Cruz',
      'is_active': true,
      'verification_status': 'pending',
      'operating_zone_id': 'zone-1',
    });

    expect(user.userId, 'user-1');
    expect(user.role, AppRole.driver);
    expect(user.fullName, 'Juan Dela Cruz');
    expect(user.verificationStatus, 'pending');
    expect(user.operatingZoneId, 'zone-1');
  });

  test('zone summaries identify active configured boundaries', () {
    final zone = ZoneSummary.fromJson({
      'zoneId': 'zone-1',
      'code': 'ZONE_1',
      'name': 'Zone 1 – TATMODA',
      'zoneStatus': 'active',
      'hasBoundary': false,
      'allowCrossZone': false,
      'coverageDescription': 'Talacogon Proper',
      'geojsonSource': 'awaiting_verified_mpdc_geojson',
    });

    expect(zone.isActive, isTrue);
    expect(zone.hasBoundary, isFalse);
    expect(zone.allowCrossZone, isFalse);
  });

  test('API exceptions carry server error codes', () {
    const exception = ApiException(code: 'ADMIN_ACCESS_DENIED', message: 'Denied');
    expect(exception.code, 'ADMIN_ACCESS_DENIED');
    expect(exception.toString(), 'Denied');
  });

  testWidgets('auth shell renders title, fields, and errors', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AuthShell(
            title: 'Passenger sign in',
            subtitle: 'Sign in to continue',
            formKey: GlobalKey<FormState>(),
            fields: const [Text('Username field'), Text('Password field')],
            submitLabel: 'Sign in',
            onSubmit: () {},
            error: 'Invalid credentials',
            footer: const Text('Create account'),
          ),
        ),
      ),
    );

    expect(find.text('Passenger sign in'), findsOneWidget);
    expect(find.text('Username field'), findsOneWidget);
    expect(find.text('Invalid credentials'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
  });
}
