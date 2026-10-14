import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import '../report_status_presentation.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = reportStatusColor(context, status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppColors.spaceSM,
        vertical: AppColors.spaceXS,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.all(
          Radius.circular(AppColors.radiusChip),
        ),
      ),
      child: Text(
        // Use human-readable labels from the canonical map where available.
        reportStatusLabel(status),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
