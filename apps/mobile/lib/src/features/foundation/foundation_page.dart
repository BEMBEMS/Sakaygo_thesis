import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../../config/app_config.dart';
import '../../design/app_colors.dart';
import '../../design/app_spacing.dart';
import '../../design/components/app_card.dart';
import '../../design/components/app_scaffold.dart';
import '../../design/components/section_header.dart';
import '../../design/components/status_chip.dart';

class FoundationPage extends StatefulWidget {
  const FoundationPage({super.key});

  @override
  State<FoundationPage> createState() => _FoundationPageState();
}

class _FoundationPageState extends State<FoundationPage> {
  bool _isLoading = true;
  String? _error;
  String _overallStatus = 'checking';
  Map<String, String> _checks = const {};

  @override
  void initState() {
    super.initState();
    unawaited(_loadHealth());
  }

  Future<void> _loadHealth() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/health');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        throw Exception('API returned ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final rawChecks = decoded['checks'] as Map<String, dynamic>;

      if (!mounted) {
        return;
      }

      setState(() {
        _checks = rawChecks.map(
          (key, value) => MapEntry(key, value.toString()),
        );
        _overallStatus = decoded['status']?.toString() ?? 'unknown';
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = 'Backend is unreachable. Start the API and try again.';
        _overallStatus = 'unavailable';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'System foundation',
      subtitle: 'Phase 1 · project structure, data, design, and navigation',
      actions: [
        IconButton(
          onPressed: () => unawaited(_loadHealth()),
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh service status',
        ),
      ],
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          final cardWidth = isWide
              ? (constraints.maxWidth - AppSpacing.md * 2) / 3
              : constraints.maxWidth;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HeroCard(status: _overallStatus, isLoading: _isLoading),
                    const SizedBox(height: AppSpacing.xl),
                    const SectionHeader(
                      title: 'Application modules',
                      subtitle: 'Navigation shells for the three documented user roles',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.md,
                      children: [
                        SizedBox(
                          width: cardWidth,
                          child: _ModuleCard(
                            title: 'Passenger',
                            description:
                                'Location, destination, and waiting-request workflow.',
                            icon: Icons.person_pin_circle_outlined,
                            route: '/passenger',
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _ModuleCard(
                            title: 'Driver',
                            description:
                                'Verification, availability, GPS, and dispatch workflow.',
                            icon: Icons.two_wheeler_outlined,
                            route: '/driver',
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _ModuleCard(
                            title: 'Administrator / LGU',
                            description:
                                'TODA, verification, monitoring, and optimization logs.',
                            icon: Icons.admin_panel_settings_outlined,
                            route: '/admin',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const SectionHeader(
                      title: 'Connected services',
                      subtitle: 'Live health reported by the Express API',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _ServiceStatusCard(
                      isLoading: _isLoading,
                      error: _error,
                      checks: _checks,
                      onRetry: () => unawaited(_loadHealth()),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Primary reference: Thesis_Revised_Final (4).docx',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.status, required this.isLoading});

  final String status;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final tone = switch (status) {
      'ok' => AppStatusTone.success,
      'degraded' => AppStatusTone.warning,
      'unavailable' => AppStatusTone.error,
      _ => AppStatusTone.info,
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusChip(
            label: isLoading ? 'checking services' : status,
            tone: tone,
            icon: isLoading ? Icons.sync : Icons.cloud_done_outlined,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Passenger–tricycle matching foundation',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Text(
              'A research-based system for optimizing passenger–driver '
              'assignments under limited tricycle availability in sparse '
              'and remote municipal areas.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.86),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.route,
  });

  final String title;
  final String description;
  final IconData icon;
  final String route;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.go(route),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(icon, color: AppColors.primaryDark),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Text(
                'Open module',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              const Icon(Icons.arrow_forward, size: 16, color: AppColors.primary),
            ],
          ),
        ],
      ),
    );
  }
}

class _ServiceStatusCard extends StatelessWidget {
  const _ServiceStatusCard({
    required this.isLoading,
    required this.error,
    required this.checks,
    required this.onRetry,
  });

  final bool isLoading;
  final String? error;
  final Map<String, String> checks;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const AppCard(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: AppSpacing.md),
              Text('Checking API, database, Redis, and matching service…'),
            ],
          ),
        ),
      );
    }

    if (error != null) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StatusChip(
              label: 'API unavailable',
              tone: AppStatusTone.error,
              icon: Icons.cloud_off_outlined,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(error!),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final entries = checks.entries.toList();

    return AppCard(
      child: Column(
        children: [
          for (var index = 0; index < entries.length; index++)
            _StatusRow(label: entries[index].key, value: entries[index].value),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tone = value == 'ok' ? AppStatusTone.success : AppStatusTone.warning;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.replaceAll('Service', ' service'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          StatusChip(label: value, tone: tone),
        ],
      ),
    );
  }
}
