import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tricycle_matching/src/features/foundation/module_foundation_page.dart';

void main() {
  testWidgets('module foundation page shows approved phase order', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ModuleFoundationPage(
          title: 'Passenger',
          description: 'Passenger workflow foundation.',
          icon: Icons.person_pin_circle_outlined,
          upcomingPhases: ['Phase 3: waiting request'],
        ),
      ),
    );

    expect(find.text('Passenger workflow foundation.'), findsOneWidget);
    expect(find.text('Phase 3: waiting request'), findsOneWidget);
    expect(find.text('foundation ready'), findsOneWidget);
  });
}
