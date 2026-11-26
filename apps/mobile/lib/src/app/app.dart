import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../design/app_theme.dart';
import '../navigation/app_router.dart';

final GoRouter _appRouter = createAppRouter();

class TricycleMatchingApp extends StatelessWidget {
  const TricycleMatchingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Passenger–Tricycle Matching System',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: _appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
