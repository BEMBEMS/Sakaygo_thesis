import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../design/components/app_text_field.dart';
import '../../zone/domain/zone.dart';
import '../data/auth_repository.dart';
import '../domain/auth_validators.dart';
import 'auth_controller.dart';
import 'auth_shell.dart';

class RegisterDriverPage extends StatefulWidget {
  const RegisterDriverPage({super.key, this.repository});

  final AuthRepository? repository;

  @override
  State<RegisterDriverPage> createState() => _RegisterDriverPageState();
}

class _RegisterDriverPageState extends State<RegisterDriverPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _licenseController = TextEditingController();
  final _membershipController = TextEditingController();
  final _plateController = TextEditingController();
  late Future<List<TodaOption>> _todasFuture;
  TodaOption? _selectedToda;
  bool _obscurePassword = true;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    final repository = widget.repository ?? const AuthRepository();
    _todasFuture = repository.fetchTodas();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _licenseController.dispose();
    _membershipController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AuthController>();

    return AuthShell(
      title: 'Register as a driver',
      subtitle: 'Accounts remain pending until LGU verification is complete.',
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
          label: 'Driver license number',
          controller: _licenseController,
          prefixIcon: Icons.card_membership_outlined,
          validator: (value) {
            final text = value?.trim() ?? '';
            if (text.length < 5) {
              return 'License number must be at least 5 characters';
            }
            return null;
          },
        ),
        AppTextField(
          label: 'TODA membership ID',
          controller: _membershipController,
          prefixIcon: Icons.badge_outlined,
          validator: (value) {
            final text = value?.trim() ?? '';
            if (text.length < 3) {
              return 'TODA membership ID must be at least 3 characters';
            }
            return null;
          },
        ),
        AppTextField(
          label: 'Plate number',
          controller: _plateController,
          prefixIcon: Icons.two_wheeler_outlined,
          validator: (value) {
            final text = value?.trim() ?? '';
            if (text.length < 3) {
              return 'Plate number must be at least 3 characters';
            }
            return null;
          },
        ),
        FutureBuilder<List<TodaOption>>(
          future: _todasFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }

            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
              return const Text(
                'Unable to load TODA list. Registration requires an active TODA.',
              );
            }

            return DropdownButtonFormField<TodaOption>(
              initialValue: _selectedToda,
              decoration: const InputDecoration(
                labelText: 'TODA',
                prefixIcon: Icon(Icons.groups_outlined),
              ),
              items: snapshot.data!
                  .map(
                    (toda) => DropdownMenuItem<TodaOption>(
                      value: toda,
                      child: Text(toda.displayName),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedToda = value);
              },
              validator: (value) => value == null ? 'Select your TODA' : null,
            );
          },
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
              'Driver registration submitted. Wait for LGU verification before signing in.',
            ),
          ),
      ],
      submitLabel: 'Submit registration',
      onSubmit: () async {
        if (!_formKey.currentState!.validate() || _selectedToda == null) {
          return;
        }

        final email = _emailController.text.trim();
        final phone = _phoneController.text.trim();
        final success = await context.read<AuthController>().registerDriver({
          'username': _usernameController.text.trim(),
          'password': _passwordController.text,
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'licenseNumber': _licenseController.text.trim(),
          'todaMembershipId': _membershipController.text.trim(),
          'vehiclePlateNumber': _plateController.text.trim(),
          'todaOrgId': _selectedToda!.todaId,
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
          onPressed: () => context.go('/driver/login'),
          child: const Text('Already registered? Sign in'),
        ),
      ),
    );
  }
}
