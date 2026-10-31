import 'package:dio/dio.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/core/utils/password_policy.dart';
import 'package:ecopin_app/shared/widgets/app_button.dart';
import 'package:ecopin_app/shared/widgets/app_text_field.dart';
import 'package:ecopin_app/shared/widgets/password_strength_meter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/auth_page_body.dart';

/// Remains outside the authenticated router until the required update succeeds.
/// The pending access token is used only here, never persisted as a session.
class RequiredPasswordChangeScreen extends ConsumerStatefulWidget {
  const RequiredPasswordChangeScreen({super.key, required this.accessToken});
  final String accessToken;
  @override
  ConsumerState<RequiredPasswordChangeScreen> createState() =>
      _RequiredPasswordChangeScreenState();
}

class _RequiredPasswordChangeScreenState
    extends ConsumerState<RequiredPasswordChangeScreen> {
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  final _scrollError = GlobalKey();
  PasswordPolicy? _policy;
  bool _loadingPolicy = true, _saving = false, _expired = false;
  String? _error, _passwordError, _confirmError;

  @override
  void initState() {
    super.initState();
    _password.addListener(_passwordChanged);
    _loadPolicy();
  }

  void _passwordChanged() => setState(() {});
  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _loadPolicy() async {
    setState(() {
      _loadingPolicy = true;
      _error = null;
    });
    try {
      final response = await ref
          .read(apiClientProvider)
          .getPasswordRequirements();
      if (response.data is! Map) {
        throw const FormatException('Policy unavailable');
      }
      final policy = PasswordPolicy(Map<String, dynamic>.from(response.data));
      if (mounted) setState(() => _policy = policy);
    } catch (_) {
      if (mounted) setState(() => _policy = null);
    } finally {
      if (mounted) setState(() => _loadingPolicy = false);
    }
  }

  Future<void> _submit() async {
    if (_saving || _loadingPolicy || _policy == null || _expired) return;
    setState(() {
      _error = null;
      _passwordError = _policy!.validate(_password.text);
      _confirmError = _password.text != _confirmation.text
          ? 'Passwords do not match.'
          : null;
    });
    if (_passwordError != null || _confirmError != null) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _saving = true);
    try {
      await ref
          .read(apiClientProvider)
          .forceChangePassword(
            newPassword: _password.text,
            accessToken: widget.accessToken,
          );
      if (mounted) {
        // A password change can terminate sessions. Let the normal login flow
        // obtain a fresh session instead of installing the original tokens.
        setState(() => _saving = false);
        Navigator.of(context).pop(true);
      }
    } on DioException catch (error) {
      if (!mounted) return;
      final code = error.response?.statusCode;
      setState(() {
        _expired = code == 401 || code == 403;
        _error = code == 403
            ? 'This account cannot continue. Return to sign in for account recovery.'
            : _expired
            ? 'Your sign-in has expired. Return to sign in and try again.'
            : code == 429
            ? 'Too many attempts. Wait a moment before trying again.'
            : 'We could not update your password. Please try again.';
      });
      _revealError();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'We could not update your password. Please try again.',
        );
        _revealError();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _revealError() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted || _scrollError.currentContext == null) return;
    Scrollable.ensureVisible(
      _scrollError.currentContext!,
      alignment: .5,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 200),
    );
  });

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back to sign in',
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: AuthPageBody(
        title: 'Set a new password',
        description:
            'Your account requires a password update before you can continue. Choose your own password, then sign in again.',
        children: [
          AppTextField(
            controller: _password,
            labelText: 'New password',
            inputType: 'password',
            autofillHints: const [AutofillHints.newPassword],
            isLoading: _saving || _expired,
            errorText: _passwordError,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _confirmation,
            labelText: 'Confirm new password',
            inputType: 'password',
            autofillHints: const [AutofillHints.newPassword],
            isLoading: _saving || _expired,
            errorText: _confirmError,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          if (_loadingPolicy)
            Semantics(
              liveRegion: true,
              child: const Text('Loading password rules…'),
            )
          else if (_policy != null)
            PasswordStrengthMeter(
              password: _password.text,
              requirements: _policy!.settings,
            )
          else ...[
            Semantics(
              liveRegion: true,
              child: const Text(
                'Password rules are unavailable. Reload them before continuing.',
              ),
            ),
            const SizedBox(height: 16),
            AppButton(
              text: 'Reload password rules',
              variant: ButtonVariant.secondary,
              onPressed: _loadPolicy,
            ),
          ],
          const SizedBox(height: 24),
          if (_error != null) ...[
            Semantics(
              key: _scrollError,
              liveRegion: true,
              child: Text(
                _error!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          AppButton(
            text: 'Update password',
            isLoading: _saving,
            onPressed: _loadingPolicy || _policy == null || _saving || _expired
                ? null
                : _submit,
          ),
        ],
      ),
    ),
  );
}
