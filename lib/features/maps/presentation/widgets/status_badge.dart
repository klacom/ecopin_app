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
      case 'acknowledged':
      case 'waiting_for_feedback':
        color = AppColors.warning;
        displayText = {
          'in progress': 'In Progress',
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
      padding: const EdgeInsets.symmetric(horizontal: AppColors.spaceSM, vertical: AppColors.spaceXS),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.all(Radius.circular(AppColors.radiusChip)),
        border: Border.all(color: color),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}