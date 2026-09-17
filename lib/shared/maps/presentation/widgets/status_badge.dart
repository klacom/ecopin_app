import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String displayText;
    switch (status.toLowerCase()) {
      case 'resolved':
      case 'closed':
        color = AppColors.success;
        displayText = status == 'resolved' ? 'Resolved' : 'Closed';
        break;
      case 'in progress':
      case 'in_progress':
      case 'acknowledged':
      case 'waiting_for_feedback':
        color = AppColors.warning;
        displayText = {
          'in progress': 'In Progress',
          'in_progress': 'In Progress',
          'acknowledged': 'Acknowledged',
          'waiting_for_feedback': 'Waiting for Feedback'
        }[status.toLowerCase()]!;
        break;
      case 'pending_owner_consent':
        color = AppColors.warning;
        displayText = 'Pending Owner Consent';
        break;
      default:
        color = AppColors.error;
        displayText = status.toUpperCase();
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppColors.spaceSM + 4,
        vertical: AppColors.spaceXS + 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppColors.radiusChip),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}