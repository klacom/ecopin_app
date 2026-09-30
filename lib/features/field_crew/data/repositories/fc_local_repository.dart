import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:ecopin_app/core/database/app_database.dart';
import 'package:ecopin_app/features/field_crew/data/models/cleanup_task_model.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

/// Repository that provides local-first read/write access for all Field Crew
/// data stored in the Drift database.
///
/// Every method here is offline-capable — it never calls a network.
/// Networking lives in the existing repositories; they call into this one
/// to cache downloaded data and to enqueue outbox mutations.
class FcLocalRepository {
  final AppDatabase _db;
  final _log = Logger('FcLocalRepository');
  final _uuid = const Uuid();

  FcLocalRepository(this._db);

  // ── Sync cursor ─────────────────────────────────────────────────────────

  /// Returns the last successful sync time for a named collection.
  Future<DateTime?> getLastSyncAt(String collectionKey) =>
      _db.getFcSyncCursor(collectionKey);

  /// Marks a collection as synced at [syncedAt] (defaults to now).
  Future<void> recordSyncAt(
    String collectionKey, [
    DateTime? syncedAt,
  ]) =>
      _db.setFcSyncCursor(collectionKey, syncedAt ?? DateTime.now());

  // ── Reports ─────────────────────────────────────────────────────────────

  /// Upserts a list of [ReportModel] objects as locally synced (state = 0).
  /// Called by [FieldCrewReportRepository] after a successful API fetch.
  Future<void> saveReports(List<ReportModel> reports) async {
    try {
      final rows = reports.map((r) {
        return FcCachedReportsCompanion.insert(
          id: r.id,
          jsonData: jsonEncode(_reportToJson(r)),
          localSyncState: const Value(0),
          serverUpdatedAt: r.updatedAt,
          cachedAt: Value(DateTime.now()),
        );
      }).toList();
      await _db.upsertFcReports(rows);
    } catch (e) {
      _log.severe('saveReports failed', e);
    }
  }

  /// Returns all locally cached reports.
  Future<List<ReportModel>> getCachedReports() async {
    try {
      final rows = await _db.getAllFcReports();
      return rows
          .map((r) {
            try {
              return ReportModel.fromJson(
                jsonDecode(r.jsonData) as Map<String, dynamic>,
              );
            } catch (e) {
              _log.warning('Failed to deserialise cached report ${r.id}: $e');
              return null;
            }
          })
          .whereType<ReportModel>()
          .toList();
    } catch (e) {
      _log.severe('getCachedReports failed', e);
      return [];
    }
  }

  /// Returns a single cached report by its server UUID.
  Future<ReportModel?> getCachedReportById(String id) async {
    try {
      final row = await _db.getFcReportById(id);
      if (row == null) return null;
      return ReportModel.fromJson(
        jsonDecode(row.jsonData) as Map<String, dynamic>,
      );
    } catch (e) {
      _log.severe('getCachedReportById($id) failed', e);
      return null;
    }
  }

  /// Returns the raw Drift row for a report, exposing [localSyncState].
  Future<FcCachedReport?> getCachedReportDbRow(String id) =>
      _db.getFcReportById(id);

  /// Finds the first pending/failed outbox item for a given operation + entity.
  Future<FcOutboxItem?> findPendingOutboxItem(
    String operationType,
    String entityId,
  ) =>
      _db.getPendingOutboxItemForEntity(
        operationType: operationType,
        entityId: entityId,
      );


  /// Returns only reports that have pending local mutations.
  Future<List<ReportModel>> getLocallyModifiedReports() async {
    try {
      final rows = await _db.getLocallyModifiedFcReports();
      return rows
          .map((r) {
            try {
              return ReportModel.fromJson(
                jsonDecode(r.jsonData) as Map<String, dynamic>,
              );
            } catch (e) {
              return null;
            }
          })
          .whereType<ReportModel>()
          .toList();
    } catch (e) {
      _log.severe('getLocallyModifiedReports failed', e);
      return [];
    }
  }

  /// Applies a local mutation to the cached report JSON and marks it modified.
  /// [patch] is a partial map that is merged into the stored JSON.
  Future<void> applyLocalReportPatch(
    String reportId,
    Map<String, dynamic> patch,
  ) async {
    try {
      final existing = await _db.getFcReportById(reportId);
      if (existing == null) return;
      final json =
          jsonDecode(existing.jsonData) as Map<String, dynamic>;
      json.addAll(patch);
      await _db.updateFcReportJson(reportId, jsonEncode(json));
      await _db.markFcReportLocallyModified(reportId);
    } catch (e) {
      _log.severe('applyLocalReportPatch($reportId) failed', e);
    }
  }

  Future<void> markFcReportSynced(String id) =>
      _db.markFcReportSynced(id);

  // ── Tasks ────────────────────────────────────────────────────────────────

  /// Upserts a list of [CleanupTask] objects as locally synced.
  Future<void> saveTasks(List<CleanupTask> tasks) async {
    try {
      final rows = tasks.map((t) {
        return FcCachedTasksCompanion.insert(
          id: t.id,
          jsonData: jsonEncode(t.toJson()),
          localSyncState: const Value(0),
          serverUpdatedAt: t.updatedAt,
          cachedAt: Value(DateTime.now()),
        );
      }).toList();
      await _db.upsertFcTasks(rows);
    } catch (e) {
      _log.severe('saveTasks failed', e);
    }
  }

  /// Returns all locally cached cleanup tasks.
  Future<List<CleanupTask>> getCachedTasks() async {
    try {
      final rows = await _db.getAllFcTasks();
      return rows
          .map((r) {
            try {
              return CleanupTask.fromJson(
                jsonDecode(r.jsonData) as Map<String, dynamic>,
              );
            } catch (e) {
              _log.warning('Failed to deserialise cached task ${r.id}: $e');
              return null;
            }
          })
          .whereType<CleanupTask>()
          .toList();
    } catch (e) {
      _log.severe('getCachedTasks failed', e);
      return [];
    }
  }

  /// Returns a single cached task by its server UUID.
  Future<CleanupTask?> getCachedTaskById(String id) async {
    try {
      final row = await _db.getFcTaskById(id);
      if (row == null) return null;
      return CleanupTask.fromJson(
        jsonDecode(row.jsonData) as Map<String, dynamic>,
      );
    } catch (e) {
      _log.severe('getCachedTaskById($id) failed', e);
      return null;
    }
  }

  /// Returns the raw Drift row for a task, exposing [localSyncState].
  Future<FcCachedTask?> getCachedTaskDbRow(String id) =>
      _db.getFcTaskById(id);


  Future<void> markFcTaskLocallyModified(String id) =>
      _db.markFcTaskLocallyModified(id);

  Future<void> markFcTaskSynced(String id) =>
      _db.markFcTaskSynced(id);

  Future<void> applyLocalTaskPatch(String taskId, Map<String, dynamic> patch) async {
    try {
      final existing = await _db.getFcTaskById(taskId);
      if (existing == null) return;
      final json = jsonDecode(existing.jsonData) as Map<String, dynamic>;
      json.addAll(patch);
      await (updateFcTaskJson(taskId, jsonEncode(json)));
      await markFcTaskLocallyModified(taskId);
    } catch (e) {
      _log.severe('applyLocalTaskPatch($taskId) failed', e);
    }
  }

  Future<void> updateFcTaskJson(String id, String newJsonData) async {
    await (_db.update(_db.fcCachedTasks)..where((t) => t.id.equals(id)))
        .write(FcCachedTasksCompanion(jsonData: Value(newJsonData)));
  }

  // ── Evidence ─────────────────────────────────────────────────────────────

  /// Replaces all cached evidence for [reportId] with [evidenceList].
  Future<void> saveEvidences(
    String reportId,
    List<Map<String, dynamic>> evidenceList,
  ) async {
    try {
      await _db.deleteFcEvidencesForReport(reportId);
      if (evidenceList.isEmpty) return;
      final rows = evidenceList.map((e) {
        return FcCachedEvidencesCompanion.insert(
          id: e['id']?.toString() ?? _uuid.v4(),
          reportId: reportId,
          jsonData: jsonEncode(e),
        );
      }).toList();
      await _db.upsertFcEvidences(reportId, rows);
    } catch (e) {
      _log.severe('saveEvidences($reportId) failed', e);
    }
  }

  /// Returns cached evidence items for [reportId].
  Future<List<Map<String, dynamic>>> getCachedEvidences(
    String reportId,
  ) async {
    try {
      final rows = await _db.getFcEvidencesForReport(reportId);
      return rows.map((r) {
        return jsonDecode(r.jsonData) as Map<String, dynamic>;
      }).toList();
    } catch (e) {
      _log.severe('getCachedEvidences($reportId) failed', e);
      return [];
    }
  }

  // ── Notes ────────────────────────────────────────────────────────────────

  /// Replaces all cached notes for [reportId] with [notesList] (server-fetched).
  Future<void> saveNotes(
    String reportId,
    List<Map<String, dynamic>> notesList,
  ) async {
    try {
      await _db.deleteFcNotesForReport(reportId);
      if (notesList.isEmpty) return;
      final rows = notesList.map((n) {
        return FcCachedNotesCompanion.insert(
          id: n['id']?.toString() ?? _uuid.v4(),
          reportId: reportId,
          jsonData: jsonEncode(n),
        );
      }).toList();
      await _db.upsertFcNotes(reportId, rows);
    } catch (e) {
      _log.severe('saveNotes($reportId) failed', e);
    }
  }

  /// Appends a single note written locally (before it has a server ID).
  ///
  /// The note map should include at minimum: action_type, action_details,
  /// user_id, created_at.  A stable client-generated id is stored so the
  /// note survives an app restart and can be matched once the server assigns
  /// a real id.
  Future<String> addLocalNote(
    String reportId,
    Map<String, dynamic> noteData,
  ) async {
    final localId = _uuid.v4();
    final data = {
      ...noteData,
      'id': localId,
      'report_id': reportId,
      'created_at': noteData['created_at'] ?? DateTime.now().toIso8601String(),
    };
    try {
      await _db.upsertFcNotes(reportId, [
        FcCachedNotesCompanion.insert(
          id: localId,
          reportId: reportId,
          jsonData: jsonEncode(data),
        ),
      ]);
    } catch (e) {
      _log.severe('addLocalNote($reportId) failed', e);
    }
    return localId;
  }

  /// Returns cached notes for [reportId].
  Future<List<Map<String, dynamic>>> getCachedNotes(String reportId) async {
    try {
      final rows = await _db.getFcNotesForReport(reportId);
      return rows.map((r) {
        return jsonDecode(r.jsonData) as Map<String, dynamic>;
      }).toList();
    } catch (e) {
      _log.severe('getCachedNotes($reportId) failed', e);
      return [];
    }
  }

  // ── Photo metadata ────────────────────────────────────────────────────────

  /// Upserts photo metadata (URL / storage path) for a given entity.
  Future<void> savePhotoMetadata({
    required String entityId,
    required String entityType,
    required String photoType,
    String? photoUrl,
    String? storagePath,
  }) async {
    try {
      final id = '${entityId}_${entityType}_$photoType';
      await _db.upsertFcPhotoMetadata(
        FcCachedPhotoMetadataCompanion.insert(
          id: id,
          entityId: entityId,
          entityType: entityType,
          photoType: photoType,
          photoUrl: Value(photoUrl),
          storagePath: Value(storagePath),
        ),
      );
    } catch (e) {
      _log.severe('savePhotoMetadata($entityId) failed', e);
    }
  }

  /// Returns all photo metadata rows for a given entity.
  Future<List<FcCachedPhotoMetadataData>> getPhotoMetadata(
    String entityId,
    String entityType,
  ) =>
      _db.getFcPhotosForEntity(entityId, entityType);

  Future<void> deletePhotoMetadata(
    String entityId,
    String entityType,
    String photoType,
  ) =>
      _db.deleteFcPhotoMetadata('${entityId}_${entityType}_$photoType');

  // ── Outbox ────────────────────────────────────────────────────────────────

  /// Enqueues a mutation into the outbox, with idempotency.
  ///
  /// If a pending/failed item with the same [operationType] and [entityId]
  /// already exists it is **replaced** (payload updated) rather than
  /// duplicated.  This prevents double-taps from producing two queue entries.
  ///
  /// Returns the stable [operationId] assigned to this item.
  Future<String> enqueueOutboxItem({
    required String operationType,
    required String entityId,
    required String entityType,
    required Map<String, dynamic> payload,
    String? baseVersion,
  }) async {
    // Notes are always additive; every tap produces a distinct operation.
    final isAdditive = operationType == FcOutboxOperationType.addNote;
    if (!isAdditive) {
      // Look for an existing pending/failed item for this operation + entity.
      final existing = await _db.getPendingOutboxItemForEntity(
        operationType: operationType,
        entityId: entityId,
      );
      if (existing != null) {
        // Update payload only — reuse the same operationId so callers can
        // track it.  Status stays pending.
        await _db.updateOutboxItemPayload(
          existing.operationId,
          jsonEncode(payload),
        );
        _log.fine(
          'enqueueOutboxItem: updated existing $operationType/$entityId'
          ' (op=${existing.operationId})',
        );
        return existing.operationId;
      }
    }

    final operationId = _uuid.v4();
    try {
      await _db.enqueueOutboxItem(
        FcOutboxItemsCompanion.insert(
          operationId: operationId,
          operationType: operationType,
          entityId: entityId,
          entityType: entityType,
          payloadJson: jsonEncode(payload),
          baseVersion: Value(baseVersion),
          status: const Value('pending'),
        ),
      );
    } catch (e) {
      _log.severe('enqueueOutboxItem($operationType/$entityId) failed', e);
    }
    return operationId;
  }

  /// Returns all pending and failed outbox items in FIFO order.
  Future<List<FcOutboxItem>> getPendingOutboxItems() =>
      _db.getPendingOutboxItems();

  /// Returns all outbox items (for diagnostics / sync center preview).
  Future<List<FcOutboxItem>> getAllOutboxItems() => _db.getAllOutboxItems();

  Future<void> markOutboxItemInFlight(String operationId) =>
      _db.markOutboxItemInFlight(operationId);

  Future<void> markOutboxItemFailed(String operationId, String error) =>
      _db.incrementOutboxRetryCount(operationId, error);

  Future<void> deleteOutboxItem(String operationId) =>
      _db.deleteOutboxItem(operationId);

  /// Called on app startup to recover items that were in-flight when the app
  /// was killed.
  Future<void> recoverInFlightItems() => _db.resetInFlightOutboxItems();

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Produces a JSON-serialisable map from a [ReportModel].
  /// Uses the model's own [toJson] and adds lat/lng for round-trip safety.
  Map<String, dynamic> _reportToJson(ReportModel r) {
    final json = r.toJson();
    // toJson() already includes latitude / longitude.
    // Add validation_status and status separately so fromJson can read them.
    json['validation_status'] = r.validationStatus;
    json['status'] = r.status;
    json['cluster_id'] = r.clusterId;
    json['user_id'] = r.userId;
    json['created_at'] = r.createdAt.toIso8601String();
    json['updated_at'] = r.updatedAt.toIso8601String();
    json['before_photo_url'] = r.beforePhotoUrl;
    json['after_photo_url'] = r.afterPhotoUrl;
    json['is_overdue'] = r.isOverdue;
    return json;
  }
}

