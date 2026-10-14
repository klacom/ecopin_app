import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/core/theme/app_theme.dart';

class ValidationBadge extends StatelessWidget {
  final String status;

  const ValidationBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final statusColors = Theme.of(context).extension<AppStatusColors>()!;
    Color color;
    String label;

    switch (status.toLowerCase()) {
      case 'validated':
      case 'approved':
        color = statusColors.success;
        label = 'Approved';
        break;
      case 'manual_review':
        color = statusColors.warning;
        label = 'Needs review';
        break;
      case 'rejected':
        color = statusColors.error;
        label = 'Rejected';
        break;
      case 'pending_ai_validation':
        color = Theme.of(context).colorScheme.onSurface;
        label = 'Awaiting automated review';
        break;
      default:
        color = Theme.of(context).colorScheme.onSurface;
        label = status.isEmpty ? 'Pending review' : status.replaceAll('_', ' ');
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppColors.spaceSM, vertical: AppColors.spaceXS),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.all(Radius.circular(AppColors.radiusChip)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
