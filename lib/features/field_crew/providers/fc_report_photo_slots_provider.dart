import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_photo_upload_section.dart';
import 'package:ecopin_app/features/field_crew/providers/fc_local_repository_provider.dart';
import 'package:ecopin_app/features/field_crew/providers/fc_report_detail_notifier.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';

/// Before and After photos for one report, merged from the local queue and the
/// server record, with the flags the completion rules use.
class FcReportPhotoSlots {
  const FcReportPhotoSlots({
    this.before = const [],
    this.after = const [],
    this.hasBefore = false,
    this.hasAfter = false,
  });
  final List<FcPhotoSlot> before, after;
  final bool hasBefore, hasAfter;

  /// What the report record alone says, before the local queue has loaded.
  factory FcReportPhotoSlots.fromReport(ReportModel report) =>
      FcReportPhotoSlots(
        hasBefore:
            report.beforePhotos.isNotEmpty ||
            report.beforePhotoUrl?.isNotEmpty == true,
        hasAfter:
            report.afterPhotos.isNotEmpty ||
            report.afterPhotoUrl?.isNotEmpty == true,
      );
}

final fcReportPhotoSlotsProvider = FutureProvider.autoDispose
    .family<FcReportPhotoSlots, String>((ref, reportId) async {
      final report = ref.watch(
        fcReportDetailNotifierProvider(reportId).select((s) => s.report),
      );
      if (report == null) return const FcReportPhotoSlots();
      final photoRepo = ref.watch(fcLocalPhotoRepositoryProvider);
      final rows = await photoRepo.getPhotosForEntity(report.id, 'report');
      final pendingDeletes = await photoRepo.getPendingDeletes();

      List<FcPhotoSlot> build(
        String type,
        List<Map<String, dynamic>> remote,
        String? legacyUrl,
      ) {
        final deleted = pendingDeletes
            .where(
              (p) =>
                  p.entityId == report.id &&
                  p.entityType == 'report' &&
                  p.photoType == type,
            )
            .map((p) => p.remoteId ?? p.localPhotoId)
            .toSet();
        final slots = [
          for (final row in rows.where((p) => p.photoType == type))
            FcPhotoSlot(
              localPhotoId: row.localPhotoId,
              remoteId: row.remoteId,
              localPath: row.localPath,
              remoteUrl: row.remoteUrl,
              syncStatus: row.syncStatus,
            ),
        ];
        final urls = slots.map((p) => p.remoteUrl).toSet();
        for (final photo in remote) {
          final url = photo['url'] as String?;
          if (url != null && !deleted.contains(photo['id']) && urls.add(url)) {
            slots.add(
              FcPhotoSlot(remoteUrl: url, remoteId: photo['id'] as String?),
            );
          }
        }
        if (slots.isEmpty &&
            remote.isEmpty &&
            !deleted.contains('legacy') &&
            legacyUrl?.isNotEmpty == true) {
          slots.add(FcPhotoSlot(remoteUrl: legacyUrl, remoteId: 'legacy'));
        }
        return slots;
      }

      final before = build(
        'before',
        report.beforePhotos,
        report.beforePhotoUrl,
      );
      final after = build('after', report.afterPhotos, report.afterPhotoUrl);
      final fromReport = FcReportPhotoSlots.fromReport(report);
      return FcReportPhotoSlots(
        before: before,
        after: after,
        hasBefore: before.isNotEmpty || fromReport.hasBefore,
        hasAfter: after.isNotEmpty || fromReport.hasAfter,
      );
    });
