import 'package:flutter/material.dart';

/// A report-level override; it never changes the account's disclosure consent.
class ReportIdentityToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  const ReportIdentityToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => SwitchListTile.adaptive(
    contentPadding: const EdgeInsets.symmetric(vertical: 8),
    title: const Text('Hide my identity'),
    subtitle: Text(
      value
          ? 'Hide your name and account details from other users, including officers and admins. Your report text and photos remain visible—avoid including personal details.'
          : 'Use your account’s name-disclosure preference for this report. Turn on to hide your identity for this report only.',
    ),
    value: value,
    onChanged: onChanged,
  );
}
