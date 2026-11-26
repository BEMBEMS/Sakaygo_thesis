import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tricycle_matching/src/features/passenger/data/location_reader.dart';
import 'package:tricycle_matching/src/features/passenger/data/passenger_repository.dart';
import 'package:tricycle_matching/src/features/passenger/domain/passenger_models.dart';
import 'package:tricycle_matching/src/features/passenger/domain/passenger_validators.dart';
import 'package:tricycle_matching/src/features/passenger/presentation/passenger_flow_page.dart';

class FakePassengerRepository extends PassengerRepository {
  const FakePassengerRepository();

  @override
  Future<PassengerProfile> fetchProfile(String token) async {
    return const PassengerProfile(
      passengerId: 'passenger-1',
      passengerClass: 'standard',
    );
  }

  @override
  Future<PassengerRequest?> fetchActiveRequest(String token) async {
    return null;
  }
}

class FakeLocationReader extends LocationReader {
  const FakeLocationReader();

  @override
  Future<LocationReadResult> readCurrentLocation() async {
    return LocationReadResult.disabled();
  }

  @override
  Future<void> openLocationSettings() async {}
}

void main() {
  group('passenger validators', () {
    test('accepts valid coordinates and destination names', () {
      expect(validateLatitude('8.7286'), isNull);
      expect(validateLongitude('125.4944'), isNull);
      expect(validateDestinationName('Del Monte proper'), isNull);
    });

    test('rejects invalid coordinates and empty destinations', () {
      expect(validateLatitude('91'), isNotNull);
      expect(validateLongitude('-181'), isNotNull);
      expect(validateDestinationName('   '), isNotNull);
    });
  });

  test('passenger request model maps API fields', () {
    final request = PassengerRequest.fromJson({
      'requestId': 'request-1',
      'passengerId': 'passenger-1',
      'pickupLatitude': 8.7286,
      'pickupLongitude': 125.4944,
      'destinationName': 'Talacogon Proper',
      'destinationLatitude': 8.7301,
      'destinationLongitude': 125.4956,
      'passengerClass': 'standard',
      'priorityScore': 0,
      'status': 'searching',
      'requestedAt': '2026-11-26T10:00:00.000Z',
    });

    expect(request.requestId, 'request-1');
    expect(request.destinationName, 'Talacogon Proper');
    expect(request.status, 'searching');
    expect(request.requestedAt.isUtc, isTrue);
  });

  test('disabled GPS result exposes the Enable GPS prompt', () {
    final result = LocationReadResult.disabled();
    expect(result.status, LocationReadStatus.disabled);
    expect(result.message, contains('Enable GPS'));
  });

  testWidgets('passenger flow shows profile and current location controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PassengerFlowPage(
          token: 'test-token',
          repository: FakePassengerRepository(),
          locationReader: FakeLocationReader(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Passenger profile'), findsOneWidget);
    expect(find.text('Class: standard'), findsOneWidget);
    expect(find.text('Use my current GPS location'), findsOneWidget);
    expect(find.text('I’m Waiting Here'), findsNWidgets(2));
    expect(find.text('Destination'), findsOneWidget);
  });
}
