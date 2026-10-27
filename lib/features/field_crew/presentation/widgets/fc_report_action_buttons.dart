import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/core/theme/typography.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';

class FcReportActionButtons extends StatefulWidget {
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
  State<FcReportActionButtons> createState() => _FcReportActionButtonsState();
}

class _FcReportActionButtonsState extends State<FcReportActionButtons> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    String label = '';
    String? nextStatus;
    bool enabled = widget.isAssigned && !_isSubmitting;
    bool requiresPhotos = false;
    String? actionIndicator;

    final status = widget.report.status.toLowerCase();
    final stage = widget.report.lifecycleStage?.toLowerCase();
    final currentStatus =
        {
          'resolved',
          'completed',
          'closed',
          'rejected',
          'waiting_for_feedback',
        }.contains(status)
        ? status
        : status == 'in_progress' ||
              status == 'responded' ||
              stage == 'responded'
        ? 'responded'
        : status == 'acknowledged' || stage == 'acknowledged'
        ? 'acknowledged'
        : status;
    final issueType = widget.report.issueType?.toLowerCase() ?? '';
    final isScouting =
        issueType == 'scouting' || issueType == 'acknowledge_only';

    if (currentStatus == 'unresolved' ||
        currentStatus == 'submitted' ||
        currentStatus == 'pending') {
      label = 'Mark as Acknowledged';
      nextStatus = 'acknowledged';
      if (widget.hasBeforePhoto) {
        actionIndicator =
            'Before photo uploaded. Press "Mark as Acknowledged" below once you have finished adding Before photos.';
      }
    } else if (currentStatus == 'acknowledged' ||
        currentStatus == 'responded' ||
        currentStatus == 'in_progress') {
      label = 'Mark as Complete';
      nextStatus = 'resolved';
      requiresPhotos = !isScouting;
      if (widget.hasAfterPhoto && (widget.hasBeforePhoto || isScouting)) {
        actionIndicator =
            'After photo uploaded. Press "Mark as Complete" below once you have finished adding all After photos.';
      }
    } else if (currentStatus == 'resolved' ||
        currentStatus == 'completed' ||
        currentStatus == 'waiting_for_feedback') {
      label = 'Waiting for Citizen to Close';
      enabled = false;
    } else if (currentStatus == 'closed') {
      label = 'Report Closed';
      enabled = false;
    } else {
      label = 'Unknown Status';
      enabled = false;
    }

    if (requiresPhotos && (!widget.hasBeforePhoto || !widget.hasAfterPhoto)) {
      enabled = false;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final disabledBg = isDark ? AppColors.surfaceDark : Colors.grey.shade200;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (actionIndicator != null)
          Container(
            margin: const EdgeInsets.only(bottom: AppColors.spaceMD),
            padding: const EdgeInsets.all(AppColors.spaceMD),
            decoration: BoxDecoration(
              color: AppColors.primaryDark.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppColors.radiusCard),
              border: Border.all(
                color: AppColors.primaryDark.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 18,
                  color: AppColors.primaryDark,
                ),
                const SizedBox(width: AppColors.spaceSM),
                Expanded(
                  child: Text(
                    actionIndicator,
                    style: AppTypography.caption.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: enabled && nextStatus != null
                ? () async {
                    setState(() => _isSubmitting = true);
                    try {
                      await widget.onStatusChange(nextStatus!);
                    } finally {
                      if (mounted) {
                        setState(() => _isSubmitting = false);
                      }
                    }
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              foregroundColor: Colors.white,
              disabledBackgroundColor: disabledBg,
              disabledForegroundColor: Colors.grey,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppColors.radiusButton),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(label, style: AppTypography.button),
          ),
        ),
        if (requiresPhotos && (!widget.hasBeforePhoto || !widget.hasAfterPhoto))
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Requires both Before and After photos.',
              style: AppTypography.caption.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
          ),
        const SizedBox(height: AppColors.spaceMD),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: widget.onViewOnMap,
            icon: const Icon(Icons.map, color: AppColors.primaryDark),
            label: const Text('View on Map', style: AppTypography.button),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryDark,
              side: const BorderSide(color: AppColors.primaryDark),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppColors.radiusButton),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
