import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import 'package:ecopin_app/shared/reports/presentation/widgets/reports_screen_widgets/status_badge.dart';
import 'package:ecopin_app/shared/widgets/app_button.dart';
import '../controllers/fc_report_detail_presentation.dart';
import 'fc_offline_ui.dart';
import 'fc_task_deadline_indicator.dart';

/// Identity of the report: canonical status badge, full title, where it is,
/// what the citizen said, the response deadline, and a map shortcut. The job
/// it belongs to is one tappable row, not a banner.
class FcReportHeaderCard extends StatelessWidget {
  const FcReportHeaderCard({
    super.key,
    required this.report,
    required this.onShowOnMap,
    this.jobTitle,
    this.onOpenJob,
  });
  final ReportModel report;
  final VoidCallback onShowOnMap;
  final String? jobTitle;
  final VoidCallback? onOpenJob;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final place = crewReportPlace(report);
    final description = report.description?.trim();
    final landmark = report.citizenLandmark?.trim();
    return FcOfflineCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: StatusBadge(status: report.status),
          ),
          const SizedBox(height: 12),
          Semantics(
            header: true,
            child: Text(report.title, style: theme.textTheme.titleLarge),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ExcludeSemantics(
                child: Icon(Icons.location_on_outlined, size: 24),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(place.primary, style: theme.textTheme.bodyMedium),
                    if (place.detail != null)
                      Text(
                        place.detail!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description == null || description.isEmpty
                ? 'No description was provided.'
                : description,
            style: theme.textTheme.bodyMedium,
          ),
          if (landmark != null && landmark.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Citizen-provided landmark (extra directions)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(landmark, style: theme.textTheme.bodyMedium),
          ],
          FcTaskDeadlineIndicator(inline: true, reports: [report]),
          const SizedBox(height: 16),
          AppButton(
            text: 'Show on map',
            icon: Icons.map_outlined,
            variant: ButtonVariant.secondary,
            height: 48,
            onPressed: onShowOnMap,
          ),
          if (jobTitle != null && onOpenJob != null) ...[
            const SizedBox(height: 4),
            InkWell(
              borderRadius: BorderRadius.circular(AppColors.radiusInput),
              onTap: onOpenJob,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Row(
                  children: [
                    const ExcludeSemantics(child: Icon(Icons.link, size: 20)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Part of job: $jobTitle',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const ExcludeSemantics(child: Icon(Icons.chevron_right)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
