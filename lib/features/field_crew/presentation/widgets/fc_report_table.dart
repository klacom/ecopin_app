import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/core/theme/typography.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import 'package:go_router/go_router.dart';

class FcReportTable extends StatelessWidget {
  final List<ReportModel> reports;
  final String taskId;
  final void Function(ReportModel report, String outcome)? onOutcome;

  const FcReportTable({
    super.key,
    required this.reports,
    required this.taskId,
    this.onOutcome,
  });

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) {
      return SliverPadding(
        padding: const EdgeInsets.all(AppColors.spaceLG),
        sliver: SliverToBoxAdapter(
          child: Center(
            child: Text(
              'No reports in this task.',
              style: AppTypography.body.copyWith(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final report = reports[index];
        return Container(
          margin: const EdgeInsets.only(bottom: AppColors.spaceMD),
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
                children: [
                  Expanded(
                    child: Text(
                      report.title,
                      style: AppTypography.h6.copyWith(
                        color: AppColors.textPrimaryDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusBadge(report.status),
                ],
              ),
              const SizedBox(height: AppColors.spaceSM),
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    report.issueType ?? 'General',
                    style: AppTypography.caption.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(width: AppColors.spaceMD),
                  const Icon(Icons.verified, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    report.validationStatus.replaceAll('_', ' '),
                    style: AppTypography.caption.copyWith(color: Colors.grey),
                  ),
                  if (report.breachedAt != null) ...[
                    const SizedBox(width: AppColors.spaceMD),
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 14,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      report.slaBreachDuration == null
                          ? 'SLA breached'
                          : 'SLA breached: ${report.slaBreachDuration}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppColors.spaceMD),
              Text(
                report.description ?? 'No description provided.',
                style: AppTypography.body.copyWith(
                  color: AppColors.textPrimaryDark,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppColors.spaceMD),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    context.push(
                      '/field-crew/tasks/$taskId/reports/${report.id}',
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryDark,
                    side: const BorderSide(color: AppColors.primaryDark),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppColors.radiusButton,
                      ),
                    ),
                  ),
                  child: const Text('View Detail', style: AppTypography.button),
                ),
              ),
              if (onOutcome != null) ...[
                const SizedBox(height: AppColors.spaceSM),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => onOutcome!(report, 'already_resolved'),
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('Already clear on arrival'),
                    ),
                    if (![
                      'resolved',
                      'completed',
                      'closed',
                      'rejected',
                    ].contains(report.status.toLowerCase()))
                      OutlinedButton.icon(
                        onPressed: () => onOutcome!(report, 'cleaned'),
                        icon: const Icon(Icons.cleaning_services_outlined),
                        label: const Text('Cleaned here'),
                      ),
                  ],
                ),
              ],
            ],
          ),
        );
      }, childCount: reports.length),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'resolved':
      case 'closed':
        color = AppColors.success;
        break;
      case 'acknowledged':
      case 'responded':
        color = AppColors.info;
        break;
      default:
        color = AppColors.warning;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppColors.radiusChip),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
