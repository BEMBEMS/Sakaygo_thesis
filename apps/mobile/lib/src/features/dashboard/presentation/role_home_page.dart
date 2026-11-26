import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../design/components/app_button.dart';
import '../../../design/components/app_card.dart';
import '../../../design/components/app_scaffold.dart';
import '../../auth/domain/auth_models.dart';
import '../../auth/presentation/auth_controller.dart';

class RoleHomePage extends StatelessWidget {
  const RoleHomePage({super.key, required this.role});

  final AppRole role;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AuthController>();
    final user = controller.user;

    return AppScaffold(
      title: role == AppRole.passenger ? 'Passenger home' : 'Driver home',
      subtitle: user?.fullName ?? 'Account',
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
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, ${user?.firstName ?? 'user'}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      role == AppRole.passenger
                          ? 'Passenger authentication is active. You can capture your location and submit a waiting request.'
                          : 'Driver authentication is active. Verification and dispatch flows are planned for Phase 4.',
                    ),
                  ],
                ),
              ),
              if (role == AppRole.passenger) ...[
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Waiting request',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Record where you are waiting and where you want to go.',
                      ),
                      const SizedBox(height: 16),
                      AppButton(
                        label: 'Start “I’m Waiting Here”',
                        icon: Icons.person_pin_circle_outlined,
                        onPressed: () => context.go('/passenger/request'),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account details',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(label: 'Username', value: user?.username ?? '-'),
                    _DetailRow(label: 'Role', value: role.label),
                    if (role == AppRole.driver)
                      _DetailRow(
                        label: 'Verification',
                        value: user?.verificationStatus ?? 'pending',
                      ),
                    if (role == AppRole.driver)
                      _DetailRow(
                        label: 'Operating zone',
                        value: user?.operatingZoneId ?? 'not assigned',
                      ),
                  ],
                ),
              ),
              if (role == AppRole.driver &&
                  user?.verificationStatus != 'verified')
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: AppCard(
                    child: Text(
                      'Your driver account is pending LGU verification. Verified accounts can use driver-only endpoints.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
