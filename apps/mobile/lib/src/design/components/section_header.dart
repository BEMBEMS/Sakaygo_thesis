import 'package:flutter/material.dart';
import '../app_spacing.dart';
import '../app_typography.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final subtitleText = subtitle;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.titleLarge),
              ? (subtitle == null
                  ? null
                  : const SizedBox(height: AppSpacing.xs)),
              ? (subtitleText == null
                  ? null
                  : Text(
                    subtitleText,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  )),
            ],
          ),
        ),
        ? (action == null ? null : const SizedBox(width: AppSpacing.md)),
        ? action,
      ],
    );
  }
}
