import 'package:dio/dio.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/shared/widgets/app_button.dart';
import 'package:ecopin_app/shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/auth_page_body.dart';

/// Requests a password-reset email. The reset link opens the EcoPin web page where the new password is chosen.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _loading = false;
  bool _sent = false;
  String? _emailError;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    final email = _email.text.trim();
    final valid = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
    setState(() {
      _error = null;
      _emailError = valid ? null : 'Enter a valid email address.';
    });
    if (!valid) return;
    setState(() => _loading = true);
    try {
      await ref.read(apiClientProvider).forgotPassword(email);
      if (mounted) setState(() => _sent = true);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(
        () => _error = e.response?.statusCode == 429
            ? 'Too many requests. Please wait a few minutes and try again.'
            : 'We could not send the reset link. Check your connection and try again.',
      );
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'We could not send the reset link. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        tooltip: 'Back to sign in',
        icon: const Icon(Icons.arrow_back),
        onPressed: _loading ? null : () => Navigator.of(context).maybePop(),
      ),
    ),
    body: AuthPageBody(
      title: 'Reset your password',
      description:
          'Enter your account email. If it matches an account, we will email you a link to choose a new password.',
      children: [
        if (_sent)
          Semantics(
            liveRegion: true,
            child: Text(
              'If an account exists for ${_email.text.trim()}, a reset link is on its way. Open it on this phone, choose a new password in the browser, then return here and sign in. Check your spam folder if you do not see it.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          )
        else ...[
          AppTextField(
            controller: _email,
            labelText: 'Email',
            inputType: 'email',
            isLoading: _loading,
            errorText: _emailError,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: AppColors.spaceLG),
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
            text: 'Send reset link',
            isLoading: _loading,
            onPressed: _loading ? null : _submit,
          ),
        ],
      ],
    ),
  );
}
