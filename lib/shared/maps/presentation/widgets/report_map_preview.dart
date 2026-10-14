import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import 'package:ecopin_app/shared/reports/presentation/widgets/reports_screen_widgets/status_badge.dart';
import 'package:ecopin_app/shared/widgets/app_button.dart';
import 'package:flutter/material.dart';

class ReportMapPreview extends StatelessWidget {
  const ReportMapPreview({super.key, required this.report});
  final ReportModel report;
  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .8,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Public report',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Close report preview',
                  onPressed: () => Navigator.of(context).pop(false),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Semantics(
              header: true,
              child: Text(
                report.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                StatusBadge(status: report.status),
                Text(
                  (report.issueType ?? 'Environmental concern').replaceAll(
                    '_',
                    ' ',
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              report.description?.trim().isNotEmpty == true
                  ? report.description!
                  : 'No description provided.',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              report.locationPrecision == 'approximate'
                  ? 'Approximate location shown on the public map.'
                  : 'Location shown on the public map.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            AppButton(
              text: 'View report',
              icon: Icons.arrow_forward,
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ),
    ),
  );
}
