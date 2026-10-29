import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/core/database/app_database.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ecopin_app/shared/reports/providers/citizen_trust_provider.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(databaseProvider);
  final api = ref.watch(apiClientProvider);
  return SyncService(
    db,
    api,
    onUrgentLocked: () => ref.invalidate(citizenTrustProvider),
  );
});

class SyncService {
  final AppDatabase _db;
  final ApiClient _api;
  final void Function()? onUrgentLocked;

  SyncService(this._db, this._api, {this.onUrgentLocked});

  Future<void> syncAll() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      return; // Offline, can't sync
    }

    await syncReports();
    await syncMedia();
    await syncTaskUpdates();
  }

  Future<void> syncReports() async {
    final ownerId = _api.currentUserId;
    if (ownerId == null) return;
    final pendingReports = await _db.getPendingReports(ownerId: ownerId);
    if (pendingReports.isEmpty) return;

    final List<Map<String, dynamic>> payload = pendingReports
        .map(
          (r) => {
            'idempotency_key': r.idempotencyKey,
            'title': r.title,
            'description': r.description,
            'latitude': r.latitude,
            'longitude': r.longitude,
            'on_private_property': r.onPrivateProperty,
            'hide_identity': r.hideIdentity,
            'citizen_landmark': r.citizenLandmark,
            'scale_level': r.scaleLevel,
            'obstruction_level': r.obstructionLevel,
            'citizen_priority': r.citizenPriority,
            'priority_reason': r.priorityReason,
            'priority_explanation': r.priorityExplanation,
            'created_at': r.createdAt.toUtc().toIso8601String(),
          },
        )
        .toList();

    for (var report in pendingReports) {
      await _db.markReportSyncing(report.id);
    }

    try {
      final response = await _api.batchSyncReports(
        payload,
        expectedUserId: ownerId,
      );
      final results = response.data['results'] as List<dynamic>;

      for (var result in results) {
        final idempotencyKey = result['idempotency_key'];
        final rId = result['result'];

        final reportRecord = pendingReports.firstWhere(
          (r) => r.idempotencyKey == idempotencyKey,
        );

        if (rId == 'created' || rId == 'duplicate') {
          // Successfully synced (or already synced), now we can delete from local DB
          await _db.deleteReport(reportRecord.id);

          // If we have media, we should queue it for upload against the new report_id
          // But for now, we just drop it (media queue is part of next phase)
        } else {
          // Error from server
          final locked = result['error_code'] == 'URGENT_TRUST_LOCKED';
          await _db.markReportFailed(
            reportRecord.id,
            '${locked ? 'URGENT_TRUST_LOCKED: ' : ''}${result['error_message'] ?? 'Unknown server error'}',
          );
          if (locked) onUrgentLocked?.call();
        }
      }
    } catch (e) {
      // Network error, mark all back to pending to retry later
      for (var report in pendingReports) {
        if (_api.currentUserId != ownerId) {
          await _db.markReportPending(report.id);
        } else {
          await _db.markReportFailed(report.id, e.toString());
        }
      }
    }
  }

  Future<void> syncMedia() async {
    final ownerId = _api.currentUserId;
    if (ownerId == null) return;
    final pendingMedia = await _db.getPendingMedia(ownerId: ownerId);
    if (pendingMedia.isEmpty) return;

    for (var media in pendingMedia) {
      // Only sync media if the corresponding report is NO LONGER pending
      // (This implies the text/metadata synced successfully because we delete it from OfflineReports upon success).
      final isReportStillPending = await _db.hasOfflineReport(
        media.idempotencyKey,
        ownerId,
      );

      if (isReportStillPending) {
        continue; // Wait for the text to sync first
      }

      await _db.markMediaSyncing(media.id);

      try {
        final imagePaths = media.imagePaths
            ?.split(',')
            .where((p) => p.isNotEmpty)
            .toList();

        await _api.syncReportMedia(
          media.idempotencyKey,
          imagePaths,
          media.videoPath,
          expectedUserId: ownerId,
        );

        // Upload successful, we can delete the media entry
        await _db.deleteMedia(media.id);
      } catch (e) {
        if (_api.currentUserId != ownerId) {
          await _db.markMediaPending(media.id);
        } else {
          await _db.markMediaFailed(media.id, e.toString());
        }
      }
    }
  }

  Future<void> syncTaskUpdates() async {
    final pendingUpdates = await _db.getPendingTaskUpdates();
    if (pendingUpdates.isEmpty) return;

    final List<Map<String, dynamic>> payload = pendingUpdates
        .map(
          (t) => {
            'task_id': t.taskId,
            'client_known_updated_at': t.clientKnownUpdatedAt.toIso8601String(),
            'payload': jsonDecode(t.payloadJson),
          },
        )
        .toList();

    for (var update in pendingUpdates) {
      await _db.markTaskUpdateSyncing(update.id);
    }

    try {
      final response = await _api.batchSyncTaskUpdates(payload);
      final results = response.data['results'] as List<dynamic>;

      for (var i = 0; i < pendingUpdates.length; i++) {
        final updateRecord = pendingUpdates[i];
        final result = results.firstWhere(
          (r) => r['task_id'] == updateRecord.taskId,
          orElse: () => null,
        );

        if (result != null) {
          final status = result['status'];
          if (status == 'success' || status == 'conflict') {
            // Either it succeeded, or it's escalated to a conflict queue on the server.
            // In either case, the local client has successfully submitted it.
            await _db.deleteTaskUpdate(updateRecord.id);
          } else {
            // Error
            await _db.markTaskUpdateFailed(
              updateRecord.id,
              result['error_message'] ?? 'Unknown error',
            );
          }
        }
      }
    } catch (e) {
      for (var update in pendingUpdates) {
        await _db.markTaskUpdateFailed(update.id, e.toString());
      }
    }
  }
}
