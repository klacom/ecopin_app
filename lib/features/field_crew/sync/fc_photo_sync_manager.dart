import 'dart:io';

import 'package:dio/dio.dart';
import 'package:ecopin_app/core/constants/api_constants.dart';
import 'package:ecopin_app/core/database/app_database.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/features/field_crew/data/repositories/fc_local_photo_repository.dart';
import 'package:ecopin_app/features/field_crew/data/repositories/fc_local_repository.dart';
import 'package:logging/logging.dart';

/// Result of one photo sync run.
class FcPhotoSyncRunResult {
  final int uploadAttempted;
  final int uploadSucceeded;
  final int uploadFailed;
  final int deleteAttempted;
  final int deleteSucceeded;
  final int deleteFailed;

  const FcPhotoSyncRunResult({
    required this.uploadAttempted,
    required this.uploadSucceeded,
    required this.uploadFailed,
    required this.deleteAttempted,
    required this.deleteSucceeded,
    required this.deleteFailed,
  });

  bool get allSucceeded =>
      uploadFailed == 0 && deleteFailed == 0;

  @override
  String toString() =>
      'FcPhotoSyncRunResult('
      'uploads: $uploadSucceeded/$uploadAttempted, '
      'deletes: $deleteSucceeded/$deleteAttempted)';
}

/// [FcPhotoSyncManager] drains the [FcLocalPhotos] table in two passes:
///
/// Pass 1 — Uploads
///   Queries all rows with `syncStatus = pending | failed` (up to [_kMaxRetries]).
///   For each row:
///     1. Marks the row `inFlight`.
///     2. Opens the local file.
///     3. Posts a multipart request to the appropriate photo endpoint.
///     4. On success: marks the row `synced`, stores `remoteUrl`/`remoteId`,
///        and patches the entity cache so the UI sees the Cloudinary/Supabase URL.
///     5. On network failure: marks the row `failed`; it will be retried next run.
///     6. On a permanent error (4xx not 401/429): marks `failed` with
///        `retryCount = max` to prevent infinite retries.
///
/// Pass 2 — Deletions
///   Queries all rows with `syncStatus = pendingDelete`.
///   For each row:
///     1. Issues a DELETE to the server.
///     2. On success: calls [FcLocalPhotoRepository.purgePhoto] to remove the
///        local file and DB row.
///     3. On network failure: leaves the row as `pendingDelete` for next run.
///
/// Dependency ordering
/// ───────────────────
/// Uploads and deletions are intentionally run AFTER [FcSyncManager.sync]
/// completes, so report/task mutations reach the server before we attempt to
/// associate a photo with a potentially-not-yet-created entity.
class FcPhotoSyncManager {
  final ApiClient _api;
  final FcLocalPhotoRepository _photoRepo;
  final FcLocalRepository _local;
  final _log = Logger('FcPhotoSyncManager');

  /// After this many retries a photo is permanently failed.
  static const int _kMaxRetries = 5;

  FcPhotoSyncManager(this._api, this._photoRepo, this._local);

  // ── Public interface ───────────────────────────────────────────────────────

  /// Crash recovery — resets any photos stuck in `inFlight` back to `pending`.
  /// Must be called once at app startup.
  Future<void> recoverInFlight() => _photoRepo.recoverInFlightPhotos();

  /// Resets the retry count for all failed photos so they can be attempted again.
  Future<void> resetFailedPhotos() async {
    await _photoRepo.resetFailedPhotoRetries();
    _log.info('Reset retry counts for all failed photos.');
  }

  /// Runs both upload and delete passes.
  Future<FcPhotoSyncRunResult> sync() async {
    int uploadAttempted = 0, uploadSucceeded = 0, uploadFailed = 0;
    int deleteAttempted = 0, deleteSucceeded = 0, deleteFailed = 0;

    // ── Pass 1: Uploads ──────────────────────────────────────────────────────
    final pendingUploads = await _photoRepo.getPendingUploads();
    for (final photo in pendingUploads) {
      if (photo.retryCount >= _kMaxRetries) {
        _log.warning(
          'Skipping ${photo.localPhotoId}: max retries (${photo.retryCount}) exceeded',
        );
        continue;
      }

      uploadAttempted++;
      final success = await _uploadPhoto(photo);
      if (success) {
        uploadSucceeded++;
      } else {
        uploadFailed++;
      }
    }

    // ── Pass 2: Deletions ────────────────────────────────────────────────────
    final pendingDeletes = await _photoRepo.getPendingDeletes();
    for (final photo in pendingDeletes) {
      deleteAttempted++;
      final success = await _deletePhoto(photo);
      if (success) {
        deleteSucceeded++;
      } else {
        deleteFailed++;
      }
    }

    return FcPhotoSyncRunResult(
      uploadAttempted: uploadAttempted,
      uploadSucceeded: uploadSucceeded,
      uploadFailed: uploadFailed,
      deleteAttempted: deleteAttempted,
      deleteSucceeded: deleteSucceeded,
      deleteFailed: deleteFailed,
    );
  }

  // ── Private: upload ────────────────────────────────────────────────────────

  Future<bool> _uploadPhoto(FcLocalPhoto photo) async {
    final file = File(photo.localPath);
    if (!await file.exists()) {
      _log.warning(
        'File not found for ${photo.localPhotoId}: ${photo.localPath} — purging',
      );
      await _photoRepo.purgePhoto(photo.localPhotoId);
      return false;
    }

    await _photoRepo.markInFlight(photo.localPhotoId);

    try {
      final fileName = photo.localPath.split('/').last;
      final reportVersion = photo.entityType == 'report'
          ? (await _local.getCachedReportById(photo.entityId))?.fcVersion
          : null;
      final formData = FormData.fromMap({
        'photo_type': photo.photoType,
        if (reportVersion != null) 'base_version': reportVersion.toString(),
        'image': await MultipartFile.fromFile(
          photo.localPath,
          filename: fileName,
        ),
      });

      final endpoint = photo.entityType == 'report'
          ? ApiConstants.uploadReportPhoto(photo.entityId)
          : ApiConstants.cleanupTaskUploadPhoto(photo.entityId);

      final response = await _api.dioClient.post(
        endpoint,
        data: formData,
        options: Options(
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      // Parse the remote URL and id from the response.
      final remoteUrl = _extractUrl(response.data, photo.entityType, photo.photoType);
      final remoteId = _extractId(response.data);

      await _photoRepo.markSynced(
        photo.localPhotoId,
        remoteUrl: remoteUrl,
        remoteId: remoteId,
      );

      // Retain the server version for the next offline write.
      final record = response.data is Map ? response.data[photo.entityType] : null;
      if (record is Map) {
        if (photo.entityType == 'report') {
          await _local.applyLocalReportPatch(photo.entityId, Map<String, dynamic>.from(record));
        } else {
          await _local.applyLocalTaskPatch(photo.entityId, Map<String, dynamic>.from(record));
        }
      } else if (remoteUrl != null) {
        await _patchEntityCache(photo, remoteUrl);
      }

      // Clean up the outbox photo entry once the photo is synced.
      await _removePhotoOutboxEntry(photo);

      _log.info(
        'Uploaded ${photo.photoType} photo for ${photo.entityType}:${photo.entityId} '
        '→ $remoteUrl',
      );
      return true;
    } on DioException catch (e, st) {
      final isPermanent = _isPermanentError(e);
      final msg = 'HTTP ${e.response?.statusCode}: ${e.message} | Data: ${e.response?.data}';

      if (isPermanent) {
        // Exhaust retry count so this photo is never retried.
        for (int i = photo.retryCount; i < _kMaxRetries; i++) {
          await _photoRepo.markFailed(photo.localPhotoId, 'permanent: $msg');
        }
        _log.warning('Permanent upload failure for ${photo.localPhotoId}: $msg\n$st');
      } else {
        await _photoRepo.markFailed(photo.localPhotoId, msg);
        _log.warning(
          'Transient upload failure for ${photo.localPhotoId} '
          '(retry ${photo.retryCount + 1}/$_kMaxRetries): $msg\n$st',
        );
      }
      return false;
    } catch (e, st) {
      await _photoRepo.markFailed(photo.localPhotoId, e.toString());
      _log.severe('Unexpected upload error for ${photo.localPhotoId}', e, st);
      return false;
    }
  }

  // ── Private: delete ────────────────────────────────────────────────────────

  Future<bool> _deletePhoto(FcLocalPhoto photo) async {
    try {
      final endpoint = photo.entityType == 'report'
          ? ApiConstants.uploadReportPhoto(photo.entityId)
          : ApiConstants.cleanupTaskUploadPhoto(photo.entityId);

      final reportVersion = photo.entityType == 'report'
          ? (await _local.getCachedReportById(photo.entityId))?.fcVersion
          : null;
      final response = await _api.dioClient.delete(
        endpoint,
        data: {'photo_type': photo.photoType, 'base_version': ?reportVersion},
        options: Options(
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      final record = response.data is Map ? response.data[photo.entityType] : null;
      if (record is Map && photo.entityType == 'report') {
        await _local.applyLocalReportPatch(photo.entityId, Map<String, dynamic>.from(record));
      }
      await _photoRepo.purgePhoto(photo.localPhotoId);
      await _removePhotoOutboxEntry(photo);

      _log.info(
        'Deleted ${photo.photoType} photo for ${photo.entityType}:${photo.entityId}',
      );
      return true;
    } on DioException catch (e) {
      // 404 means already deleted server-side — purge locally and succeed.
      if (e.response?.statusCode == 404 ||
          (e.response?.statusCode == 400 &&
              (e.response?.data?.toString() ?? '').contains('No photo'))) {
        await _photoRepo.purgePhoto(photo.localPhotoId);
        await _removePhotoOutboxEntry(photo);
        _log.info(
          'Delete 404/already-gone for ${photo.localPhotoId} — purged locally',
        );
        return true;
      }
      _log.warning(
        'Delete failed for ${photo.localPhotoId}: ${e.message}',
      );
      return false;
    } catch (e) {
      _log.severe('Unexpected delete error for ${photo.localPhotoId}', e);
      return false;
    }
  }

  // ── Private: helpers ───────────────────────────────────────────────────────

  /// Extracts the CDN URL from the server response.
  String? _extractUrl(
    dynamic data,
    String entityType,
    String photoType,
  ) {
    if (data is! Map<String, dynamic>) return null;
    // Report upload: { report: { before_photo_url: '...' } }
    if (entityType == 'report') {
      final record = data['report'] as Map<String, dynamic>?;
      return record?['${photoType}_photo_url'] as String?;
    }
    // Task upload: { task: { before_photo_url: '...' } }
    final record = data['task'] as Map<String, dynamic>?;
    return record?['${photoType}_photo_url'] as String?;
  }

  String? _extractId(dynamic data) {
    if (data is! Map<String, dynamic>) return null;
    return (data['report'] ?? data['task'])?['id'] as String?;
  }

  /// Patches the local entity cache so the UI shows the remote URL without
  /// waiting for a full refresh.
  Future<void> _patchEntityCache(FcLocalPhoto photo, String remoteUrl) async {
    try {
      final patch = {'${photo.photoType}_photo_url': remoteUrl};
      if (photo.entityType == 'report') {
        await _local.applyLocalReportPatch(photo.entityId, patch);
      } else {
        await _local.applyLocalTaskPatch(photo.entityId, patch);
      }
    } catch (e) {
      _log.warning('_patchEntityCache failed for ${photo.entityId}: $e');
    }
  }

  /// Removes the corresponding outbox entry for this photo operation after
  /// the upload or deletion has been confirmed on the server.
  Future<void> _removePhotoOutboxEntry(FcLocalPhoto photo) async {
    try {
      final opType = photo.syncStatus == FcLocalPhotoSyncStatus.pendingDelete
          ? FcOutboxOperationType.deletePhoto
          : (photo.photoType == 'before'
              ? FcOutboxOperationType.uploadBeforePhoto
              : FcOutboxOperationType.uploadAfterPhoto);

      final item = await _local.findPendingOutboxItem(opType, photo.entityId);
      if (item != null) {
        await _local.deleteOutboxItem(item.operationId);
      }
    } catch (e) {
      _log.warning('_removePhotoOutboxEntry failed for ${photo.localPhotoId}: $e');
    }
  }

  /// Returns true for 4xx errors that should not be retried (e.g., 400, 403,
  /// 413 — but not 401 or 429 which can resolve themselves).
  bool _isPermanentError(DioException e) {
    final code = e.response?.statusCode;
    if (code == null) return false;
    return code >= 400 && code < 500 && code != 401 && code != 429;
  }
}
