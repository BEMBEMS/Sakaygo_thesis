import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../design/components/app_card.dart';
import '../../../design/components/app_scaffold.dart';
import '../../auth/data/api_exception.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../zone/domain/zone.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key, this.repository});

  final AuthRepository? repository;

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _DashboardData {
  const _DashboardData({required this.zones, required this.crossZoneAllowed});

  final List<ZoneSummary> zones;
  final bool crossZoneAllowed;
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  late Future<_DashboardData> _dashboardFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = context.read<AuthController>();
    final token = controller.token;
    final repository = widget.repository ?? const AuthRepository();

    if (!controller.isAuthenticated || token == null || token.isEmpty) {
      _dashboardFuture = Future<_DashboardData>.value(
        const _DashboardData(zones: <ZoneSummary>[], crossZoneAllowed: false),
      );
      return;
    }

    _dashboardFuture = Future.wait<dynamic>(<Future<dynamic>>[
      repository.fetchZones(token: token, admin: true),
      repository.fetchCrossZonePolicy(token),
    ]).then((results) {
      return _DashboardData(
        zones: results[0] as List<ZoneSummary>,
        crossZoneAllowed: results[1] as bool,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<AuthController>();

    return AppScaffold(
      title: 'Admin dashboard',
      subtitle: controller.user?.fullName ?? 'Administrative account',
      actions: [
        IconButton(
          tooltip: 'Sign out',
          onPressed: () async {
            await context.read<AuthController>().logout();
            if (context.mounted) {
              context.go('/');
            }
          },
          icon: const Icon(Icons.logout),
        ),
      ],
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Phase 2 administrative access',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Role-based sign-in and operating-zone oversight are active. Driver verification and user management remain later-phase work.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FutureBuilder<_DashboardData>(
                future: _dashboardFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  }

                  if (snapshot.hasError) {
                    final error = snapshot.error;

                    if (error is ApiException && error.isAuthFailure) {
                      WidgetsBinding.instance.addPostFrameCallback((_) async {
                        await controller.expireSession();
                        if (context.mounted) {
                          context.go('/admin/login');
                        }
                      });
                    }

                    return AppCard(
                      child: Text(
                        error is ApiException
                            ? error.message
                            : 'Unable to load administrative data.',
                      ),
                    );
                  }

                  final data =
                      snapshot.data ??
                      const _DashboardData(
                        zones: <ZoneSummary>[],
                        crossZoneAllowed: false,
                      );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppCard(
                        child: Text(
                          'Cross-zone matching: ${data.crossZoneAllowed ? 'allowed' : 'disabled'}',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Operating zones',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      if (data.zones.isEmpty)
                        const AppCard(
                          child: Text('No operating zones are configured.'),
                        )
                      else
                        Column(
                          children: data.zones.map((zone) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: AppCard(
                                child: ListTile(
                                  leading: Icon(
                                    zone.isActive
                                        ? Icons.check_circle_outline
                                        : Icons.pause_circle_outline,
                                  ),
                                  title: Text('${zone.code} · ${zone.name}'),
                                  subtitle: Text(
                                    '${zone.coverageDescription}\n'
                                    'Status: ${zone.zoneStatus} · '
                                    'Boundary: ${zone.hasBoundary ? 'configured' : 'not configured'}',
                                  ),
                                  isThreeLine: true,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
