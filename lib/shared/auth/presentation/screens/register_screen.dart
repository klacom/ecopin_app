import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/core/utils/validators.dart';
import 'package:ecopin_app/shared/widgets/app_button.dart';
import 'package:ecopin_app/shared/widgets/snackbar_helper.dart';
import '../widgets/auth_page_body.dart';
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
  String? _error;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;
  bool _requirementsLoading = true;
  bool _requirementsUnavailable = false;

  void _showError(String message) { if (mounted) setState(() => _error = message); }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
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
      _log.warning('Failed to fetch password requirements');
      if (mounted) setState(() => _requirementsUnavailable = true);
    } finally {
      if (mounted) setState(() => _requirementsLoading = false);
    }
  }

  bool _isPasswordValid() {
    if (_requirements == null) return _passwordController.text.length >= 8;
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
    if (_isLoading) return;
    setState(() {
      _error = null;
      _emailError = _emailController.text.trim().isEmpty ? 'Enter your email.' : null;
      _passwordError = _passwordController.text.isEmpty ? 'Enter a password.' : validatePassword(_passwordController.text);
      _confirmError = validateConfirmPassword(_passwordController.text, _confirmPasswordController.text);
    });
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Frontend validation — rules mirror the backend (see core/utils/validators.dart).
    if (email.isEmpty) {
      _showError('Email is required');
      return;
    }
    if (password.isEmpty) {
      _showError('Password is required');
      return;
    }

    final passwordError = validatePassword(password);
    if (passwordError != null) {
      _showError(passwordError);
      return;
    }

    final confirmError = validateConfirmPassword(password, confirmPassword);
    if (confirmError != null) {
      _showError(confirmError);
      return;
    }

    if (!_isPasswordValid()) {
      _showError('Please meet all password requirements');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.register(
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
      _showError(errorMessage);
    } catch (e, stackTrace) {
      _log.severe(e, stackTrace);
      _showError('Your account could not be created. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(leading: IconButton(tooltip: 'Back to EcoPin',
      icon: const Icon(Icons.arrow_back), onPressed: _isLoading ? null : () => context.go('/landing'))),
    body: AuthPageBody(title: 'Create your account', description: 'Report environmental concerns in Pasig and follow their progress.', children: [
      AppTextField(controller: _emailController, labelText: 'Email', inputType: 'email',
        isLoading: _isLoading, errorText: _emailError, textInputAction: TextInputAction.next),
      const SizedBox(height: AppColors.spaceMD),
      AppTextField(controller: _passwordController, labelText: 'Password', inputType: 'password',
        isLoading: _isLoading, errorText: _passwordError, autofillHints: const [AutofillHints.newPassword], textInputAction: TextInputAction.next),
      if (_requirementsLoading) const Padding(padding: EdgeInsets.only(top: 12), child: Text('Checking password requirements…')),
      if (_requirementsUnavailable) const Padding(padding: EdgeInsets.only(top: 12), child: Text('Password requirements could not load. Your password will also be checked when you submit.')),
      if (_requirements != null) PasswordStrengthMeter(password: _passwordController.text, requirements: _requirements),
      const SizedBox(height: AppColors.spaceMD),
      AppTextField(controller: _confirmPasswordController, labelText: 'Confirm password', inputType: 'password',
        isLoading: _isLoading, errorText: _confirmError, autofillHints: const [AutofillHints.newPassword], textInputAction: TextInputAction.done, onSubmitted: (_) => signUp()),
      const SizedBox(height: AppColors.spaceLG),
      if (_error != null) ...[
        Semantics(liveRegion: true, child: Text(_error!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.error))),
        const SizedBox(height: AppColors.spaceMD),
      ],
      AppButton(text: 'Create account', isLoading: _isLoading, onPressed: _isLoading ? null : signUp),
      const SizedBox(height: AppColors.spaceMD),
      AppButton(text: 'Already registered? Sign in', variant: ButtonVariant.link,
        onPressed: _isLoading ? null : () => context.go('/login')),
    ]),
  );
}
