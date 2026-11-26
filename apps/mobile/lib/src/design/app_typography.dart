import 'package:flutter/material.dart';

class AppTypography {
  static const TextStyle displayLarge = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.8,
    height: 1.15,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    height: 1.2,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle bodyLarge = TextStyle(fontSize: 16, height: 1.5);
  static const TextStyle bodyMedium = TextStyle(fontSize: 14, height: 1.45);
  static const TextStyle bodySmall = TextStyle(fontSize: 12, height: 1.4);
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static TextTheme get textTheme => const TextTheme(
    displayLarge: displayLarge,
    headlineMedium: headlineMedium,
    titleLarge: titleLarge,
    titleMedium: titleMedium,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    bodySmall: bodySmall,
    labelLarge: labelLarge,
  );
}
