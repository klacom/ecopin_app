import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/shared/widgets/app_dialog.dart';
import 'package:flutter/material.dart';

class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key});

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  String _confirmation = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final danger =
        theme.extension<AppStatusColors>()?.error ?? theme.colorScheme.error;
    return AppDialog(
      centered: true,
      stackActions: true,
      icon: Icons.delete_forever_rounded,
      iconColor: danger,
      title: 'Delete account?',
      message:
          'This is permanent and cannot be undone. Your sign-in credentials, '
          'profile and notifications will be deleted. Your reports will remain '
          'anonymized for city waste tracking.\n\n'
          'You will be logged out before deletion. If deletion fails, sign in again to retry.',
      actions: [
        FilledButton(
          onPressed: _confirmation == 'I confirm'
              ? () => Navigator.of(context).pop(true)
              : null,
          style: FilledButton.styleFrom(
            backgroundColor: danger,
            foregroundColor: Colors.white,
          ),
          child: const Text('Delete account', textAlign: TextAlign.center),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Keep my account', textAlign: TextAlign.center),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Type exactly “I confirm” to continue.'),
          const SizedBox(height: 8),
          TextField(
            onChanged: (value) => setState(() => _confirmation = value),
            autocorrect: false,
            enableSuggestions: false,
            decoration: const InputDecoration(
              labelText: 'Confirmation',
              hintText: 'I confirm',
            ),
          ),
        ],
      ),
    );
  }
}
