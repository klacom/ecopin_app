import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';

class ValidationBadge extends StatelessWidget {
  final String status;

  const ValidationBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status.toLowerCase()) {
      case 'validated':
      case 'approved':
        color = AppColors.success;
        label = 'AI OK';
        break;
      case 'manual_review':
        color = AppColors.warning;
        label = 'REVIEW';
        break;
      case 'rejected':
        color = AppColors.error;
        label = 'INVALID';
        break;
      default:
        color = Colors.grey;
        label = 'PENDING';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppColors.spaceSM, vertical: AppColors.spaceXS),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.all(Radius.circular(AppColors.radiusChip)),
        border: Border.all(color: color, width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
