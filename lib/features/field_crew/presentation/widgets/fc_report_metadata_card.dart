import 'package:ecopin_app/shared/reports/presentation/widgets/response_deadline_indicator.dart';
import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/core/theme/typography.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_task_status_badge.dart';
import 'package:intl/intl.dart';

class FcReportMetadataCard extends StatelessWidget {
  final ReportModel report;

  const FcReportMetadataCard({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? Colors.white10 : Colors.grey.shade100;
    final textColor = isDark ? AppColors.textPrimaryDark : Colors.black87;
    final dividerColor = isDark ? Colors.white10 : Colors.grey.shade200;

    return Container(
      padding: const EdgeInsets.all(AppColors.spaceLG),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  report.title,
                  style: AppTypography.h4.copyWith(color: textColor),
                ),
              ),
              const SizedBox(width: AppColors.spaceSM),
              FcTaskStatusBadge(status: report.status),
            ],
          ),
          const SizedBox(height: AppColors.spaceMD),
          ResponseDeadlineIndicator(report: report, details: true),
          _buildInfoRow('Description', report.description ?? 'N/A', textColor),
          if (report.citizenLandmark?.trim().isNotEmpty == true) ...[
            const SizedBox(height: AppColors.spaceMD),
            _buildInfoRow('Citizen-provided landmark (extra directions)', report.citizenLandmark!, textColor),
          ],
          Divider(color: dividerColor, height: 24),
          Row(
            children: [
              Expanded(child: _buildInfoRow('Issue Type', report.issueType ?? 'General', textColor)),
              Expanded(child: _buildInfoRow('Severity', report.severityLevel ?? 'Unrated', textColor)),
            ],
          ),
          const SizedBox(height: AppColors.spaceMD),
          Row(
            children: [
              Expanded(child: _buildInfoRow('Validation', report.validationStatus.replaceAll('_', ' '), textColor)),
              Expanded(child: _buildInfoRow('Reporter', report.userFullName ?? 'Anonymous Citizen', textColor)),
            ],
          ),
          Divider(color: dividerColor, height: 24),
          _buildInfoRow('Coordinates', '${report.location.latitude.toStringAsFixed(5)}, ${report.location.longitude.toStringAsFixed(5)}', textColor),
          const SizedBox(height: AppColors.spaceMD),
          Row(
            children: [
              Expanded(child: _buildInfoRow('Submitted', DateFormat.yMMMd().add_jm().format(report.createdAt), textColor)),
              Expanded(child: _buildInfoRow('Updated', DateFormat.yMMMd().add_jm().format(report.updatedAt), textColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.label.copyWith(color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.body.copyWith(color: textColor),
        ),
      ],
    );
  }
}
