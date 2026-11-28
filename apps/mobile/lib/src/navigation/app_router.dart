import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../design/components/app_scaffold.dart';
import '../features/auth/domain/auth_models.dart';
import '../features/auth/presentation/admin_login_page.dart';
import '../features/auth/presentation/auth_controller.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/register_driver_page.dart';
import '../features/auth/presentation/register_passenger_page.dart';
import '../features/auth/presentation/unauthorized_page.dart';
import '../features/dashboard/presentation/admin_dashboard_page.dart';
import '../features/dashboard/presentation/role_home_page.dart';
import '../features/foundation/foundation_page.dart';
import '../features/foundation/module_foundation_page.dart';
import '../features/passenger/presentation/passenger_flow_page.dart';

const Set<String> _authPaths = <String>{
  '/passenger/login',
  '/passenger/register',
  '/driver/login',
  '/driver/register',
  '/admin/login',
};

const Map<String, Set<AppRole>> _protectedRoles = <String, Set<AppRole>>{
  '/passenger/home': <AppRole>{AppRole.passenger},
  '/passenger/request': <AppRole>{AppRole.passenger},
  '/driver/home': <AppRole>{AppRole.driver},
  '/admin/dashboard': <AppRole>{AppRole.admin, AppRole.lgu, AppRole.toda},
};

String? resolveAuthRedirect(AuthController auth, String path) {
  if (auth.status == AuthStatus.unknown) {
    return _protectedRoles.containsKey(path) ? '/' : null;
  }

  final allowedRoles = _protectedRoles[path];

  if (auth.status == AuthStatus.unauthenticated) {
    return allowedRoles == null ? null : _loginPathFor(path);
  }

  final user = auth.user;

  if (user == null) {
    return allowedRoles == null ? null : _loginPathFor(path);
  }

  if (_authPaths.contains(path)) {
    return _homeFor(user);
  }

  if (allowedRoles != null && !allowedRoles.contains(user.role)) {
    return '/unauthorized';
  }

  if (path == '/driver/home' &&
      user.role == AppRole.driver &&
      user.verificationStatus != 'verified') {
    return '/unauthorized';
  }

  return null;
}

GoRouter createAppRouter(AuthController auth) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: auth,
    redirect: (context, state) =>
        resolveAuthRedirect(auth, state.uri.path),
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const FoundationPage(),
      ),
      GoRoute(
        path: '/passenger',
        builder: (context, state) => const ModuleFoundationPage(
          title: 'Passenger',
          description:
              'Passenger-facing workflows for location, destination, and waiting requests.',
          icon: Icons.person_pin_circle_outlined,
          upcomingPhases: [
            'Phase 2 complete: registration and authentication',
            'Phase 3 complete: profile, current location, destination, and “I’m Waiting Here”',
            'Phase 5: matching status, recommended driver, and pickup details',
            'Phase 6: acceptance, decline, and request-status notifications',
          ],
        ),
      ),
      GoRoute(
        path: '/driver',
        builder: (context, state) => const ModuleFoundationPage(
          title: 'Driver',
          description:
              'Verified tricycle driver workflows for availability, GPS, and dispatch.',
          icon: Icons.two_wheeler_outlined,
          upcomingPhases: [
            'Phase 2 complete: registration and pending verification sign-in',
            'Phase 4: TODA registration, verification, availability, and GPS updates',
            'Phase 5: assignment offers, acceptance, decline, and active trips',
            'Phase 6: real-time request synchronization',
          ],
        ),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const ModuleFoundationPage(
          title: 'Administrator / LGU',
          description:
              'Municipal oversight of accounts, TODA records, matching activity, and metrics.',
          icon: Icons.admin_panel_settings_outlined,
          upcomingPhases: [
            'Phase 2 complete: administrator authentication and role-based access',
            'Phase 7: driver verification, TODA management, and user management',
            'Phase 7: live fleet, request, and matching-log monitoring',
            'Phase 8: matching-efficiency and utilization evaluation views',
          ],
        ),
      ),
      GoRoute(
        path: '/unauthorized',
        builder: (context, state) => const UnauthorizedPage(),
      ),
      GoRoute(
        path: '/passenger/login',
        builder: (context, state) => const LoginPage(role: AppRole.passenger),
      ),
      GoRoute(
        path: '/passenger/register',
        builder: (context, state) => const RegisterPassengerPage(),
      ),
      GoRoute(
        path: '/driver/login',
        builder: (context, state) => const LoginPage(role: AppRole.driver),
      ),
      GoRoute(
        path: '/driver/register',
        builder: (context, state) => const RegisterDriverPage(),
      ),
      GoRoute(
        path: '/admin/login',
        builder: (context, state) => const AdminLoginPage(),
      ),
      GoRoute(
        path: '/passenger/home',
        builder: (context, state) =>
            const RoleHomePage(role: AppRole.passenger),
      ),
      GoRoute(
        path: '/passenger/request',
        builder: (context, state) => const PassengerFlowPage(),
      ),
      GoRoute(
        path: '/driver/home',
        builder: (context, state) => const RoleHomePage(role: AppRole.driver),
      ),
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminDashboardPage(),
      ),
    ],
    errorBuilder: (context, state) => AppScaffold(
      title: 'Page not found',
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('No route matches ${state.uri.path}'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/'),
              child: const Text('Back to foundation'),
            ),
          ],
        ),
      ),
    ),
  );
}

String _loginPathFor(String path) {
  if (path.startsWith('/driver')) {
    return '/driver/login';
  }
  if (path.startsWith('/admin')) {
    return '/admin/login';
  }
  return '/passenger/login';
}

String _homeFor(AuthUser user) {
  if (user.role == AppRole.driver) {
    return user.verificationStatus == 'verified'
        ? '/driver/home'
        : '/unauthorized';
  }
  if (user.role.isAdministrative) {
    return '/admin/dashboard';
  }
  return '/passenger/home';
}
