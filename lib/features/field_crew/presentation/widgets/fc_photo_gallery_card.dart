import 'package:flutter/material.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import 'package:ecopin_app/shared/widgets/private_media_image.dart';
import 'package:ecopin_app/shared/reports/presentation/widgets/report_details_widgets/fullscreen_image_view.dart';
import '../controllers/fc_task_detail_presentation.dart';
import 'fc_offline_ui.dart';

class FcPhotoGalleryCard extends StatelessWidget {
  const FcPhotoGalleryCard({
    super.key,
    required this.reports,
    this.evidenceByReport = const {},
    this.isLoading = false,
    this.error,
    this.onRetry,
  });
  final List<ReportModel> reports;
  final Map<String, List<dynamic>> evidenceByReport;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) {
    final photos = <(ReportModel, String)>[];
    var videos = 0;
    for (final report in reports) {
      for (final row in evidenceByReport[report.id] ?? []) {
        final url = citizenEvidenceUrl(row);
        if (url == null) continue;
        if (citizenEvidenceIsVideo(row)) {
          videos++;
        } else {
          photos.add((report, url));
        }
      }
    }
    final known = reports.every((r) => evidenceByReport.containsKey(r.id));
    final text = Theme.of(context).textTheme;
    return FcOfflineCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Citizen evidence', style: text.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Submitted with the linked reports. Cleanup photos stay in each report.',
            style: text.bodySmall,
          ),
          if (isLoading) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(
              semanticsLabel: 'Loading citizen evidence',
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(error!, style: text.bodyMedium),
          ],
          if (photos.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '${photos.length} ${photos.length == 1 ? 'photo' : 'photos'}',
              style: text.bodySmall,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 120 + MediaQuery.textScalerOf(context).scale(14) * 3.2,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final (report, url) = photos[index];
                  return SizedBox(
                    width: 148,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Semantics(
                          button: true,
                          label: 'View citizen photo from ${report.title}',
                          child: Material(
                            clipBehavior: Clip.antiAlias,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      FullScreenImageView(imageUrl: url),
                                ),
                              ),
                              child: ExcludeSemantics(
                                child: PrivateMediaImage(
                                  url,
                                  width: 148,
                                  height: 112,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stack) =>
                                      const Center(child: Text('Photo unavailable')),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          report.title,
                          style: text.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ] else if (!isLoading && error == null) ...[
            const SizedBox(height: 16),
            Text(
              known
                  ? (reports.isEmpty
                        ? 'No linked reports to preview.'
                        : 'No citizen photo evidence on these reports.')
                  : 'Citizen evidence has not been loaded yet.',
              style: text.bodyMedium,
            ),
          ],
          if (videos > 0)
            Text(
              '$videos ${videos == 1 ? 'video' : 'videos'} · open the corresponding report to view.',
              style: text.bodySmall,
            ),
          if (onRetry != null && (error != null || (!known && !isLoading)))
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: isLoading ? null : onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry citizen evidence'),
              ),
            ),
        ],
      ),
    );
  }
}
