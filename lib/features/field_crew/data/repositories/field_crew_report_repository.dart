import 'dart:io';
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

class FieldCrewReportRepository {
  final ApiClient _apiClient;
  final CacheService _cacheService;
  final FcLocalRepository _local;
  final FcLocalPhotoRepository _localPhoto;
  final Logger log = Logger('FieldCrewReportRepository');

  FieldCrewReportRepository(
    this._apiClient,
    this._cacheService,
    this._local,
    this._localPhoto,
  );

  // ── Network helper ──────────────────────────────────────────────────────

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
      if (cached.isNotEmpty) {
        return cached.where((r) => r.clusterId == clusterId).toList();
      }
      return (await _cacheService.getCachedReports())
          .where((r) => r.clusterId == clusterId)
          .toList();
    }
  }

  Future<List<ReportModel>> fetchReportsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final wanted = ids.toSet();
    final found = <String, ReportModel>{};
    try {
      final unique = wanted.toList();
      for (var offset = 0; offset < unique.length; offset += 100) {
        final chunk = unique.skip(offset).take(100).toSet();
        final response = await _apiClient.dioClient.get(
          ApiConstants.reports,
          queryParameters: {'ids': chunk.join(','), 'limit': 100},
        );
        for (final raw in response.data as List) {
          final report = ReportModel.fromJson(Map<String, dynamic>.from(raw));
          if (chunk.contains(report.id)) found[report.id] = report;
        }
      }
      await _cacheService.cacheReports(found.values.toList());
      await _local.saveReports(found.values.toList());
    } catch (e) {
      log.warning('Linked report refresh unavailable', e);
    }
    // Local edits remain authoritative until synchronized. Never return another task's cached reports.
    for (final report in await _local.getCachedReports()) {
      if (wanted.contains(report.id) &&
          (!found.containsKey(report.id) ||
              ((await _local.getCachedReportDbRow(report.id))?.localSyncState ??
                      0) !=
                  0)) {
        found[report.id] = report;
      }
    }
    if (found.isEmpty) {
      for (final report in await _cacheService.getCachedReports()) {
        if (wanted.contains(report.id)) found[report.id] = report;
      }
    }
    return [
      for (final id in wanted)
        if (found[id] != null) found[id]!,
    ];
  }

  Future<Map<String, List<dynamic>>> fetchEvidenceByReportIds(
    List<String> ids,
  ) async {
    final result = <String, List<dynamic>>{};
    final unique = ids.toSet().toList();
    for (var offset = 0; offset < unique.length; offset += 10) {
      final chunk = unique.skip(offset).take(10).toList();
      final response = await _apiClient.dioClient.post(
        '/api/reports/batch-evidence',
        data: {'reportIds': chunk, 'strict': true},
      );
      final data = Map<String, dynamic>.from(response.data);
      for (final id in chunk) {
        if (data[id] is! List) throw StateError('Evidence response incomplete');
        final rows = (data[id] as List)
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
        await _local.saveEvidences(id, rows);
        result[id] = rows;
      }
    }
    return result;
  }

  /// Returns a report. Prefers the local Drift cache so locally-modified
  /// data is always visible, then falls back to the network.
  Future<ReportModel> fetchReportById(String id, {bool refresh = false}) async {
    // 1. Try local cache first — returns locally-modified state immediately.
    final local = await _local.getCachedReportById(id);
    if (local != null &&
        (!refresh ||
            ((await _local.getCachedReportDbRow(id))?.localSyncState ?? 0) !=
                0)) {
      // Refresh in background — don't await, don't block.
      _refreshReportFromNetwork(id);
      return local;
    }
    // 2. Nothing cached; must go to network.
    try {
      final response = await _apiClient.dioClient.get(
        ApiConstants.getReportById(id),
      );
      final report = ReportModel.fromJson(response.data);
      await _cacheService.cacheReports([report]);
      await _local.saveReports([report]);
      return report;
    } catch (e) {
      log.severe('Failed to fetch report by id $id', e);
      if (local != null) return local;
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
      final response = await _apiClient.dioClient.get(
        ApiConstants.getReportById(id),
      );
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
      final cached = await _local.getCachedEvidences(reportId);
      if (cached.isNotEmpty) return cached;
      rethrow;
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
  Future<void> updateReportStatus(
    String id,
    String status, {
    String? notes,
  }) async {
    // Step 1 — local
    final baseVersion = (await _local.getCachedReportById(id))?.fcVersion ?? 0;
    final payload = {
      'status': status,
      if (notes != null) 'cleanup_action_notes': notes.trim(),
    };
    await _local.applyLocalReportPatch(id, payload);
    // Step 2 — queue (idempotent; double-taps update payload, not create new)
    await _local.enqueueOutboxItem(
      operationType: FcOutboxOperationType.updateReportStatus,
      entityId: id,
      entityType: 'report',
      payload: payload,
      baseVersion: baseVersion.toString(),
    );
    // Step 3 — background network attempt
  }

  /// Updates the lifecycle stage of a report.
  Future<void> updateLifecycleStage(String id, String stage) async {
    final baseVersion = (await _local.getCachedReportById(id))?.fcVersion ?? 0;
    await _local.applyLocalReportPatch(id, {'stage': stage});
    await _local.enqueueOutboxItem(
      operationType: FcOutboxOperationType.updateLifecycleStage,
      entityId: id,
      entityType: 'report',
      payload: {'stage': stage},
      baseVersion: baseVersion.toString(),
    );
  }

  /// Updates validation status.
  Future<void> updateReportValidation(String id, String status) async {
    final baseVersion = (await _local.getCachedReportById(id))?.fcVersion ?? 0;
    await _local.applyLocalReportPatch(id, {'validation_status': status});
    await _local.enqueueOutboxItem(
      operationType: FcOutboxOperationType.updateReportValidation,
      entityId: id,
      entityType: 'report',
      payload: {'validation_status': status},
      baseVersion: baseVersion.toString(),
    );
  }

  /// Updates editable report details (notes field etc.).
  Future<void> updateReportDetails(String id, Map<String, dynamic> body) async {
    final baseVersion = (await _local.getCachedReportById(id))?.fcVersion ?? 0;
    await _local.applyLocalReportPatch(id, body);
    await _local.enqueueOutboxItem(
      operationType: FcOutboxOperationType.updateReportDetails,
      entityId: id,
      entityType: 'report',
      payload: body,
      baseVersion: baseVersion.toString(),
    );
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
      payload: {...body, '_local_note_id': localId},
    );

    // Step 3 — background push

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

  Future<List<AgencyResponse>> fetchAgencyResponses(String reportId) async {
    try {
      final response = await _apiClient.dioClient.get(
        ApiConstants.agencyResponses(reportId),
      );
      final List<dynamic> data = response.data;
      final responses = data
          .map((json) => AgencyResponse.fromJson(json))
          .toList();
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
    if (photoType == 'before' || photoType == 'after') {
      final cached = await _local.getCachedReportById(reportId);
      final removed = (await _localPhoto.getPendingDeletes())
          .where(
            (p) =>
                p.entityId == reportId &&
                p.entityType == 'report' &&
                p.photoType == photoType,
          )
          .map((p) => p.remoteId ?? p.localPhotoId)
          .toSet();
      final entries = photoType == 'before'
          ? (cached?.beforePhotos ?? <Map<String, dynamic>>[])
          : (cached?.afterPhotos ?? <Map<String, dynamic>>[]);
      final legacyUrl = photoType == 'before'
          ? cached?.beforePhotoUrl
          : cached?.afterPhotoUrl;
      final keys = {
        for (final p in entries)
          if (!removed.contains(p['id'])) p['id'],
      };
      final urls = {
        for (final p in entries)
          if (!removed.contains(p['id'])) p['url'],
      };
      if (entries.isEmpty &&
          !removed.contains('legacy') &&
          legacyUrl?.startsWith('https://') == true) {
        keys.add('legacy');
        urls.add(legacyUrl);
      }
      for (final p in await _localPhoto.getPhotosForEntity(
        reportId,
        'report',
      )) {
        if (p.photoType == photoType && !urls.contains(p.remoteUrl)) {
          keys.add(p.remoteId ?? p.localPhotoId);
        }
      }
      if (keys.length >= 5) {
        final label = photoType == 'before' ? 'Before' : 'After';
        throw FcPhotoSlotOccupiedException('Maximum 5 $label photos reached.');
      }
    }
    // Step 1 — Copy file to permanent storage, check dedup/slot, insert DB row.
    final localPhotoId = await _localPhoto.addPhoto(
      entityId: reportId,
      entityType: 'report',
      photoType: photoType,
      sourceFile: file,
    );

    // Step 2 — Patch cached report JSON with the local path so the UI
    //           renders the thumbnail immediately without a network round-trip.
    //           Note: do NOT auto-transition stage/status on photo upload;
    //           the crew explicitly taps Mark as Acknowledged / Mark as Complete.
    final localPath =
        (await _localPhoto.getPhotoById(localPhotoId))?.localPath ?? file.path;

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

    return localPhotoId;
  }

  /// Deletes a before/after photo for a report.
  ///
  /// Finds the active [FcLocalPhoto] row for the slot; if it was never
  /// uploaded the row is purged immediately.  If it was synced, the row is
  /// flagged as `pendingDelete` and the server DELETE is attempted in the
  /// background.
  Future<void> deleteReportPhoto(
    String reportId,
    String photoType, {
    String? photoId,
  }) async {
    final rows = await _localPhoto.getPhotosForEntity(reportId, 'report');
    FcLocalPhoto? target;
    for (final row in rows) {
      if (row.photoType == photoType &&
          (photoId == null ||
              row.localPhotoId == photoId ||
              row.remoteId == photoId)) {
        target = row;
        break;
      }
    }
    if (target != null) {
      await _localPhoto.deletePhoto(target.localPhotoId);
    } else {
      final cached = await _local.getCachedReportById(reportId);
      final url = photoType == 'before'
          ? cached?.beforePhotoUrl
          : cached?.afterPhotoUrl;
      await _localPhoto.queueRemoteDeletion(
        reportId,
        photoType,
        photoId ?? 'legacy',
        url,
      );
    }
    final active = (await _localPhoto.getPhotosForEntity(
      reportId,
      'report',
    )).where((p) => p.photoType == photoType).toList();
    final cached = await _local.getCachedReportById(reportId);
    final removed = (await _localPhoto.getPendingDeletes())
        .where(
          (p) =>
              p.entityId == reportId &&
              p.entityType == 'report' &&
              p.photoType == photoType,
        )
        .map((p) => p.remoteId)
        .toSet();
    final collectionKey = photoType == 'before'
        ? 'before_photos'
        : 'after_photos';
    final urlKey = photoType == 'before'
        ? 'before_photo_url'
        : 'after_photo_url';
    final existingRemote = photoType == 'before'
        ? cached?.beforePhotos
        : cached?.afterPhotos;
    final remote =
        existingRemote?.where((p) => !removed.contains(p['id'])).toList() ?? [];
    await _local.applyLocalReportPatch(reportId, {
      collectionKey: remote,
      urlKey: active.isNotEmpty
          ? active.first.remoteUrl ?? active.first.localPath
          : remote.firstOrNull?['url'],
    });
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
        e,
      );
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

      final types =
          (response as List<dynamic>)
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
      final response = await _apiClient.dioClient.get('/api/admin/field-crews');
      return response.data as List<dynamic>;
    } catch (e) {
      log.severe('Failed to fetch available crew', e);
      return [];
    }
  }
}
