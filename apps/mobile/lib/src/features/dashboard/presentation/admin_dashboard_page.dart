import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../design/components/app_card.dart';
import '../../../design/components/app_scaffold.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../zone/domain/zone.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key, this.repository});

  final AuthRepository? repository;

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  late Future<List<ZoneSummary>> _zonesFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final token = context.read<AuthController>().token ?? '';
    _zonesFuture = (widget.repository ?? const AuthRepository()).fetchZones(
      token: token,
      admin: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AuthController>();

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
                      'Role-based sign-in and operating-zone oversight are active. Driver verification and user management are planned for Phase 7.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Operating zones',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<ZoneSummary>>(
                future: _zonesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  }

                  if (snapshot.hasError || !snapshot.hasData) {
                    return AppCard(
                      child: Text(
                        'Unable to load operating zones: ${snapshot.error}',
                      ),
                    );
                  }

                  final zones = snapshot.data!;
                  return Column(
                    children: zones
                        .map(
                          (zone) => Padding(
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
                                  'Boundary: ${zone.hasBoundary ? 'configured' : 'not configured'} · '
                                  'Cross-zone: ${zone.allowCrossZone ? 'allowed' : 'disabled'}',
                                ),
                                isThreeLine: true,
                              ),
                            ),
                          ),
                        )
                        .toList(),
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
