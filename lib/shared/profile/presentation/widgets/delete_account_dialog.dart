import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';

class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key});

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  String _confirmation = '';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      icon: const Icon(Icons.delete_forever_rounded, color: AppColors.error),
      title: const Text('Delete Account?', textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'This is permanent and cannot be undone. Your sign-in credentials, '
            'profile and notifications will be deleted. Your reports will remain '
            'anonymized for city waste tracking.\n\n'
            'You will be logged out before deletion. If deletion fails, sign in again to retry.',
          ),
          const SizedBox(height: 20),
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
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _confirmation == 'I confirm'
                ? () => Navigator.of(context).pop(true)
                : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            child: const Text('Delete account', textAlign: TextAlign.center),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep my account', textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}
