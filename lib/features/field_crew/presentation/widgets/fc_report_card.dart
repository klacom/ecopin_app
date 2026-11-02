import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import 'package:ecopin_app/shared/reports/presentation/widgets/reports_screen_widgets/status_badge.dart';
import '../controllers/fc_report_detail_presentation.dart';
import '../controllers/fc_reports_presentation.dart';
import '../controllers/fc_task_detail_presentation.dart';
import 'fc_task_deadline_indicator.dart';

/// One report in a list: what it is, where it is, where it stands, and (while
/// it is still to handle) when a response is due. Used by the Reports tab and
/// by the report list inside a job, so the two look the same.
class FcReportCard extends StatelessWidget {
  const FcReportCard({super.key, required this.report, required this.onTap});

  final ReportModel report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final place = crewReportPlace(report);
    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        side: BorderSide(color: theme.dividerTheme.color ?? theme.dividerColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(report.title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ExcludeSemantics(
                          child: Icon(
                            Icons.place_outlined,
                            size: 18,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            place.detail == null
                                ? place.primary
                                : '${place.primary} · ${place.detail}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        StatusBadge(status: report.status),
                        Text(
                          crewReportTypeLabel(report),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    if (!reportIsHandled(report))
                      FcTaskDeadlineIndicator(inline: true, reports: [report]),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const ExcludeSemantics(
                child: Icon(Icons.chevron_right, size: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
