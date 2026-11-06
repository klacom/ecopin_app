import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/app_theme.dart';

String citizenPriorityLabel(String? value) =>
    switch (value?.trim().toLowerCase()) {
      'urgent' => 'Urgent',
      'non_urgent' => 'Non-urgent',
      _ => 'Not specified',
    };

/// Citizen selection is separate from severity, dispatch and SWMO verification.
class ReportPriorityBadge extends StatelessWidget {
  const ReportPriorityBadge({super.key, required this.priority});
  final String? priority;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = citizenPriorityLabel(priority);
    final tone = label == 'Urgent'
        ? theme.extension<AppStatusColors>()?.error ?? theme.colorScheme.error
        : theme.colorScheme.onSurfaceVariant;
    return Tooltip(
      message:
          'Citizen-selected priority. Urgent requests still require SWMO verification.',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: tone.withValues(alpha: .08),
          border: Border.all(color: tone),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'Citizen priority: $label',
          style: theme.textTheme.labelMedium?.copyWith(color: tone),
        ),
      ),
    );
  }
}
