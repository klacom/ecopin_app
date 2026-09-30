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
    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  report.title,
                  style: AppTypography.h4.copyWith(color: AppColors.textPrimaryDark),
                ),
              ),
              const SizedBox(width: AppColors.spaceSM),
              FcTaskStatusBadge(status: report.status),
            ],
          ),
          const SizedBox(height: AppColors.spaceMD),
          _buildInfoRow('Description', report.description ?? 'N/A'),
          const Divider(color: AppColors.dividerDark, height: 24),
          Row(
            children: [
              Expanded(child: _buildInfoRow('Issue Type', report.issueType ?? 'General')),
              Expanded(child: _buildInfoRow('Severity', report.severityLevel ?? 'Unrated')),
            ],
          ),
          const SizedBox(height: AppColors.spaceMD),
          Row(
            children: [
              Expanded(child: _buildInfoRow('Validation', report.validationStatus.replaceAll('_', ' '))),
              Expanded(child: _buildInfoRow('Reporter', report.userFullName ?? 'Anonymous Citizen')),
            ],
          ),
          const Divider(color: AppColors.dividerDark, height: 24),
          _buildInfoRow('Coordinates', '${report.location.latitude.toStringAsFixed(5)}, ${report.location.longitude.toStringAsFixed(5)}'),
          const SizedBox(height: AppColors.spaceMD),
          Row(
            children: [
              Expanded(child: _buildInfoRow('Submitted', DateFormat.yMMMd().add_jm().format(report.createdAt))),
              Expanded(child: _buildInfoRow('Updated', DateFormat.yMMMd().add_jm().format(report.updatedAt))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.label.copyWith(color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.body.copyWith(color: AppColors.textPrimaryDark),
        ),
      ],
    );
  }
}
