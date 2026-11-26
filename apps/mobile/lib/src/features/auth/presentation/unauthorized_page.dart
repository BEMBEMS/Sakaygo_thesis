import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../design/components/app_button.dart';
import '../../../design/components/app_scaffold.dart';

class UnauthorizedPage extends StatelessWidget {
  const UnauthorizedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Access restricted',
      body: _UnauthorizedBody(),
    );
  }
}

class _UnauthorizedBody extends StatelessWidget {
  const _UnauthorizedBody();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 64),
            const SizedBox(height: 20),
            Text(
              'Your account does not have access to this area.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Go to home',
              onPressed: () => context.go('/'),
            ),
          ],
        ),
      ),
    );
  }
}
