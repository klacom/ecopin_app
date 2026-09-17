import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/shared/widgets/app_button.dart';
import 'package:ecopin_app/shared/widgets/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:ecopin_app/shared/widgets/app_text_field.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/shared/widgets/password_strength_meter.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final Logger _log = Logger("Register Screen");
  bool _isLoading = false;
  Map<String, dynamic>? _requirements;

  @override
  void initState() {
    super.initState();
    _fetchRequirements();
    _passwordController.addListener(() => setState(() {})); // Rebuild on typing
  }

  Future<void> _fetchRequirements() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.getPasswordRequirements();
      if (mounted) {
        setState(() {
          _requirements = response.data;
        });
      }
    } catch (e) {
      _log.warning('Failed to fetch password requirements: $e');
    }
  }

  bool _isPasswordValid() {
    if (_requirements == null) return _passwordController.text.length >= 6;
    final pwd = _passwordController.text;
    final minLength = _requirements!['password_min_length'] ?? 8;
    if (pwd.length < minLength) return false;
    if (_requirements!['password_require_uppercase'] == true && !RegExp(r'[A-Z]').hasMatch(pwd)) return false;
    if (_requirements!['password_require_lowercase'] == true && !RegExp(r'[a-z]').hasMatch(pwd)) return false;
    if (_requirements!['password_require_numbers'] == true && !RegExp(r'\d').hasMatch(pwd)) return false;
    if (_requirements!['password_require_special_chars'] == true && !RegExp(r'[!@#\$%\^&\*\(\),\.\?":\{\}\|<>]').hasMatch(pwd)) return false;
    return true;
  }

  void signUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

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
    if (!_isPasswordValid()) {
      SnackbarHelper.showError('Please meet all password requirements');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.register(
        email,
        password,
        confirmPassword,
      );

      if (mounted) {
        SnackbarHelper.showMessage('Registration successful! Please verify your email first.');
        context.go('/email-verification?email=${Uri.encodeComponent(email)}');
      }
    } on DioException catch (e, stackTrace) {
      String errorMessage = 'Registration failed';

      _log.severe(e, stackTrace);

      if (e.response?.data != null && e.response?.data['message'] != null) {
        errorMessage = e.response?.data['message'];
      } else if (e.response?.data != null &&
          e.response?.data['errors'] != null) {
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
        padding: const EdgeInsets.all(AppColors.spaceMD),
        child: Column(
          children: [
            AppTextField(controller: _emailController, labelText: 'Email'),
            const SizedBox(height: AppColors.spaceMD),
            AppTextField(
              controller: _passwordController,
              labelText: 'Password',
              inputType: 'password',
            ),
            if (_requirements != null) 
              PasswordStrengthMeter(
                password: _passwordController.text,
                requirements: _requirements,
              ),
            const SizedBox(height: AppColors.spaceMD),
            AppTextField(
              controller: _confirmPasswordController,
              labelText: 'Confirm Password',
              inputType: 'password',
            ),
            const SizedBox(height: AppColors.spaceXXL),
            AppButton(
              text: 'Register',
              isLoading: _isLoading,
              onPressed: _isLoading ? null : signUp,
            ),
            const SizedBox(height: AppColors.spaceMD),
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
