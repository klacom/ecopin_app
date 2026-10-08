import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_sqflite/drift_sqflite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

// ─────────────────────────────────────────────────────────────────────────────
// LEGACY TABLES (citizen offline-submission flow — unchanged, do not remove)
// ─────────────────────────────────────────────────────────────────────────────

class OfflineReports extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get idempotencyKey => text().unique()();
  TextColumn get title => text()();
  TextColumn get description => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  BoolColumn get onPrivateProperty =>
      boolean().withDefault(const Constant(false))();
  TextColumn get scaleLevel => text().nullable()();
  TextColumn get obstructionLevel => text().nullable()();

  // Media files (stored as comma-separated paths or JSON)
  TextColumn get imagePaths => text().nullable()();
  TextColumn get videoPath => text().nullable()();

  // Sync state
  IntColumn get syncStatus => integer().withDefault(
    const Constant(0),
  )(); // 0=pending 1=syncing 2=failed
  TextColumn get syncError => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class OfflineTaskUpdates extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId => integer()();

  // Storing the payload as a JSON string
  TextColumn get payloadJson => text()();

  DateTimeColumn get clientKnownUpdatedAt => dateTime()();

  // Sync state
  IntColumn get syncStatus => integer().withDefault(
    const Constant(0),
  )(); // 0=pending 1=syncing 2=failed
  TextColumn get syncError => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class OfflineMedia extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get idempotencyKey => text().unique()();
  TextColumn get imagePaths => text().nullable()();
  TextColumn get videoPath => text().nullable()();
  IntColumn get syncStatus => integer().withDefault(
    const Constant(0),
  )(); // 0=pending 1=syncing 2=failed
  TextColumn get syncError => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ─────────────────────────────────────────────────────────────────────────────
// PHASE 1 — FIELD CREW LOCAL-FIRST TABLES  (schema v3)
// ─────────────────────────────────────────────────────────────────────────────

/// Persists downloaded Field Crew reports with sync tracking.
///
/// [localSyncState] semantics:
///   0 = synced (data matches server)
///   1 = locally_modified (has unsent mutations)
///
/// The record is always inserted/replaced on every successful API fetch.
/// localSyncState is set to 1 by repositories when a mutation is queued.
class FcCachedReports extends Table {
  TextColumn get id => text()(); // Server UUID primary key
  TextColumn get jsonData => text()(); // Full serialised ReportModel JSON
  IntColumn get localSyncState =>
      integer().withDefault(const Constant(0))(); // 0=synced 1=locally_modified
  DateTimeColumn get serverUpdatedAt =>
      dateTime()(); // updatedAt from server payload
  DateTimeColumn get cachedAt =>
      dateTime().withDefault(currentDateAndTime)(); // when cached locally

  @override
  Set<Column> get primaryKey => {id};
}

/// Persists downloaded Field Crew cleanup tasks with sync tracking.
class FcCachedTasks extends Table {
  TextColumn get id => text()(); // Server UUID primary key
  TextColumn get jsonData => text()();
  TextColumn get address => text().nullable()();
  IntColumn get localSyncState => integer().withDefault(const Constant(0))();
  DateTimeColumn get serverUpdatedAt => dateTime()();
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Persists evidence/photo items for a specific report.
/// Only metadata (URL, type, mimetype) — no binary blobs.
class FcCachedEvidences extends Table {
  TextColumn get id => text()(); // Evidence item server UUID
  TextColumn get reportId => text()(); // FK → FcCachedReports.id
  TextColumn get jsonData => text()(); // Full serialised evidence JSON
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Persists LGU and Field Crew notes for a specific report.
/// Only metadata — no large text blobs beyond the note body.
class FcCachedNotes extends Table {
  TextColumn get id => text()(); // Note server UUID
  TextColumn get reportId => text()(); // FK → FcCachedReports.id
  TextColumn get jsonData => text()(); // Full serialised note JSON
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Persists Before/After photo metadata for reports and tasks.
/// Stores URLs/storage paths only — no binary image data.
class FcCachedPhotoMetadata extends Table {
  TextColumn get id => text()(); // Stable client-side ID (entityId + photoType)
  TextColumn get entityId => text()(); // Report ID or Task ID
  TextColumn get entityType => text()(); // 'report' | 'task'
  TextColumn get photoType => text()(); // 'before' | 'after'
  TextColumn get photoUrl => text().nullable()();
  TextColumn get storagePath => text().nullable()();
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tracks the last successful sync cursor per data collection.
/// Used to perform incremental fetches (e.g. since=<lastSyncAt>).
///
/// [collectionKey] is a stable identifier such as 'fc_reports', 'fc_tasks'.
class FcSyncCursors extends Table {
  TextColumn get collectionKey => text()();
  DateTimeColumn get lastSyncAt => dateTime()();
  TextColumn get extraJson =>
      text().nullable()(); // reserved for pagination cursors

  @override
  Set<Column> get primaryKey => {collectionKey};
}

/// Outbox / sync queue for Field Crew mutations that could not be sent
/// immediately due to network conditions.
///
/// [operationType] is one of the stable string constants defined in
/// [FcOutboxOperationType].
///
/// [status] values:
///   'pending'   — not yet attempted
///   'in_flight' — currently being sent (cleared on crash restart → pending)
///   'failed'    — last attempt errored; eligible for retry
///
/// Records are deleted after successful upload in Phase 2.
class FcOutboxItems extends Table {
  // Stable UUID generated at insertion time; used to detect duplicates.
  TextColumn get operationId => text()();
  TextColumn get operationType =>
      text()(); // see FcOutboxOperationType constants
  TextColumn get entityId => text()(); // The entity this mutation targets
  TextColumn get entityType => text()(); // 'report' | 'task' | 'note' | 'photo'
  TextColumn get payloadJson => text()(); // JSON-encoded mutation payload
  // The server's updatedAt at the moment of local mutation; used for
  // optimistic concurrency in Phase 2 conflict resolution.
  TextColumn get baseVersion => text().nullable()(); // ISO-8601 DateTime string
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {operationId};
}

/// Stable string constants for [FcOutboxItems.operationType].
/// Keep in sync with server-side operation handler names.
abstract class FcOutboxOperationType {
  static const String updateReportStatus = 'fc.report.update_status';
  static const String updateLifecycleStage = 'fc.report.update_lifecycle_stage';
  static const String updateReportValidation = 'fc.report.update_validation';
  static const String updateReportDetails = 'fc.report.update_details';
  static const String addNote = 'fc.note.add';
  static const String markTaskComplete = 'fc.task.mark_complete';
  static const String reconcileReportOutcome = 'fc.report.reconcile';
  static const String recordFieldLoad = 'fc.load.record';
  static const String submitTaskFailure = 'fc.task.failure';
  static const String uploadBeforePhoto = 'fc.photo.upload_before';
  static const String uploadAfterPhoto = 'fc.photo.upload_after';
  static const String deletePhoto = 'fc.photo.delete';
}

// ─────────────────────────────────────────────────────────────────────────────
// PHASE 3 — OFFLINE PHOTO TABLE (schema v4)
// ─────────────────────────────────────────────────────────────────────────────

/// Sync status values for [FcLocalPhotos.syncStatus].
abstract class FcLocalPhotoSyncStatus {
  /// Photo is pending upload — local only.
  static const int pending = 0;

  /// Upload is actively in progress.
  static const int inFlight = 1;

  /// Upload succeeded; [remoteUrl] / [remoteId] are populated.
  static const int synced = 2;

  /// Upload failed; retained locally for retry.
  static const int failed = 3;

  /// Deletion was requested while offline; pending DELETE on server.
  static const int pendingDelete = 4;
}

/// Stores the full metadata for a Field Crew before/after photo.
///
/// A row is created when the user picks an image (even offline).
/// The local file is copied into app-internal storage so it survives
/// the image-picker's temp directory being cleared.
///
/// Column notes:
///  • [localPhotoId] — stable client UUID (PK), never changes.
///  • [entityId]     — report or task server UUID.
///  • [entityType]   — 'report' | 'task'.
///  • [photoType]    — 'before' | 'after'.
///  • [localPath]    — absolute path inside app documents dir.
///  • [fileHash]     — SHA-256 hex of the file bytes; used for dedup.
///  • [fileSize]     — bytes; used for UI display and dedup.
///  • [syncStatus]   — see [FcLocalPhotoSyncStatus].
///  • [remoteId]     — server-assigned photo ID (null until synced).
///  • [remoteUrl]    — CDN/storage URL (null until synced).
class FcLocalPhotos extends Table {
  TextColumn get localPhotoId => text()();
  TextColumn get entityId => text()();
  TextColumn get entityType => text()(); // 'report' | 'task'
  TextColumn get photoType => text()(); // 'before' | 'after'
  TextColumn get localPath => text()();
  TextColumn get fileHash => text().nullable()();
  IntColumn get fileSize => integer().withDefault(const Constant(0))();
  IntColumn get syncStatus =>
      integer().withDefault(const Constant(0))(); // see FcLocalPhotoSyncStatus
  TextColumn get remoteId => text().nullable()();
  TextColumn get remoteUrl => text().nullable()();
  TextColumn get lastError => text().nullable()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {localPhotoId};
}

// ─────────────────────────────────────────────────────────────────────────────
// PHASE 4 — ROUTES AND ADDRESSES (schema v5)
// ─────────────────────────────────────────────────────────────────────────────

class FcCachedRoutes extends Table {
  TextColumn get id => text()(); // Route server UUID
  TextColumn get jsonData => text()(); // Full serialised JSON
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('FcCachedAddress')
class FcCachedAddresses extends Table {
  TextColumn get placeId => text()(); // Places API place_id or custom ID
  TextColumn get displayName => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {placeId};
}

// ─────────────────────────────────────────────────────────────────────────────
// DATABASE CLASS
// ─────────────────────────────────────────────────────────────────────────────

@DriftDatabase(
  tables: [
    // Legacy citizen tables
    OfflineReports,
    OfflineTaskUpdates,
    OfflineMedia,
    // Field Crew local-first tables (Phase 1)
    FcCachedReports,
    FcCachedTasks,
    FcCachedEvidences,
    FcCachedNotes,
    FcCachedPhotoMetadata,
    FcSyncCursors,
    FcOutboxItems,
    // Field Crew offline photos (Phase 3)
    FcLocalPhotos,
    // Field Crew routes & addresses (Phase 4)
    FcCachedRoutes,
    FcCachedAddresses,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.createTable(offlineMedia);
        }
        if (from < 3) {
          // Phase 1: Field Crew local-first tables
          await m.createTable(fcCachedReports);
          await m.createTable(fcCachedTasks);
          await m.createTable(fcCachedEvidences);
          await m.createTable(fcCachedNotes);
          await m.createTable(fcCachedPhotoMetadata);
          await m.createTable(fcSyncCursors);
          await m.createTable(fcOutboxItems);
        }
        if (from < 4) {
          // Phase 3: Offline photo table
          await m.createTable(fcLocalPhotos);
        }
        if (from < 5) {
          // Phase 4: Routes and Addresses caching
          await m.createTable(fcCachedRoutes);
          await m.createTable(fcCachedAddresses);
        }
        if (from < 6) {
          await m.addColumn(fcCachedTasks, fcCachedTasks.address);
        }
      },
    );
  }

  // ── Legacy helper methods (citizen flow — unchanged) ──────────────────────

  Future<List<OfflineReport>> getPendingReports() =>
      (select(offlineReports)..where((t) => t.syncStatus.equals(0))).get();

  Future<void> markReportSyncing(int id) =>
      (update(offlineReports)..where((t) => t.id.equals(id))).write(
        const OfflineReportsCompanion(syncStatus: Value(1)),
      );

  Future<void> markReportFailed(int id, String error) =>
      (update(offlineReports)..where((t) => t.id.equals(id))).write(
        OfflineReportsCompanion(
          syncStatus: const Value(2),
          syncError: Value(error),
        ),
      );

  Future<void> deleteReport(int id) =>
      (delete(offlineReports)..where((t) => t.id.equals(id))).go();

  Future<List<OfflineTaskUpdate>> getPendingTaskUpdates() =>
      (select(offlineTaskUpdates)..where((t) => t.syncStatus.equals(0))).get();

  Future<void> markTaskUpdateSyncing(int id) =>
      (update(offlineTaskUpdates)..where((t) => t.id.equals(id))).write(
        const OfflineTaskUpdatesCompanion(syncStatus: Value(1)),
      );

  Future<void> markTaskUpdateFailed(int id, String error) =>
      (update(offlineTaskUpdates)..where((t) => t.id.equals(id))).write(
        OfflineTaskUpdatesCompanion(
          syncStatus: const Value(2),
          syncError: Value(error),
        ),
      );

  Future<void> deleteTaskUpdate(int id) =>
      (delete(offlineTaskUpdates)..where((t) => t.id.equals(id))).go();

  Future<List<OfflineMediaData>> getPendingMedia() =>
      (select(offlineMedia)..where((t) => t.syncStatus.equals(0))).get();

  Future<void> markMediaSyncing(int id) =>
      (update(offlineMedia)..where((t) => t.id.equals(id))).write(
        const OfflineMediaCompanion(syncStatus: Value(1)),
      );

  Future<void> markMediaFailed(int id, String error) =>
      (update(offlineMedia)..where((t) => t.id.equals(id))).write(
        OfflineMediaCompanion(
          syncStatus: const Value(2),
          syncError: Value(error),
        ),
      );

  Future<void> deleteMedia(int id) =>
      (delete(offlineMedia)..where((t) => t.id.equals(id))).go();

  // ── Field Crew cached report helpers ──────────────────────────────────────

  /// Upsert a batch of reports as synced (state = 0).
  Future<void> upsertFcReports(List<FcCachedReportsCompanion> rows) =>
      batch((b) => b.insertAllOnConflictUpdate(fcCachedReports, rows));

  Future<List<FcCachedReport>> getAllFcReports() =>
      (select(fcCachedReports)..orderBy([
            (t) => OrderingTerm(
              expression: t.serverUpdatedAt,
              mode: OrderingMode.desc,
            ),
          ]))
          .get();

  Future<FcCachedReport?> getFcReportById(String id) => (select(
    fcCachedReports,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Mark a locally cached report as modified (state = 1).
  Future<void> markFcReportLocallyModified(String id) =>
      (update(fcCachedReports)..where((t) => t.id.equals(id))).write(
        const FcCachedReportsCompanion(localSyncState: Value(1)),
      );

  Future<void> updateFcReportJson(String id, String newJsonData) =>
      (update(fcCachedReports)..where((t) => t.id.equals(id))).write(
        FcCachedReportsCompanion(jsonData: Value(newJsonData)),
      );

  /// Reset a locally modified report back to synced after a successful push.
  Future<void> markFcReportSynced(String id) =>
      (update(fcCachedReports)..where((t) => t.id.equals(id))).write(
        const FcCachedReportsCompanion(localSyncState: Value(0)),
      );

  Future<List<FcCachedReport>> getLocallyModifiedFcReports() =>
      (select(fcCachedReports)..where((t) => t.localSyncState.equals(1))).get();

  // ── Field Crew cached task helpers ────────────────────────────────────────

  Future<void> upsertFcTasks(List<FcCachedTasksCompanion> rows) =>
      batch((b) => b.insertAllOnConflictUpdate(fcCachedTasks, rows));

  Future<List<FcCachedTask>> getAllFcTasks() =>
      (select(fcCachedTasks)..orderBy([
            (t) => OrderingTerm(
              expression: t.serverUpdatedAt,
              mode: OrderingMode.desc,
            ),
          ]))
          .get();

  Future<FcCachedTask?> getFcTaskById(String id) =>
      (select(fcCachedTasks)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> markFcTaskLocallyModified(String id) =>
      (update(fcCachedTasks)..where((t) => t.id.equals(id))).write(
        const FcCachedTasksCompanion(localSyncState: Value(1)),
      );

  Future<void> markFcTaskSynced(String id) =>
      (update(fcCachedTasks)..where((t) => t.id.equals(id))).write(
        const FcCachedTasksCompanion(localSyncState: Value(0)),
      );

  // ── Field Crew cached evidence helpers ────────────────────────────────────

  Future<void> upsertFcEvidences(
    String reportId,
    List<FcCachedEvidencesCompanion> rows,
  ) => batch((b) => b.insertAllOnConflictUpdate(fcCachedEvidences, rows));

  Future<List<FcCachedEvidence>> getFcEvidencesForReport(String reportId) =>
      (select(
        fcCachedEvidences,
      )..where((t) => t.reportId.equals(reportId))).get();

  Future<void> deleteFcEvidencesForReport(String reportId) => (delete(
    fcCachedEvidences,
  )..where((t) => t.reportId.equals(reportId))).go();

  // ── Field Crew cached note helpers ────────────────────────────────────────

  Future<void> upsertFcNotes(
    String reportId,
    List<FcCachedNotesCompanion> rows,
  ) => batch((b) => b.insertAllOnConflictUpdate(fcCachedNotes, rows));

  Future<List<FcCachedNote>> getFcNotesForReport(String reportId) =>
      (select(fcCachedNotes)..where((t) => t.reportId.equals(reportId))).get();

  Future<void> deleteFcNotesForReport(String reportId) =>
      (delete(fcCachedNotes)..where((t) => t.reportId.equals(reportId))).go();

  // ── Field Crew photo metadata helpers ─────────────────────────────────────

  Future<void> upsertFcPhotoMetadata(FcCachedPhotoMetadataCompanion row) =>
      into(fcCachedPhotoMetadata).insertOnConflictUpdate(row);

  Future<List<FcCachedPhotoMetadataData>> getFcPhotosForEntity(
    String entityId,
    String entityType,
  ) =>
      (select(fcCachedPhotoMetadata)..where(
            (t) =>
                t.entityId.equals(entityId) & t.entityType.equals(entityType),
          ))
          .get();

  Future<void> deleteFcPhotoMetadata(String id) =>
      (delete(fcCachedPhotoMetadata)..where((t) => t.id.equals(id))).go();

  // ── Sync cursor helpers ────────────────────────────────────────────────────

  Future<DateTime?> getFcSyncCursor(String collectionKey) async {
    final row = await (select(
      fcSyncCursors,
    )..where((t) => t.collectionKey.equals(collectionKey))).getSingleOrNull();
    return row?.lastSyncAt;
  }

  Future<void> setFcSyncCursor(String collectionKey, DateTime syncedAt) =>
      into(fcSyncCursors).insertOnConflictUpdate(
        FcSyncCursorsCompanion.insert(
          collectionKey: collectionKey,
          lastSyncAt: syncedAt,
        ),
      );

  // ── Outbox (sync queue) helpers ────────────────────────────────────────────

  Future<void> enqueueOutboxItem(FcOutboxItemsCompanion item) =>
      into(fcOutboxItems).insertOnConflictUpdate(item);

  /// Returns the first pending or failed outbox item for a given
  /// [operationType] + [entityId] combination, used for idempotency.
  Future<FcOutboxItem?> getPendingOutboxItemForEntity({
    required String operationType,
    required String entityId,
  }) =>
      (select(fcOutboxItems)
            ..where(
              (t) =>
                  t.operationType.equals(operationType) &
                  t.entityId.equals(entityId) &
                  (t.status.equals('pending') | t.status.equals('failed')),
            )
            ..limit(1))
          .getSingleOrNull();

  /// Overwrites the [payloadJson] for an existing outbox item.
  Future<void> updateOutboxItemPayload(
    String operationId,
    String newPayloadJson,
  ) => (update(fcOutboxItems)..where((t) => t.operationId.equals(operationId)))
      .write(
        FcOutboxItemsCompanion(
          payloadJson: Value(newPayloadJson),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<List<FcOutboxItem>> getPendingOutboxItems() =>
      (select(fcOutboxItems)
            ..where(
              (t) => t.status.equals('pending') | t.status.equals('failed'),
            )
            ..orderBy([
              (t) =>
                  OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc),
            ]))
          .get();

  Future<List<FcOutboxItem>> getAllOutboxItems() =>
      (select(fcOutboxItems)..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc),
          ]))
          .get();

  Future<void> markOutboxItemInFlight(String operationId) =>
      (update(
        fcOutboxItems,
      )..where((t) => t.operationId.equals(operationId))).write(
        FcOutboxItemsCompanion(
          status: const Value('in_flight'),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> markOutboxItemFailed(String operationId, String error) =>
      (update(
        fcOutboxItems,
      )..where((t) => t.operationId.equals(operationId))).write(
        FcOutboxItemsCompanion(
          status: const Value('failed'),
          lastError: Value(error),
          retryCount: Value(
            // Increment retryCount; we read current value separately if needed.
            // For simplicity we use a raw expression here is not available in
            // Drift companion writes, so callers should pass the incremented count.
            0, // overridden by incrementOutboxRetryCount
          ),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> incrementOutboxRetryCount(
    String operationId,
    String error,
  ) async {
    final existing = await (select(
      fcOutboxItems,
    )..where((t) => t.operationId.equals(operationId))).getSingleOrNull();
    if (existing == null) return;
    await (update(
      fcOutboxItems,
    )..where((t) => t.operationId.equals(operationId))).write(
      FcOutboxItemsCompanion(
        status: const Value('failed'),
        lastError: Value(error),
        retryCount: Value(existing.retryCount + 1),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteOutboxItem(String operationId) => (delete(
    fcOutboxItems,
  )..where((t) => t.operationId.equals(operationId))).go();

  /// Resets any items stuck in 'in_flight' back to 'pending'.
  /// Should be called on app startup to recover from crashes.
  Future<void> resetInFlightOutboxItems() =>
      (update(fcOutboxItems)..where((t) => t.status.equals('in_flight'))).write(
        FcOutboxItemsCompanion(
          status: const Value('pending'),
          updatedAt: Value(DateTime.now()),
        ),
      );

  // ── FcLocalPhotos helpers (Phase 3) ───────────────────────────────────────

  /// Inserts a new local photo record.
  Future<void> insertFcLocalPhoto(FcLocalPhotosCompanion row) =>
      into(fcLocalPhotos).insert(row);

  /// Returns a single local photo by its [localPhotoId].
  Future<FcLocalPhoto?> getFcLocalPhotoById(String localPhotoId) => (select(
    fcLocalPhotos,
  )..where((t) => t.localPhotoId.equals(localPhotoId))).getSingleOrNull();

  /// Returns all local photos for a given entity, ordered oldest-first.
  Future<List<FcLocalPhoto>> getFcLocalPhotosForEntity(
    String entityId,
    String entityType,
  ) =>
      (select(fcLocalPhotos)
            ..where(
              (t) =>
                  t.entityId.equals(entityId) & t.entityType.equals(entityType),
            )
            ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
          .get();

  /// Returns the first photo matching a specific [entityId], [entityType],
  /// and [photoType] whose sync state is NOT [FcLocalPhotoSyncStatus.pendingDelete].
  ///
  /// Used to determine whether a slot is already occupied before adding.
  Future<FcLocalPhoto?> getActiveFcLocalPhoto(
    String entityId,
    String entityType,
    String photoType,
  ) =>
      (select(fcLocalPhotos)
            ..where(
              (t) =>
                  t.entityId.equals(entityId) &
                  t.entityType.equals(entityType) &
                  t.photoType.equals(photoType) &
                  t.syncStatus.isNotIn([FcLocalPhotoSyncStatus.pendingDelete]),
            )
            ..limit(1))
          .getSingleOrNull();

  /// Checks whether a photo with the given [fileHash] already exists for this
  /// entity (deduplication).
  Future<FcLocalPhoto?> getFcLocalPhotoByHash(
    String entityId,
    String entityType,
    String fileHash,
  ) =>
      (select(fcLocalPhotos)
            ..where(
              (t) =>
                  t.entityId.equals(entityId) &
                  t.entityType.equals(entityType) &
                  t.fileHash.equals(fileHash) &
                  t.syncStatus.isNotIn([FcLocalPhotoSyncStatus.pendingDelete]),
            )
            ..limit(1))
          .getSingleOrNull();

  /// Returns all photos pending upload (syncStatus = pending | failed).
  Future<List<FcLocalPhoto>> getPendingFcLocalPhotos() =>
      (select(fcLocalPhotos)
            ..where(
              (t) =>
                  t.syncStatus.equals(FcLocalPhotoSyncStatus.pending) |
                  t.syncStatus.equals(FcLocalPhotoSyncStatus.failed),
            )
            ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
          .get();

  /// Returns all photos pending deletion on the server.
  Future<List<FcLocalPhoto>> getPendingDeleteFcLocalPhotos() =>
      (select(fcLocalPhotos)..where(
            (t) => t.syncStatus.equals(FcLocalPhotoSyncStatus.pendingDelete),
          ))
          .get();

  /// Marks a photo as in-flight (upload in progress).
  Future<void> markFcLocalPhotoInFlight(String localPhotoId) =>
      (update(
        fcLocalPhotos,
      )..where((t) => t.localPhotoId.equals(localPhotoId))).write(
        FcLocalPhotosCompanion(
          syncStatus: const Value(FcLocalPhotoSyncStatus.inFlight),
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// Marks a photo as synced and stores the server-assigned [remoteId] and
  /// [remoteUrl].
  Future<void> markFcLocalPhotoSynced(
    String localPhotoId, {
    String? remoteId,
    String? remoteUrl,
  }) =>
      (update(
        fcLocalPhotos,
      )..where((t) => t.localPhotoId.equals(localPhotoId))).write(
        FcLocalPhotosCompanion(
          syncStatus: const Value(FcLocalPhotoSyncStatus.synced),
          remoteId: Value(remoteId),
          remoteUrl: Value(remoteUrl),
          lastError: const Value(null),
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// Marks a photo upload as failed, incrementing the retry counter.
  Future<void> markFcLocalPhotoFailed(String localPhotoId, String error) async {
    final row = await getFcLocalPhotoById(localPhotoId);
    if (row == null) return;
    await (update(
      fcLocalPhotos,
    )..where((t) => t.localPhotoId.equals(localPhotoId))).write(
      FcLocalPhotosCompanion(
        syncStatus: const Value(FcLocalPhotoSyncStatus.failed),
        lastError: Value(error),
        retryCount: Value(row.retryCount + 1),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Marks a photo as pending deletion on the server.
  /// The row is retained so the delete can be replayed when back online.
  Future<void> markFcLocalPhotoPendingDelete(String localPhotoId) =>
      (update(
        fcLocalPhotos,
      )..where((t) => t.localPhotoId.equals(localPhotoId))).write(
        FcLocalPhotosCompanion(
          syncStatus: const Value(FcLocalPhotoSyncStatus.pendingDelete),
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// Permanently removes a local photo row (after the delete has been
  /// confirmed on the server, or for photos that were never uploaded).
  Future<void> deleteFcLocalPhoto(String localPhotoId) => (delete(
    fcLocalPhotos,
  )..where((t) => t.localPhotoId.equals(localPhotoId))).go();

  /// Resets any FcLocalPhotos stuck in [FcLocalPhotoSyncStatus.inFlight]
  /// back to [FcLocalPhotoSyncStatus.pending] after a crash / restart.
  Future<void> resetInFlightFcLocalPhotos() =>
      (update(
            fcLocalPhotos,
          )..where((t) => t.syncStatus.equals(FcLocalPhotoSyncStatus.inFlight)))
          .write(
            FcLocalPhotosCompanion(
              syncStatus: const Value(FcLocalPhotoSyncStatus.pending),
              updatedAt: Value(DateTime.now()),
            ),
          );

  /// Resets failed photos back to pending with 0 retries.
  Future<void> resetFailedFcLocalPhotos() =>
      (update(fcLocalPhotos)
            ..where((t) => t.syncStatus.equals(FcLocalPhotoSyncStatus.failed)))
          .write(
            FcLocalPhotosCompanion(
              syncStatus: const Value(FcLocalPhotoSyncStatus.pending),
              retryCount: const Value(0),
              lastError: const Value(null),
              updatedAt: Value(DateTime.now()),
            ),
          );
  // ─────────────────────────────────────────────────────────────────────────────
  // PHASE 4 — ROUTES AND ADDRESSES METHODS
  // ─────────────────────────────────────────────────────────────────────────────

  Future<void> cacheFcRoute(String routeId, String json) =>
      into(fcCachedRoutes).insertOnConflictUpdate(
        FcCachedRoutesCompanion(
          id: Value(routeId),
          jsonData: Value(json),
          cachedAt: Value(DateTime.now()),
        ),
      );

  Future<List<FcCachedRoute>> getAllFcRoutes() => select(fcCachedRoutes).get();

  Future<void> cacheFcAddress(
    String placeId,
    String displayName,
    double lat,
    double lng,
  ) => into(fcCachedAddresses).insertOnConflictUpdate(
    FcCachedAddressesCompanion(
      placeId: Value(placeId),
      displayName: Value(displayName),
      latitude: Value(lat),
      longitude: Value(lng),
      cachedAt: Value(DateTime.now()),
    ),
  );

  Future<List<FcCachedAddress>> searchFcAddresses(String query) {
    if (query.isEmpty) return select(fcCachedAddresses).get();
    final lowerQuery = query.toLowerCase();
    return (select(fcCachedAddresses)..where((a) => a.displayName.lower().like('%$lowerQuery%'))).get();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return SqfliteQueryExecutor.inDatabaseFolder(path: file.path);
  });
}
