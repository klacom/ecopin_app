import 'package:ecopin_app/shared/widgets/app_dialog.dart';
import 'package:flutter/material.dart';

/// Asks before signing out; resolves to true only when the person confirms.
Future<bool> confirmLogout(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AppDialog(
      centered: true,
      icon: Icons.logout_rounded,
      title: 'Log out?',
      message: 'You will need to sign in again to see your reports and alerts.',
      actions: [
        OutlinedButton(
          style: OutlinedButton.styleFrom(fixedSize: const Size.fromHeight(48)),
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(fixedSize: const Size.fromHeight(48)),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Log out'),
        ),
      ],
    ),
  );
  return confirmed == true;
}
