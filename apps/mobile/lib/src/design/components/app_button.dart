import 'package:flutter/material.dart';
import '../app_spacing.dart';

enum AppButtonVariant { filled, outlined, text }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.filled,
    this.icon,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment:
          expanded ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: [
        if (icon != null) Icon(icon, size: 18),
        if (icon != null) const SizedBox(width: AppSpacing.sm),
        Text(label),
      ],
    );

    final button = switch (variant) {
      AppButtonVariant.filled => ElevatedButton(
        onPressed: onPressed,
        child: child,
      ),
      AppButtonVariant.outlined => OutlinedButton(
        onPressed: onPressed,
        child: child,
      ),
      AppButtonVariant.text => TextButton(onPressed: onPressed, child: child),
    };

    if (!expanded) {
      return button;
    }

    return SizedBox(width: double.infinity, child: button);
  }
}
