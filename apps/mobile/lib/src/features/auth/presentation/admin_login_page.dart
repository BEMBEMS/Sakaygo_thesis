import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../design/components/app_text_field.dart';
import '../domain/auth_validators.dart';
import 'auth_controller.dart';
import 'auth_shell.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AuthController>();

    return AuthShell(
      title: 'Administrator sign in',
      subtitle: 'Restricted to LGU, TODA, and system administrator accounts.',
      formKey: _formKey,
      error: controller.error,
      isBusy: controller.isBusy,
      fields: [
        AppTextField(
          label: 'Username or email',
          controller: _identifierController,
          prefixIcon: Icons.admin_panel_settings_outlined,
          validator: (value) => validateRequired(value, 'Username or email'),
        ),
        AppTextField(
          label: 'Password',
          controller: _passwordController,
          prefixIcon: Icons.lock_outline,
          validator: validatePassword,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            onPressed: () {
              setState(() => _obscurePassword = !_obscurePassword);
            },
            icon: Icon(
              _obscurePassword ? Icons.visibility : Icons.visibility_off,
            ),
          ),
        ),
      ],
      submitLabel: 'Open dashboard',
      onSubmit: () async {
        if (!_formKey.currentState!.validate()) {
          return;
        }

        final success = await context.read<AuthController>().adminLogin(
          identifier: _identifierController.text.trim(),
          password: _passwordController.text,
        );

        if (!context.mounted) {
          return;
        }
        if (!success) {
          return;
        }

        context.go('/admin/dashboard');
      },
      footer: Align(
        alignment: Alignment.center,
        child: TextButton(
          onPressed: () => context.go('/'),
          child: const Text('Back to foundation overview'),
        ),
      ),
    );
  }
}
