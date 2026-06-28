import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/shared/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:ecopin_app/shared/widgets/app_text_field.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ecopin_app/shared/widgets/snackbar_helper.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final Logger _log = Logger("Login Screen");
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  void _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      SnackbarHelper.showError('Please enter email and password');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.login(email, password);

      // The backend returns the Supabase session
      final sessionData = response.data['session'];

      if (sessionData != null) {
        // We need to set the session in the Supabase SDK so the ApiClient
        // interceptor can pick up the token for subsequent requests.
        await Supabase.instance.client.auth.setSession(
          sessionData['refresh_token'],
        );

        if (mounted) {
          context.go('/maps'); // Initial Screen
        }
      } else {
        SnackbarHelper.showError('Login failed: Invalid session data');
      }
    } on DioException catch (e) {
      String errorMessage = 'Login failed';
      if (e.response?.data != null && e.response?.data['message'] != null) {
        errorMessage = e.response?.data['message'];
      }
      _log.severe(e);
      SnackbarHelper.showError("LOGIN ERROR: $errorMessage");
    } catch (e, stackTrace) {
      _log.severe(e, stackTrace);
      SnackbarHelper.showError('An unexpected error occurred: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Ecopin',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Login',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 32),
              AppTextField(
                controller: _emailController,
                labelText: 'Email',
                // keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _passwordController,
                labelText: 'Password',
                inputType: 'password',
              ),
              const SizedBox(height: 24),
              AppButton(
                text: 'Login',
                isLoading: _isLoading,
                variant: ButtonVariant.primary,
                onPressed: _isLoading ? null : _login,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => context.go('/register'),
                child: const Text(
                  "Don't have an account? Sign Up",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
