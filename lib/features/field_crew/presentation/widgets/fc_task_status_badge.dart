import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/app_theme.dart';
import '../controllers/fc_dashboard_presentation.dart';

class FcTaskStatusBadge extends StatelessWidget {
  const FcTaskStatusBadge({super.key, required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context),
        colors = Theme.of(context).extension<AppStatusColors>();
    final color = switch (crewTaskKey(status)) {
      'completed' => colors?.success ?? theme.colorScheme.onSurface,
      'in_progress' => colors?.info ?? theme.colorScheme.onSurface,
      'pending' ||
      'assigned' ||
      'scheduled' ||
      'on_hold' => colors?.warning ?? theme.colorScheme.onSurface,
      _ => theme.colorScheme.onSurface,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        border: Border.all(color: color.withValues(alpha: .35)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        crewTaskLabel(status),
        style: theme.textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
