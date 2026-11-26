import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../design/app_theme.dart';
import '../features/auth/presentation/auth_controller.dart';
import '../navigation/app_router.dart';

final AuthController authController = AuthController();
final GoRouter _appRouter = createAppRouter(authController);

class TricycleMatchingApp extends StatelessWidget {
  const TricycleMatchingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthController>.value(
      value: authController,
      child: MaterialApp.router(
        title: 'Passenger–Tricycle Matching System',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        routerConfig: _appRouter,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
