import 'package:ecopin_app/core/utils/password_policy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ecopin_app/routes/app_routes.dart';
import 'package:ecopin_app/features/admin/data/admin_repository.dart';
import 'package:ecopin_app/features/admin/presentation/widgets/admin_widgets.dart';
import 'package:ecopin_app/shared/widgets/app_button.dart';
import 'package:ecopin_app/shared/widgets/app_text_field.dart';
import 'package:ecopin_app/shared/widgets/password_strength_meter.dart';

class AdminAccountForm extends ConsumerStatefulWidget {
  const AdminAccountForm({super.key, this.userId, this.accountName});
  final String? userId, accountName;
  @override
  ConsumerState<AdminAccountForm> createState() => _AdminAccountFormState();
}

class _AdminAccountFormState extends ConsumerState<AdminAccountForm> {
  final _name = TextEditingController(),
      _email = TextEditingController(),
      _password = TextEditingController();
  final _scroll = ScrollController();
  String _role = 'citizen';
  String? _error, _nameError, _emailError, _passwordError;
  PasswordPolicy? _policy;
  bool _policyLoading = true, _busy = false, _confirming = false;
  bool _accountRecovery = false;
  bool get _reset => widget.userId != null;
  @override
  void initState() {
    super.initState();
    _password.addListener(_passwordEdited);
    _loadPolicy();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _passwordEdited() {
    if (mounted) {
      setState(() {
        if (_passwordError != null) {
          _passwordError = _policy?.validate(_password.text);
        }
      });
    }
  }

  Future<void> _loadPolicy() async {
    setState(() {
      _policyLoading = true;
      _error = null;
      _accountRecovery = false;
    });
    try {
      final settings = await ref.read(adminRepositoryProvider).getSettings();
      final policy = PasswordPolicy(settings);
      if (mounted) {
        setState(() {
          _policy = policy;
          _policyLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _policyLoading = false;
          _error =
              'Password rules could not be loaded. ${adminErrorMessage(error)}';
          _accountRecovery = adminRequiresAccountRecovery(error);
        });
      }
    }
  }

  Future<void> _submit() async {
    if (_busy || _policy == null || _policyLoading || _accountRecovery) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _nameError = !_reset && _name.text.trim().isEmpty
          ? 'Enter the account holder’s name.'
          : null;
      _emailError =
          !_reset &&
              !RegExp(
                r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
              ).hasMatch(_email.text.trim())
          ? 'Enter a valid email address.'
          : null;
      _passwordError = _policy!.validate(_password.text);
      _error = null;
    });
    if (_nameError != null || _emailError != null || _passwordError != null) {
      await _scroll.animateTo(
        0,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
      return;
    }
    setState(() {
      _busy = true;
      _confirming = true;
    });
    final confirmed = await confirmAdminAction(
      context,
      title: _reset ? 'Reset account password?' : 'Create this account?',
      message: _reset
          ? 'Set a new password for ${widget.accountName ?? 'this account'}? Ask the account holder to sign in using the new password.'
          : '${_name.text.trim()}\n${_email.text.trim()}\nRole: ${adminRoles[_role]}\n\nThe backend will request a password change on the next sign-in.',
      action: _reset ? 'Reset password' : 'Create account',
    );
    if (!mounted) return;
    setState(() => _confirming = false);
    if (!confirmed) {
      setState(() => _busy = false);
      return;
    }
    try {
      final repository = ref.read(adminRepositoryProvider);
      if (_reset) {
        await repository.resetPassword(widget.userId!, _password.text);
      } else {
        await repository.createUser(
          email: _email.text.trim(),
          password: _password.text,
          name: _name.text.trim(),
          role: _role,
        );
      }
      if (mounted) {
        _password.clear();
        setState(() => _busy = false);
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = adminErrorMessage(error);
          _accountRecovery = adminRequiresAccountRecovery(error);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(
        title: Text(_reset ? 'Reset password' : 'Create account'),
        leading: BackButton(
          onPressed: _busy ? null : () => Navigator.of(context).maybePop(),
        ),
        toolbarHeight:
            MediaQuery.textScalerOf(
                  context,
                ).clamp(maxScaleFactor: 1.3).scale(24) *
                2 +
            16,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scroll,
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _reset
                        ? widget.accountName ?? 'Account password'
                        : 'Account details',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _reset
                        ? 'Enter an explicit new password. A password change is requested at the next sign-in.'
                        : 'Choose the correct role and review the account before creating it.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 24),
                  if (!_reset) ...[
                    AppTextField(
                      key: const Key('admin-create-name'),
                      labelText: 'Full name',
                      controller: _name,
                      isLoading: _busy,
                      errorText: _nameError,
                      autofillHints: const [AutofillHints.name],
                    ),
                    const SizedBox(height: 20),
                    AppTextField(
                      key: const Key('admin-create-email'),
                      labelText: 'Email',
                      controller: _email,
                      inputType: 'email',
                      isLoading: _busy,
                      errorText: _emailError,
                    ),
                    const SizedBox(height: 20),
                    AdminSelect(
                      label: 'Account role',
                      value: _role,
                      options: adminRoles,
                      onChanged: _busy
                          ? null
                          : (value) => setState(() => _role = value),
                    ),
                    const SizedBox(height: 24),
                  ],
                  AppTextField(
                    key: const Key('admin-account-password'),
                    labelText: 'New password',
                    inputType: 'password',
                    controller: _password,
                    isLoading: _busy,
                    errorText: _passwordError,
                    autofillHints: const [AutofillHints.newPassword],
                  ),
                  if (_policyLoading) ...[
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(
                      semanticsLabel: 'Loading password rules',
                    ),
                  ] else if (_policy != null)
                    PasswordStrengthMeter(
                      password: _password.text,
                      requirements: _policy!.settings,
                    ),
                  const SizedBox(height: 24),
                  if (_error != null) ...[
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_accountRecovery)
                    AppButton(
                      text: 'Open Account',
                      variant: ButtonVariant.secondary,
                      onPressed: () => context.go(AdminAppRoutes.profile),
                    )
                  else if (!_policyLoading && _policy == null)
                    AppButton(
                      text: 'Retry password rules',
                      variant: ButtonVariant.secondary,
                      onPressed: _loadPolicy,
                    ),
                  AppButton(
                    text: _reset ? 'Review password reset' : 'Review account',
                    isLoading: _busy && !_confirming,
                    onPressed:
                        _busy ||
                            _policyLoading ||
                            _policy == null ||
                            _accountRecovery
                        ? null
                        : _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
