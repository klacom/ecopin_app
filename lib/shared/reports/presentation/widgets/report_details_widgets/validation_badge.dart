import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';

class ValidationBadge extends StatelessWidget {
  final String status;

  const ValidationBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'pending_ai_validation':
      case 'pending':
        color = AppColors.info;
        label = 'PENDING AI';
        icon = Icons.hourglass_empty;
        break;
      case 'approved':
        color = AppColors.success;
        label = 'APPROVED';
        icon = Icons.verified;
        break;
      case 'manual_review':
        color = AppColors.warning;
        label = 'MANUAL REVIEW';
        icon = Icons.rate_review;
        break;
      case 'rejected':
        color = AppColors.error;
        label = 'REJECTED';
        icon = Icons.error_outline;
        break;
      case 'archived':
        color = Colors.grey;
        label = 'ARCHIVED';
        icon = Icons.archive;
        break;
      default:
        color = Colors.grey;
        label = 'UNKNOWN';
        icon = Icons.help_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppColors.spaceMD, vertical: AppColors.spaceSM),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.all(Radius.circular(AppColors.radiusChip)),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: AppColors.spaceXS),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
