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
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/shared/auth/providers/auth_notifier.dart';
import 'package:ecopin_app/core/constants/app_constants.dart';

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
        // Establish the Supabase session from the tokens returned by the
        // backend.
        await Supabase.instance.client.auth.setSession(
          sessionData['refresh_token'],
          accessToken: sessionData['access_token'],
        );
        
        // Parse role directly from response to bypass AuthNotifier async delays
        final userData = response.data['user'];
        final roleString = userData?['role'] as String?;
        UserRole role = UserRole.citizen; // Default

        if (roleString != null) {
          if (roleString == 'field_crew') {
            role = UserRole.fieldCrew;
          } else {
            role = UserRole.values.firstWhere(
              (e) => e.name == roleString,
              orElse: () => UserRole.citizen,
            );
          }
        }

        if (mounted) {
          // Force the notifier to instantly recognize the authenticated state 
          // so GoRouter doesn't intercept the navigation and throw us back to login!
          ref.read(authNotifierProvider.notifier).manualOverrideAuthenticatedState(role);

          if (role == UserRole.officer) {
            context.go('/officer/dashboard');
          } else if (role == UserRole.admin) {
            context.go('/admin/dashboard');
          } else if (role == UserRole.fieldCrew) {
            context.go('/field-crew/dashboard');
          } else {
            context.go('/maps');
          }
        }
      } else {
        SnackbarHelper.showError('Login failed: Invalid session data');
      }
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data['code'] == 'EMAIL_NOT_VERIFIED') {
        if (mounted) {
          context.go('/email-verification?email=${Uri.encodeComponent(email)}');
        }
        return;
      }
      
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/landing'),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppColors.spaceXL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset(
                Theme.of(context).brightness == Brightness.light 
                    ? 'assets/logos/Full Logo Light.png' 
                    : 'assets/logos/Full Logo Dark.png',
                height: 60,
              ),
              const SizedBox(height: AppColors.spaceSM),
              Text(
                'Login',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppColors.spaceXXL),
              AppTextField(
                controller: _emailController,
                labelText: 'Email',
                // keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppColors.spaceMD),
              AppTextField(
                controller: _passwordController,
                labelText: 'Password',
                inputType: 'password',
              ),
              const SizedBox(height: AppColors.spaceLG),
              AppButton(
                text: 'Login',
                isLoading: _isLoading,
                variant: ButtonVariant.primary,
                onPressed: _isLoading ? null : _login,
              ),
              const SizedBox(height: AppColors.spaceMD),
              GestureDetector(
                onTap: () => context.go('/register'),
                child: Text(
                  "Don't have an account? Sign Up",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.light ? Colors.black : Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
