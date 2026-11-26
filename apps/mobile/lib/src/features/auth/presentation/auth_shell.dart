import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_spacing.dart';
import '../../../design/components/app_button.dart';
import '../../../design/components/app_card.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.formKey,
    required this.fields,
    required this.submitLabel,
    required this.onSubmit,
    required this.footer,
    this.error,
    this.isBusy = false,
  });

  final String title;
  final String subtitle;
  final GlobalKey<FormState> formKey;
  final List<Widget> fields;
  final String submitLabel;
  final VoidCallback onSubmit;
  final Widget footer;
  final String? error;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Authentication')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: AppCard(
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                          ),
                          child: const Icon(
                            Icons.lock_outline,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          title,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        if (error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusSm,
                                ),
                              ),
                              child: Text(
                                error!,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppColors.error),
                              ),
                            ),
                          ),
                        ..._spacedFields(),
                        const SizedBox(height: AppSpacing.md),
                        if (isBusy)
                          const Padding(
                            padding: EdgeInsets.only(bottom: AppSpacing.md),
                            child: Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          ),
                        AppButton(
                          label: submitLabel,
                          onPressed: isBusy ? null : onSubmit,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        footer,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _spacedFields() {
    final widgets = <Widget>[];

    for (final field in fields) {
      widgets.add(field);
      widgets.add(const SizedBox(height: AppSpacing.md));
    }

    return widgets;
  }
}
