import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../design/components/app_text_field.dart';
import '../domain/auth_models.dart';
import '../domain/auth_validators.dart';
import 'auth_controller.dart';
import 'auth_shell.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.role});

  final AppRole role;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
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
      final isPassenger = widget.role == AppRole.passenger;

      return AuthShell(
        title: isPassenger ? 'Passenger sign in' : 'Driver sign in',
        subtitle: isPassenger
            ? 'Sign in to request a tricycle in Talacogon.'
            : 'Sign in to view your verification and dispatch status.',
        formKey: _formKey,
        error: controller.error,
        isBusy: controller.isBusy,
        fields: [
          AppTextField(
            label: 'Username or email',
            controller: _identifierController,
            prefixIcon: Icons.person_outline,
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
        submitLabel: 'Sign in',
        onSubmit: () async {
          if (!_formKey.currentState!.validate()) {
            return;
          }

          final success = await context.read<AuthController>().login(
            identifier: _identifierController.text.trim(),
            password: _passwordController.text,
          );

          if (!context.mounted) {
            return;
          }
          if (!success) {
            return;
          }

          context.go(isPassenger ? '/passenger/home' : '/driver/home');
        },
        footer: Align(
          alignment: Alignment.center,
          child: TextButton(
            onPressed: () {
              context.go(
                isPassenger ? '/passenger/register' : '/driver/register',
              );
            },
            child: Text(
              isPassenger
                  ? 'New passenger? Create an account'
                  : 'New driver? Register here',
            ),
          ),
        ),
      );
    }
}
