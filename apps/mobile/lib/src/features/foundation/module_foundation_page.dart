import 'package:flutter/material.dart';

import '../../design/app_colors.dart';
import '../../design/app_spacing.dart';
import '../../design/components/app_card.dart';
import '../../design/components/app_scaffold.dart';
import '../../design/components/section_header.dart';
import '../../design/components/status_chip.dart';

class ModuleFoundationPage extends StatelessWidget {
  const ModuleFoundationPage({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.upcomingPhases,
  });

  final String title;
  final String description;
  final IconData icon;
  final List<String> upcomingPhases;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: title,
      subtitle: 'Phase 1 · navigation shell',
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                        ),
                        child: Icon(icon, color: AppColors.primaryDark),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(title, style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const StatusChip(
                        label: 'foundation ready',
                        tone: AppStatusTone.success,
                        icon: Icons.check_circle_outline,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                const SectionHeader(
                  title: 'Implementation order',
                  subtitle: 'Features are added only after their phase is approved',
                ),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final phase in upcomingPhases)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.schedule,
                                size: 18,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(
                                  phase,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
