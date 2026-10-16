import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/core/theme/typography.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';

class FcReportActionButtons extends StatelessWidget {
  final ReportModel report;
  final bool isAssigned;
  final bool hasBeforePhoto;
  final bool hasAfterPhoto;
  final Future<void> Function(String newStatus) onStatusChange;
  final VoidCallback onViewOnMap;

  const FcReportActionButtons({
    super.key,
    required this.report,
    required this.isAssigned,
    required this.hasBeforePhoto,
    required this.hasAfterPhoto,
    required this.onStatusChange,
    required this.onViewOnMap,
  });

  @override
  Widget build(BuildContext context) {
    String label = '';
    String? nextStatus;
    bool enabled = isAssigned;
    bool requiresPhotos = false;

    final currentStatus = report.status.toLowerCase();
    final issueType = report.issueType?.toLowerCase() ?? '';
    final isScouting = issueType == 'scouting' || issueType == 'acknowledge_only';
    
    if (currentStatus == 'unresolved' || currentStatus == 'submitted' || currentStatus == 'pending') {
      label = 'Mark as Acknowledged';
      nextStatus = 'acknowledged';
    } else if (currentStatus == 'acknowledged') {
      label = 'Mark as Responded';
      nextStatus = 'responded';
    } else if (currentStatus == 'responded' || currentStatus == 'in_progress') {
      label = 'Cleanup Completed';
      nextStatus = 'resolved';
      requiresPhotos = !isScouting;
    } else if (currentStatus == 'resolved' || currentStatus == 'waiting_for_feedback') {
      label = 'Waiting for Citizen to Close';
      enabled = false;
    } else if (currentStatus == 'closed') {
      label = 'Report Closed';
      enabled = false;
    } else {
      label = 'Unknown Status';
      enabled = false;
    }

    if (requiresPhotos && (!hasBeforePhoto || !hasAfterPhoto)) {
      enabled = false;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final disabledBg = isDark ? AppColors.surfaceDark : Colors.grey.shade200;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: enabled && nextStatus != null ? () => onStatusChange(nextStatus!) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              foregroundColor: Colors.white,
              disabledBackgroundColor: disabledBg,
              disabledForegroundColor: Colors.grey,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppColors.radiusButton)),
            ),
            child: Text(label, style: AppTypography.button),
          ),
        ),
        if (requiresPhotos && (!hasBeforePhoto || !hasAfterPhoto))
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text('Requires both Before and After photos.', style: AppTypography.caption.copyWith(color: AppColors.error)),
          ),
        const SizedBox(height: AppColors.spaceMD),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onViewOnMap,
            icon: const Icon(Icons.map, color: AppColors.primaryDark),
            label: const Text('View on Map', style: AppTypography.button),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryDark,
              side: const BorderSide(color: AppColors.primaryDark),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppColors.radiusButton)),
            ),
          ),
        ),
      ],
    );
  }
}
