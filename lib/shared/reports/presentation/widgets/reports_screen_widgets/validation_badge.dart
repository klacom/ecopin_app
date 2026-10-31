import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/core/theme/app_theme.dart';

/// Written review decision and its tone; the single source for the badge and
/// the My Reports rows so the two never disagree.
({String label, Color color}) validationPresentation(
  BuildContext context,
  String status,
) {
  final statusColors = Theme.of(context).extension<AppStatusColors>()!;
  final neutral = Theme.of(context).colorScheme.onSurface;
  return switch (status.toLowerCase()) {
    'validated' ||
    'approved' => (label: 'Approved', color: statusColors.success),
    'manual_review' => (label: 'Needs review', color: statusColors.warning),
    'rejected' => (label: 'Rejected', color: statusColors.error),
    'pending_ai_validation' => (
      label: 'Awaiting automated review',
      color: neutral,
    ),
    _ => (
      label: status.isEmpty ? 'Pending review' : status.replaceAll('_', ' '),
      color: neutral,
    ),
  };
}

class ValidationBadge extends StatelessWidget {
  final String status;

  const ValidationBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (:label, :color) = validationPresentation(context, status);
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
