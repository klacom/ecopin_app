import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/shared/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:ecopin_app/shared/widgets/app_text_field.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/auth_page_body.dart';
import 'required_password_change_screen.dart';
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
  String? _error;
  String? _emailError;
  String? _passwordError;
  String? _notice;

  void _showError(String message) {
    if (mounted) setState(() => _error = message);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_isLoading) return;
    setState(() {
      _error = null;
      _notice = null;
      _emailError = _emailController.text.trim().isEmpty
          ? 'Enter your email.'
          : null;
      _passwordError = _passwordController.text.isEmpty
          ? 'Enter your password.'
          : null;
    });
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Please enter email and password');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.login(email, password);

      // The backend returns the Supabase session
      final sessionData = response.data['session'];

      if (response.data['requirePasswordChange'] == true) {
        final accessToken = sessionData is Map
            ? sessionData['access_token']
            : null;
        if (accessToken is! String || accessToken.isEmpty) {
          _showError(
            'We could not start your password update. Please sign in again.',
          );
          return;
        }
        if (!mounted) return;
        final updated = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) =>
                RequiredPasswordChangeScreen(accessToken: accessToken),
          ),
        );
        if (mounted && updated == true) {
          _passwordController.clear();
          setState(
            () => _notice = 'Password updated. Sign in with your new password.',
          );
        }
        return;
      }

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

        if (roleString == 'admin') {
          await Supabase.instance.client.auth.signOut();
          if (mounted) {
            _showError(
              'Administrator access is restricted to the Web Command Center. Please use the web application.',
            );
          }
          return;
        }

        if (roleString != null) {
          if (roleString == 'field_crew') {
            role = UserRole.fieldCrew;
          } else if (roleString == 'lgu' || roleString == 'officer') {
            role = UserRole.officer;
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
          ref
              .read(authNotifierProvider.notifier)
              .manualOverrideAuthenticatedState(role);

          if (role == UserRole.officer) {
            context.go('/officer/dashboard');
          } else if (role == UserRole.fieldCrew) {
            context.go('/field-crew/dashboard');
          } else {
            context.go('/maps');
          }
        }
      } else {
        _showError('Unable to complete sign in. Invalid session received.');
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['code'] == 'EMAIL_NOT_VERIFIED') {
        if (mounted) {
          context.go('/email-verification?email=${Uri.encodeComponent(email)}');
        }
        return;
      }

      String errorMessage = 'Invalid email or password. Please try again.';
      if (data is Map) {
        if (data['message'] != null && data['message'] != 'Login failed') {
          errorMessage = data['message'].toString();
        } else if (data['error'] != null) {
          final err = data['error'].toString();
          if (err.toLowerCase().contains('invalid login credentials') ||
              err.toLowerCase().contains('invalid_grant')) {
            errorMessage = 'Invalid email or password. Please check your credentials and try again.';
          } else {
            errorMessage = err;
          }
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Connection timed out. Please check your network and try again.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'Unable to connect to server. Please check your internet connection.';
      }
      _log.severe(e);
      _showError(errorMessage);
    } catch (e, stackTrace) {
      _log.severe(e, stackTrace);
      _showError('We could not sign you in. Please check your connection and try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        tooltip: 'Back to EcoPin',
        icon: const Icon(Icons.arrow_back),
        onPressed: _isLoading ? null : () => context.go('/landing'),
      ),
    ),
    body: AuthPageBody(
      title: 'Welcome back',
      description: 'Sign in to follow your reports or continue your work.',
      children: [
        AppTextField(
          controller: _emailController,
          labelText: 'Email',
          inputType: 'email',
          isLoading: _isLoading,
          errorText: _emailError,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppColors.spaceMD),
        AppTextField(
          controller: _passwordController,
          labelText: 'Password',
          inputType: 'password',
          isLoading: _isLoading,
          errorText: _passwordError,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _login(),
        ),
        const SizedBox(height: AppColors.spaceLG),
        if (_notice != null) ...[
          Semantics(
            liveRegion: true,
            child: Text(
              _notice!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: AppColors.spaceMD),
        ],
        if (_error != null) ...[
          Semantics(
            liveRegion: true,
            child: Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
          const SizedBox(height: AppColors.spaceMD),
        ],
        AppButton(
          text: 'Sign in',
          isLoading: _isLoading,
          onPressed: _isLoading ? null : _login,
        ),
        const SizedBox(height: AppColors.spaceMD),
        AppButton(
          text: 'Create an account',
          variant: ButtonVariant.link,
          onPressed: _isLoading ? null : () => context.go('/register'),
        ),
      ],
    ),
  );
}
