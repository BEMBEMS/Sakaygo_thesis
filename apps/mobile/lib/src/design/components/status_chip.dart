import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../app_spacing.dart';

enum AppStatusTone { success, warning, error, info, neutral }

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.tone = AppStatusTone.neutral,
    this.icon,
  });

  final String label;
  final AppStatusTone tone;
  final IconData? icon;

  Color get _color => switch (tone) {
    AppStatusTone.success => AppColors.success,
    AppStatusTone.warning => AppColors.warning,
    AppStatusTone.error => AppColors.error,
    AppStatusTone.info => AppColors.info,
    AppStatusTone.neutral => AppColors.textSecondary,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) Icon(icon, size: 14, color: _color),
          if (icon != null) const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
