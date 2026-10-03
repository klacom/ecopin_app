import 'dart:io';
import 'package:dio/dio.dart';
import 'package:ecopin_app/core/constants/api_constants.dart';
import 'package:ecopin_app/core/database/app_database.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/core/services/cache_service.dart';
import 'package:ecopin_app/features/field_crew/data/models/agency_response_model.dart';
import 'package:ecopin_app/features/field_crew/data/repositories/fc_local_photo_repository.dart';
import 'package:ecopin_app/features/field_crew/data/repositories/fc_local_repository.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide MultipartFile;
import 'package:uuid/uuid.dart';

class FieldCrewReportRepository {
  final ApiClient _apiClient;
  final CacheService _cacheService;
  final FcLocalRepository _local;
  final FcLocalPhotoRepository _localPhoto;
  final Logger log = Logger('FieldCrewReportRepository');
  final _uuid = const Uuid();

  FieldCrewReportRepository(
    this._apiClient,
    this._cacheService,
    this._local,
    this._localPhoto,
  );

  // ── Network helper ──────────────────────────────────────────────────────

  bool _isNetworkError(Object e) {
    if (e is DioException) {
      return e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.unknown;
    }
    return e is SocketException;
  }

  // ── Fetch methods (network → local cache → UI) ─────────────────────────

  Future<List<ReportModel>> fetchReportsByClusterId(String clusterId) async {
    try {
      final response = await _apiClient.dioClient.get(
        '/api/reports/cluster/$clusterId',
      );
      final List<dynamic> data = response.data;
      final reports = data.map((json) => ReportModel.fromJson(json)).toList();
      await _cacheService.cacheReports(reports);
      await _local.saveReports(reports);
      return reports;
    } catch (e) {
      log.severe('Failed to fetch reports by cluster', e);
      final cached = await _local.getCachedReports();
      if (cached.isNotEmpty) return cached;
      return await _cacheService.getCachedReports();
    }
  }

  Future<List<ReportModel>> fetchReportsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    try {
      final response = await _apiClient.dioClient.get(
        ApiConstants.reports,
        queryParameters: {'ids': ids.join(',')},
      );
      final List<dynamic> data = response.data;
      final reports = data.map((json) => ReportModel.fromJson(json)).toList();
      await _cacheService.cacheReports(reports);
      await _local.saveReports(reports);
      return reports;
    } catch (e) {
      log.severe('Failed to fetch reports by ids', e);
      final cached = await _local.getCachedReports();
      if (cached.isNotEmpty) {
        return cached.where((r) => ids.contains(r.id)).toList();
      }
      final legacy = await _cacheService.getCachedReports();
      return legacy.where((r) => ids.contains(r.id)).toList();
    }
  }

  /// Returns a report. Prefers the local Drift cache so locally-modified
  /// data is always visible, then falls back to the network.
  Future<ReportModel> fetchReportById(String id) async {
    // 1. Try local cache first — returns locally-modified state immediately.
    final local = await _local.getCachedReportById(id);
    if (local != null) {
      // Refresh in background — don't await, don't block.
      _refreshReportFromNetwork(id);
      return local;
    }
    // 2. Nothing cached; must go to network.
    try {
      final response =
          await _apiClient.dioClient.get(ApiConstants.getReportById(id));
      final report = ReportModel.fromJson(response.data);
      await _cacheService.cacheReports([report]);
      await _local.saveReports([report]);
      return report;
    } catch (e) {
      log.severe('Failed to fetch report by id $id', e);
      final legacy = await _cacheService.getCachedReportById(id);
      if (legacy != null) return legacy;
      rethrow;
    }
  }

  /// Silently re-fetches a report from the network and updates the local cache.
  /// Only replaces local data if the report is NOT locally modified, so we
  /// don't overwrite optimistic changes with stale server data.
  Future<void> _refreshReportFromNetwork(String id) async {
    try {
      final response =
          await _apiClient.dioClient.get(ApiConstants.getReportById(id));
      final report = ReportModel.fromJson(response.data);
      // Only update if not locally modified.
      final row = await _local.getCachedReportById(id);
      if (row != null) {
        // Check sync state via DB row.
        final dbRow = await _local.getCachedReportDbRow(id);
        if (dbRow != null && dbRow.localSyncState == 0) {
          await _cacheService.cacheReports([report]);
          await _local.saveReports([report]);
        }
      } else {
        await _cacheService.cacheReports([report]);
        await _local.saveReports([report]);
      }
    } catch (_) {
      // Silent — background refresh; errors are acceptable.
    }
  }

  Future<List<dynamic>> fetchReportEvidence(String reportId) async {
    try {
      final response = await _apiClient.dioClient.get(
        ApiConstants.evidenceByReportId(reportId),
      );
      final list = response.data as List<dynamic>;
      final maps = list.whereType<Map<String, dynamic>>().toList();
      await _local.saveEvidences(reportId, maps);
      return list;
    } catch (e) {
      log.severe('Failed to fetch report evidence', e);
      return await _local.getCachedEvidences(reportId);
    }
  }

  // ── Local-first mutations ───────────────────────────────────────────────
  //
  // Pattern for every mutation:
  //   1. Apply patch to local DB immediately (offline-visible).
  //   2. Enqueue outbox item (idempotent).
  //   3. Attempt backend call in background — do NOT await from callers.
  //   4. On network success: mark synced, remove outbox item.
  //   5. On network error: leave outbox item pending (Phase 3 will drain it).

  /// Acknowledges or otherwise updates the status of a report.
  Future<void> updateReportStatus(String id, String status) async {
    // Step 1 — local
    await _local.applyLocalReportPatch(id, {'status': status});
    // Step 2 — queue (idempotent; double-taps update payload, not create new)
    await _local.enqueueOutboxItem(
      operationType: FcOutboxOperationType.updateReportStatus,
      entityId: id,
      entityType: 'report',
      payload: {'status': status},
    );
    // Step 3 — background network attempt
    _tryPushReportStatus(id, status);
  }

  Future<void> _tryPushReportStatus(String id, String status) async {
    try {
      await _apiClient.dioClient.patch(
        ApiConstants.updateReportStatus(id),
        data: {'status': status},
      );
      await _local.markFcReportSynced(id);
      // Remove the outbox entry on success so it is not replayed.
      await _removeOutboxForEntity(
          FcOutboxOperationType.updateReportStatus, id);
    } catch (e) {
      if (!_isNetworkError(e)) {
        log.warning('updateReportStatus backend error (non-network): $e');
      }
      // Outbox entry stays — will be retried in Phase 3.
    }
  }

  /// Updates the lifecycle stage of a report.
  Future<void> updateLifecycleStage(String id, String stage) async {
    await _local.applyLocalReportPatch(id, {'lifecycle_stage': stage});
    await _local.enqueueOutboxItem(
      operationType: FcOutboxOperationType.updateLifecycleStage,
      entityId: id,
      entityType: 'report',
      payload: {'lifecycle_stage': stage},
    );
    _tryPushLifecycleStage(id, stage);
  }

  Future<void> _tryPushLifecycleStage(String id, String stage) async {
    try {
      await _apiClient.dioClient.patch(
        ApiConstants.updateReportLifecycleStage(id),
        data: {'lifecycle_stage': stage},
      );
      await _local.markFcReportSynced(id);
      await _removeOutboxForEntity(
          FcOutboxOperationType.updateLifecycleStage, id);
    } catch (e) {
      if (!_isNetworkError(e)) {
        log.warning('updateLifecycleStage backend error (non-network): $e');
      }
    }
  }

  /// Updates validation status.
  Future<void> updateReportValidation(String id, String status) async {
    await _local.applyLocalReportPatch(id, {'validation_status': status});
    await _local.enqueueOutboxItem(
      operationType: FcOutboxOperationType.updateReportValidation,
      entityId: id,
      entityType: 'report',
      payload: {'validation_status': status},
    );
    _tryPushReportValidation(id, status);
  }

  Future<void> _tryPushReportValidation(String id, String status) async {
    try {
      await _apiClient.dioClient.patch(
        ApiConstants.updateReportValidation(id),
        data: {'validation_status': status},
      );
      await _local.markFcReportSynced(id);
      await _removeOutboxForEntity(
          FcOutboxOperationType.updateReportValidation, id);
    } catch (e) {
      if (!_isNetworkError(e)) {
        log.warning('updateReportValidation backend error (non-network): $e');
      }
    }
  }

  /// Updates editable report details (notes field etc.).
  Future<void> updateReportDetails(String id, Map<String, dynamic> body) async {
    await _local.applyLocalReportPatch(id, body);
    await _local.enqueueOutboxItem(
      operationType: FcOutboxOperationType.updateReportDetails,
      entityId: id,
      entityType: 'report',
      payload: body,
    );
    _tryPushReportDetails(id, body);
  }

  Future<void> _tryPushReportDetails(
      String id, Map<String, dynamic> body) async {
    try {
      await _apiClient.dioClient.patch(
        ApiConstants.updateReportNotes(id),
        data: body,
      );
      await _local.markFcReportSynced(id);
      await _removeOutboxForEntity(
          FcOutboxOperationType.updateReportDetails, id);
    } catch (e) {
      if (!_isNetworkError(e)) {
        log.warning('updateReportDetails backend error (non-network): $e');
      }
    }
  }

  // ── Notes ───────────────────────────────────────────────────────────────

  /// Adds a Field Crew / LGU note.
  ///
  /// Locally: the note is persisted immediately to [FcCachedNotes] so it
  /// survives an app restart.
  ///
  /// Returns the locally-generated note that callers can show in the UI
  /// without waiting for the server.
  Future<AgencyResponse> logAgencyResponse(
    String reportId,
    Map<String, dynamic> body,
  ) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final userId = currentUser?.id ?? 'unknown';
    final now = DateTime.now().toIso8601String();

    final noteData = {
      'action_type': body['action_type'] ?? 'manual_note',
      'action_details': body['action'] ?? body['action_details'] ?? '',
      'user_id': userId,
      'created_at': now,
    };

    // Step 1 — persist locally
    final localId = await _local.addLocalNote(reportId, noteData);

    // Step 2 — queue (addNote is additive; always creates a new entry)
    await _local.enqueueOutboxItem(
      operationType: FcOutboxOperationType.addNote,
      entityId: reportId,
      entityType: 'report',
      payload: {
        ...body,
        '_local_note_id': localId,
      },
    );

    // Step 3 — background push
    _tryPushNote(reportId, body, localId);

    // Return a synthetic AgencyResponse so the UI can append it immediately.
    return AgencyResponse(
      id: localId,
      reportId: reportId,
      actionType: noteData['action_type'] as String,
      actionDetails: noteData['action_details'] as String?,
      createdAt: DateTime.now(),
      userId: userId,
    );
  }

  Future<void> _tryPushNote(
    String reportId,
    Map<String, dynamic> body,
    String localNoteId,
  ) async {
    try {
      await _apiClient.dioClient.post(
        ApiConstants.agencyResponses(reportId),
        data: body,
        options: Options(
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );
      // Remove from outbox using the localNoteId as entityId isn't unique
      // for notes.  We'll just clear the first pending addNote for this report.
      await _removeFirstNoteOutboxForReport(reportId, localNoteId);
    } catch (e) {
      if (!_isNetworkError(e)) {
        log.warning('logAgencyResponse backend error (non-network): $e');
      }
    }
  }

  Future<List<AgencyResponse>> fetchAgencyResponses(String reportId) async {
    try {
      final response =
          await _apiClient.dioClient.get(ApiConstants.agencyResponses(reportId));
      final List<dynamic> data = response.data;
      final responses =
          data.map((json) => AgencyResponse.fromJson(json)).toList();
      // Replace local note cache with authoritative server data.
      await _local.saveNotes(
        reportId,
        data.whereType<Map<String, dynamic>>().toList(),
      );
      return responses;
    } catch (e) {
      log.severe('Failed to fetch agency responses', e);
      // Offline fallback: read from local cache.
      final cached = await _local.getCachedNotes(reportId);
      return cached.map((m) => AgencyResponse.fromJson(m)).toList();
    }
  }

  // ── Photo operations (offline-first via FcLocalPhotoRepository) ──────────
  //
  // The local photo repo handles file copy + dedup.
  // We then patch the cached JSON so the report reflects the local path,
  // enqueue the outbox item, and fire the background push.

  /// Adds a before/after photo for a report.
  ///
  /// Returns the stable [localPhotoId] assigned to the new photo row so
  /// callers can reference it if needed.
  ///
  /// Throws [FcPhotoSlotOccupiedException] or [FcPhotoDuplicateException]
  /// from [FcLocalPhotoRepository] if the slot is occupied or the file is a
  /// duplicate — let these propagate so the UI can show a meaningful message.
  Future<String> uploadReportPhoto(
    String reportId,
    File file,
    String photoType,
  ) async {
    // Step 1 — Copy file to permanent storage, check dedup/slot, insert DB row.
    final localPhotoId = await _localPhoto.addPhoto(
      entityId: reportId,
      entityType: 'report',
      photoType: photoType,
      sourceFile: file,
    );

    // Step 2 — Patch cached report JSON with the local path so the UI
    //           renders the thumbnail immediately without a network round-trip.
    final localPath = (await _localPhoto.getActivePhoto(
      reportId,
      'report',
      photoType,
    ))
        ?.localPath ?? file.path;

    await _local.applyLocalReportPatch(reportId, {
      '${photoType}_photo_url': localPath,
    });

    final opType = photoType == 'before'
        ? FcOutboxOperationType.uploadBeforePhoto
        : FcOutboxOperationType.uploadAfterPhoto;

    // Step 3 — Queue outbox intent (idempotent).
    await _local.enqueueOutboxItem(
      operationType: opType,
      entityId: reportId,
      entityType: 'report',
      payload: {
        'photo_type': photoType,
        'local_photo_id': localPhotoId,
        'file_path': localPath,
      },
    );

    // Step 4 — Background push; do NOT await.
    _tryPushUploadReportPhoto(reportId, file, photoType, opType, localPhotoId);

    return localPhotoId;
  }

  Future<void> _tryPushUploadReportPhoto(
    String reportId,
    File file,
    String photoType,
    String opType,
    String localPhotoId,
  ) async {
    await _localPhoto.markInFlight(localPhotoId);
    try {
      final fileName = file.path.split('/').last;
      final formData = FormData.fromMap({
        'photo_type': photoType,
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
      });
      final response = await _apiClient.dioClient.post(
        ApiConstants.uploadReportPhoto(reportId),
        data: formData,
        options: Options(
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      // Parse remote URL/id from response if the server returns them.
      final remoteId = _extractString(response.data, 'id');
      final remoteUrl = _extractString(response.data, 'url') ??
          _extractString(response.data, '${photoType}_photo_url');

      // Mark local photo row as synced with remote identifiers.
      await _localPhoto.markSynced(
        localPhotoId,
        remoteId: remoteId,
        remoteUrl: remoteUrl,
      );

      // Update cached JSON with the authoritative remote URL if available.
      if (remoteUrl != null) {
        await _local.applyLocalReportPatch(reportId, {
          '${photoType}_photo_url': remoteUrl,
        });
      }

      await _local.markFcReportSynced(reportId);
      await _removeOutboxForEntity(opType, reportId);
    } catch (e) {
      await _localPhoto.markFailed(localPhotoId, e.toString());
      if (!_isNetworkError(e)) {
        log.warning('uploadReportPhoto backend error (non-network): $e');
      }
    }
  }

  /// Deletes a before/after photo for a report.
  ///
  /// Finds the active [FcLocalPhoto] row for the slot; if it was never
  /// uploaded the row is purged immediately.  If it was synced, the row is
  /// flagged as `pendingDelete` and the server DELETE is attempted in the
  /// background.
  Future<void> deleteReportPhoto(String reportId, String photoType) async {
    // Find the active local photo row for this slot.
    final photoRow = await _localPhoto.getActivePhoto(
      reportId,
      'report',
      photoType,
    );

    if (photoRow != null) {
      // Step 1 — Mark row as pending-delete (or hard-delete if unsynced).
      await _localPhoto.deletePhoto(photoRow.localPhotoId);
    }

    // Step 2 — Patch cached JSON to null the URL so the UI reflects deletion.
    await _local.applyLocalReportPatch(reportId, {
      '${photoType}_photo_url': null,
    });

    // Step 3 — Queue outbox intent (idempotent).
    await _local.enqueueOutboxItem(
      operationType: FcOutboxOperationType.deletePhoto,
      entityId: reportId,
      entityType: 'report',
      payload: {
        'photo_type': photoType,
        if (photoRow != null) 'local_photo_id': photoRow.localPhotoId,
        if (photoRow?.remoteId != null) 'remote_id': photoRow!.remoteId,
      },
    );
    await _local.deletePhotoMetadata(reportId, 'report', photoType);

    // Step 4 — Background push (only needed if the photo had reached the server).
    if (photoRow?.syncStatus == FcLocalPhotoSyncStatus.synced) {
      _tryPushDeleteReportPhoto(
        reportId,
        photoType,
        photoRow!.localPhotoId,
      );
    } else {
      // Never reached the server — nothing to delete remotely; clean outbox.
      await _removeOutboxForEntity(FcOutboxOperationType.deletePhoto, reportId);
    }
  }

  Future<void> _tryPushDeleteReportPhoto(
    String reportId,
    String photoType,
    String localPhotoId,
  ) async {
    try {
      await _apiClient.dioClient.delete(
        ApiConstants.uploadReportPhoto(reportId),
        data: {'photo_type': photoType},
        options: Options(
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );
      // Confirmed deleted on server — purge local file and row.
      await _localPhoto.purgePhoto(localPhotoId);
      await _local.markFcReportSynced(reportId);
      await _removeOutboxForEntity(FcOutboxOperationType.deletePhoto, reportId);
    } catch (e) {
      if (!_isNetworkError(e)) {
        log.warning('deleteReportPhoto backend error (non-network): $e');
      }
      // Row stays as pendingDelete — outbox entry stays pending for retry.
    }
  }

  // ── Bulk fetch helpers ─────────────────────────────────────────────────

  Future<List<ReportModel>> fetchFilteredReports() async {
    try {
      log.info('Fetching filtered reports from Supabase reports_view...');
      final response = await Supabase.instance.client
          .from('reports_view')
          .select()
          .order('created_at', ascending: false);

      log.info('Got ${response.length} raw reports from reports_view');

      final reports = (response as List<dynamic>)
          .map((json) {
            try {
              return ReportModel.fromJson(json as Map<String, dynamic>);
            } catch (e) {
              log.warning('Failed to parse report: $e  json=$json');
              return null;
            }
          })
          .whereType<ReportModel>()
          .toList();

      await _cacheService.cacheReports(reports);
      await _local.saveReports(reports);
      await _local.recordSyncAt('fc_reports');
      return reports;
    } catch (e) {
      log.severe(
          'Failed to fetch reports from Supabase, falling back to Drift cache',
          e);
      final localReports = await _local.getCachedReports();
      if (localReports.isNotEmpty) return localReports;
      return await _cacheService.getCachedReports();
    }
  }

  Future<List<String>> fetchIssueTypes() async {
    try {
      final response = await Supabase.instance.client
          .from('reports_view')
          .select('issue_type')
          .not('issue_type', 'is', null);

      final types = (response as List<dynamic>)
          .map((row) => row['issue_type']?.toString())
          .whereType<String>()
          .toSet()
          .toList()
        ..sort();

      return types;
    } catch (e) {
      log.severe('Failed to fetch issue types from Supabase', e);
      return ['Littering', 'Illegal Dumping', 'Overflowing Bin', 'Vandalism'];
    }
  }

  Future<List<dynamic>> fetchAvailableCrew() async {
    try {
      final response =
          await _apiClient.dioClient.get('/api/admin/field-crews');
      return response.data as List<dynamic>;
    } catch (e) {
      log.severe('Failed to fetch available crew', e);
      return [];
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────

  /// Removes the outbox entry for a given operation type + entity after a
  /// successful sync, so it is not replayed.
  Future<void> _removeOutboxForEntity(
      String operationType, String entityId) async {
    try {
      final item = await _local.findPendingOutboxItem(operationType, entityId);
      if (item != null) {
        await _local.deleteOutboxItem(item.operationId);
      }
    } catch (_) {}
  }

  /// Removes the first pending addNote outbox entry that matches the
  /// given [localNoteId] in its payload.
  Future<void> _removeFirstNoteOutboxForReport(
      String reportId, String localNoteId) async {
    try {
      final items = await _local.getPendingOutboxItems();
      for (final item in items) {
        if (item.operationType == FcOutboxOperationType.addNote &&
            item.entityId == reportId &&
            item.payloadJson.contains(localNoteId)) {
          await _local.deleteOutboxItem(item.operationId);
          break;
        }
      }
    } catch (_) {}
  }

  /// Safely extracts a String value from a response data map.
  String? _extractString(dynamic data, String key) {
    if (data is Map<String, dynamic>) {
      final v = data[key];
      if (v is String && v.isNotEmpty) return v;
    }
    return null;
  }
}
