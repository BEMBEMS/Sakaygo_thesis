import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/foundation/foundation_page.dart';
import '../features/foundation/module_foundation_page.dart';
import '../design/components/app_scaffold.dart';

GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: '/',
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
            'Phase 2: registration and authentication',
            'Phase 3: profile, current location, destination, and “I’m Waiting Here”',
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
            'Phase 2: registration and authentication',
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
            'Phase 2: administrator authentication and role-based access',
            'Phase 7: driver verification, TODA management, and user management',
            'Phase 7: live fleet, request, and matching-log monitoring',
            'Phase 8: matching-efficiency and utilization evaluation views',
          ],
        ),
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
