import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tricycle_matching/src/design/app_colors.dart';
import 'package:tricycle_matching/src/design/app_theme.dart';
import 'package:tricycle_matching/src/design/components/app_button.dart';
import 'package:tricycle_matching/src/design/components/status_chip.dart';

void main() {
  test('design tokens define a primary color', () {
    expect(AppColors.primary, isA<Color>());
  });

  test('light theme uses Material 3', () {
    expect(AppTheme.light.useMaterial3, isTrue);
  });

  testWidgets('AppButton renders its label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppButton(label: 'Continue'),
        ),
      ),
    );

    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('StatusChip renders its label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatusChip(label: 'foundation ready'),
        ),
      ),
    );

    expect(find.text('foundation ready'), findsOneWidget);
  });
}
