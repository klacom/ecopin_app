import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/core/constants/app_constants.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toLowerCase()) {
      case 'resolved':
        color = AppColors.success;
        break;
      case 'in_progress':
        color = AppColors.warning;
        break;
      case 'waiting_for_feedback':
        color = AppColors.warning;
        break;
      case 'unresolved':
      case 'rejected':
      default:
        color = AppColors.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppColors.spaceSM, vertical: AppColors.spaceXS),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.all(Radius.circular(AppColors.radiusChip)),
      ),
      child: Text(
        // Use human-readable labels from the canonical map where available.
        (reportStatusLabels[status.toLowerCase()] ?? status).toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
