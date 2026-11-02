import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import '../controllers/fc_dashboard_presentation.dart';

/// Supporting facts about the report, collapsed by default: type, severity,
/// validation, reporter, coordinates and dates. The same disclosure pattern as
/// the citizen Report details.
class FcReportInfoSection extends StatelessWidget {
  const FcReportInfoSection({super.key, required this.report});
  final ReportModel report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = <(String, String)>[
      ('Issue type', crewTaskLabel(report.issueType ?? 'General concern')),
      ('Severity', crewTaskLabel(report.severityLevel ?? 'Not rated')),
      ('Validation', crewTaskLabel(report.validationStatus)),
      ('Reporter', report.userFullName ?? 'Anonymous citizen'),
      (
        'Coordinates',
        '${report.location.latitude.toStringAsFixed(5)}, ${report.location.longitude.toStringAsFixed(5)}',
      ),
      (
        'Submitted',
        DateFormat.yMMMd().add_jm().format(report.createdAt.toLocal()),
      ),
      (
        'Last updated',
        DateFormat.yMMMd().add_jm().format(report.updatedAt.toLocal()),
      ),
    ];
    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        side: BorderSide(color: theme.dividerTheme.color ?? theme.dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          minTileHeight: 64,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          leading: const Icon(Icons.info_outline, size: 28),
          title: Text(
            'Report information',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            'Type, severity, reporter, dates',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          children: [
            for (final (label, value) in rows)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SelectableText(value, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
