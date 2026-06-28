import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/shared/widgets/app_button.dart';
import 'package:ecopin_app/shared/widgets/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:ecopin_app/shared/widgets/app_text_field.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:logging/logging.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final Logger _log = Logger("Register Screen");
  bool _isLoading = false;

  void signUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Frontend validation
    // TODO: Make modular later, isang file nalang baguhin for validation rules.

    if (email.isEmpty) {
      SnackbarHelper.showError('Email is required');
      return;
    }
    if (password.isEmpty) {
      SnackbarHelper.showError('Password is required');
      return;
    }
    if (password != confirmPassword) {
      SnackbarHelper.showError('Passwords do not match');
      return;
    }
    if (password.length < 6) {
      SnackbarHelper.showError('Password must be at least 6 characters');
      return;
    }

    setState(() => _isLoading = true);

    try {

      final apiClient = ref.read(apiClientProvider);
      // TODO: Lagyan ng Confirm Email
      final response = await apiClient.register(
        email,
        password,
        confirmPassword,
      );

      if (mounted) {
        SnackbarHelper.showMessage('Registration successful');
        // Go to login page after successful registration
        context.go('/login');
      }
    } on DioException catch (e, stackTrace) {

      String errorMessage = 'Registration failed';
      // String errorMessage = 'RF: $e';

      _log.severe(e, stackTrace);

      if (e.response?.data != null && e.response?.data['message'] != null) {
        errorMessage = e.response?.data['message'];
      } else if (e.response?.data != null &&
          e.response?.data['errors'] != null) {
        // Handle express-validator errors
        final errors = e.response?.data['errors'] as List;
        if (errors.isNotEmpty) {
          errorMessage = errors[0]['msg'];
        }
      }
      SnackbarHelper.showError(errorMessage);
    } catch (e, stackTrace) {
       _log.severe(e, stackTrace);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            AppTextField(controller: _emailController, labelText: 'Email'),
            const SizedBox(height: 16),
            AppTextField(
              controller: _passwordController,
              labelText: 'Password',
              inputType: 'password',
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _confirmPasswordController,
              labelText: 'Confirm Password',
              inputType: 'password',
            ),
            const SizedBox(height: 32),
            AppButton(
              text: 'Register',
              isLoading: _isLoading,
              onPressed: _isLoading ? null : signUp,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                context.go('/login');
              },
              child: const Text('Already have an account? Log in'),
            ),
          ],
        ),
      ),
    );
  }
}
