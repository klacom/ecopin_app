import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/core/theme/typography.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_task_status_badge.dart';
import 'package:intl/intl.dart';

class FcReportListTile extends StatelessWidget {
  final ReportModel report;
  final VoidCallback onTap;

  const FcReportListTile({super.key, required this.report, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final validationColor = _getValidationColor(report.validationStatus);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppColors.radiusCard),
      child: Container(
        padding: const EdgeInsets.all(AppColors.spaceLG),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(AppColors.radiusCard),
          border: Border.all(color: AppColors.dividerDark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    report.title,
                    style: AppTypography.h5.copyWith(color: AppColors.textPrimaryDark),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppColors.spaceSM),
                FcTaskStatusBadge(status: report.status),
              ],
            ),
            const SizedBox(height: AppColors.spaceMD),
            Row(
              children: [
                _buildBadge(report.issueType?.toUpperCase() ?? 'GENERAL', AppColors.primaryDark),
                const SizedBox(width: AppColors.spaceSM),
                _buildBadge(report.validationStatus.toUpperCase().replaceAll('_', ' '), validationColor),
              ],
            ),
            const SizedBox(height: AppColors.spaceMD),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Created: ${DateFormat.yMMMd().format(report.createdAt)}',
                  style: AppTypography.caption.copyWith(color: Colors.grey),
                ),
                Row(
                  children: [
                    const Icon(Icons.flag, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      report.status.replaceAll('_', ' '),
                      style: AppTypography.caption.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: AppTypography.caption.copyWith(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getValidationColor(String status) {
    switch (status.toLowerCase()) {
      case 'validated':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }
}
