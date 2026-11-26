import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../design/components/app_text_field.dart';
import '../domain/auth_validators.dart';
import 'auth_controller.dart';
import 'auth_shell.dart';

class RegisterPassengerPage extends StatefulWidget {
  const RegisterPassengerPage({super.key});

  @override
  State<RegisterPassengerPage> createState() => _RegisterPassengerPageState();
}

class _RegisterPassengerPageState extends State<RegisterPassengerPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _obscurePassword = true;
  bool _submitted = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AuthController>();

    return AuthShell(
      title: 'Create passenger account',
      subtitle: 'Use your details as registered with the LGU.',
      formKey: _formKey,
      error: controller.error,
      isBusy: controller.isBusy,
      fields: [
        AppTextField(
          label: 'Username',
          controller: _usernameController,
          prefixIcon: Icons.alternate_email,
          validator: validateUsername,
        ),
        AppTextField(
          label: 'First name',
          controller: _firstNameController,
          prefixIcon: Icons.badge_outlined,
          validator: (value) => validateName(value, 'First name'),
        ),
        AppTextField(
          label: 'Last name',
          controller: _lastNameController,
          prefixIcon: Icons.badge_outlined,
          validator: (value) => validateName(value, 'Last name'),
        ),
        AppTextField(
          label: 'Email (optional)',
          controller: _emailController,
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: validateEmail,
        ),
        AppTextField(
          label: 'Phone number (optional)',
          controller: _phoneController,
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          validator: validatePhone,
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
        if (_submitted)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Account created. You can now sign in.',
            ),
          ),
      ],
      submitLabel: 'Create account',
      onSubmit: () async {
        if (!_formKey.currentState!.validate()) {
          return;
        }

        final email = _emailController.text.trim();
        final phone = _phoneController.text.trim();
        final success = await context.read<AuthController>().registerPassenger({
          'username': _usernameController.text.trim(),
          'password': _passwordController.text,
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          if (email.isNotEmpty) 'email': email,
          if (phone.isNotEmpty) 'phoneNumber': phone,
        });

        if (!mounted) {
          return;
        }
        if (!success) {
          return;
        }

        setState(() => _submitted = true);
      },
      footer: Align(
        alignment: Alignment.center,
        child: TextButton(
          onPressed: () => context.go('/passenger/login'),
          child: const Text('Already registered? Sign in'),
        ),
      ),
    );
  }
}
