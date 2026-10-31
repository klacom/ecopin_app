import 'package:dio/dio.dart' as dio;
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/core/utils/validators.dart';
import 'package:ecopin_app/shared/widgets/app_dialog.dart';
import 'package:ecopin_app/shared/widgets/app_text_field.dart';
import 'package:ecopin_app/shared/widgets/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Change-password form: live requirement checklist from the shared validator,
/// inline errors, named show/hide actions and in-place progress.
class ChangePasswordDialog extends ConsumerStatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  ConsumerState<ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<ChangePasswordDialog> {
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  String? _newError, _confirmError, _requestError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _new.addListener(() => setState(() => _newError = null));
  }

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final newError = validatePassword(_new.text);
    final confirmError = newError == null
        ? validateConfirmPassword(_new.text, _confirm.text)
        : null;
    setState(() {
      _newError = newError;
      _confirmError = confirmError;
      _requestError = null;
    });
    if (newError != null || confirmError != null) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(apiClientProvider)
          .changePassword(oldPassword: _current.text, newPassword: _new.text);
      if (!mounted) return;
      SnackbarHelper.showValidMessage('Password changed.');
      Navigator.pop(context);
    } on dio.DioException catch (e) {
      final data = e.response?.data;
      final message = data is Map && data['message'] is String
          ? data['message'] as String
          : null;
      if (mounted) {
        setState(
          () => _requestError =
              message ?? 'Could not change your password. Try again.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _requestError = 'Could not change your password. Try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppStatusColors>();
    final ok = colors?.success ?? theme.colorScheme.primary;
    return AppDialog(
      title: 'Change password',
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                    semanticsLabel: 'Saving your password',
                  ),
                )
              : const Text('Save'),
        ),
      ],
      child: AutofillGroup(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: _current,
              labelText: 'Current password',
              inputType: 'password',
              isLoading: _saving,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.password],
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _new,
              labelText: 'New password',
              inputType: 'password',
              isLoading: _saving,
              errorText: _newError,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final rule in passwordRequirements(_new.text))
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            rule.met ? Icons.check : Icons.circle_outlined,
                            size: 16,
                            color: rule.met
                                ? ok
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              rule.met ? '${rule.label}, met' : rule.label,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: rule.met
                                    ? ok
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _confirm,
              labelText: 'Confirm new password',
              inputType: 'password',
              isLoading: _saving,
              errorText: _confirmError,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              onSubmitted: (_) => _save(),
            ),
            if (_requestError != null)
              Semantics(
                liveRegion: true,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _requestError!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors?.error ?? theme.colorScheme.error,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
