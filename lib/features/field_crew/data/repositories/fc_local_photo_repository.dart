import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:ecopin_app/core/database/app_database.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// High-level offline-photo operations for the Field Crew flow.
///
/// Responsibilities:
///   1. Copy an image-picker temp file into permanent app-internal storage.
///   2. Compute the file's SHA-256 hash for duplicate detection.
///   3. Check whether the slot (entity + photoType) is already occupied.
///   4. Insert / delete rows in [FcLocalPhotos].
///   5. Provide read helpers the UI needs to render pending photos.
///
/// This class is intentionally **network-free** — it only touches the local
/// Drift database and the device filesystem.  Uploading is handled by the
/// existing report/task repositories via their outbox pattern.
class FcLocalPhotoRepository {
  final AppDatabase _db;
  final _log = Logger('FcLocalPhotoRepository');
  final _uuid = const Uuid();

  FcLocalPhotoRepository(this._db);

  // ─────────────────────────────────────────────────────────────────────────
  // Public API — called by FieldCrewReportRepository / CleanupTaskRepository
  // ─────────────────────────────────────────────────────────────────────────

  /// Persists a picked image for an entity (report or task).
  ///
  /// Steps:
  ///   1. Hash the source file.
  ///   2. Check for duplicate within the same entity/type slot.
  ///   3. Check whether the slot is already occupied (one URL per slot rule).
  ///   4. Copy the file to permanent storage under `<appDocuments>/fc_photos/`.
  ///   5. Insert a [FcLocalPhotos] row with `syncStatus = pending`.
  ///
  /// Returns the stable [localPhotoId] on success.
  ///
  /// Throws [FcPhotoSlotOccupiedException] if a non-pendingDelete photo
  /// already occupies the slot.
  ///
  /// Throws [FcPhotoDuplicateException] if the exact same file content was
  /// already added for this entity+type slot.
  Future<String> addPhoto({
    required String entityId,
    required String entityType, // 'report' | 'task'
    required String photoType, // 'before' | 'after'
    required File sourceFile,
  }) async {
    // 1 — Hash
    final hash = await _hashFile(sourceFile);
    final fileSize = await sourceFile.length();

    // 2 — Duplicate check
    final dup = await _db.getFcLocalPhotoByHash(entityId, entityType, hash);
    if (dup != null) {
      throw FcPhotoDuplicateException(
        'A photo with identical content already exists for this slot '
        '(localPhotoId: ${dup.localPhotoId}).',
      );
    }

    // 3 — Slot occupancy check
    final existing = await _db.getActiveFcLocalPhoto(entityId, entityType, photoType);
    if (existing != null) {
      throw FcPhotoSlotOccupiedException(
        'The $photoType photo slot for entity $entityId is already occupied '
        '(localPhotoId: ${existing.localPhotoId}). Delete it first.',
      );
    }

    // 4 — Copy to permanent storage
    final localPhotoId = _uuid.v4();
    final destPath = await _buildDestPath(localPhotoId, sourceFile.path);
    await _copyFile(sourceFile, destPath);

    // 5 — Insert DB row
    try {
      await _db.insertFcLocalPhoto(
        FcLocalPhotosCompanion.insert(
          localPhotoId: localPhotoId,
          entityId: entityId,
          entityType: entityType,
          photoType: photoType,
          localPath: destPath,
          fileHash: Value(hash),
          fileSize: Value(fileSize),
          syncStatus: const Value(FcLocalPhotoSyncStatus.pending),
        ),
      );
    } catch (e) {
      // Roll back the copied file so we don't leave an orphan.
      await _safeDelete(destPath);
      _log.severe('addPhoto: DB insert failed for $localPhotoId', e);
      rethrow;
    }

    _log.info('addPhoto: added $localPhotoId ($photoType) for $entityType:$entityId');
    return localPhotoId;
  }

  /// Marks a local photo as pending deletion.
  ///
  /// For photos that were **never uploaded** (still `pending` or `failed`),
  /// the row and local file are deleted immediately.
  ///
  /// For photos that are already `synced`, the row is transitioned to
  /// `pendingDelete` so the caller's outbox pattern can issue the server
  /// DELETE when connectivity is restored.
  Future<void> deletePhoto(String localPhotoId) async {
    final row = await _db.getFcLocalPhotoById(localPhotoId);
    if (row == null) {
      _log.warning('deletePhoto: $localPhotoId not found — skipping');
      return;
    }

    if (row.syncStatus == FcLocalPhotoSyncStatus.synced) {
      // Still needs a server DELETE — keep the row but flag it.
      await _db.markFcLocalPhotoPendingDelete(localPhotoId);
      _log.info('deletePhoto: marked $localPhotoId as pendingDelete');
    } else {
      // Was never uploaded (pending / inFlight / failed) — purge entirely.
      await _db.deleteFcLocalPhoto(localPhotoId);
      await _safeDelete(row.localPath);
      _log.info('deletePhoto: hard-deleted $localPhotoId (was never uploaded)');
    }
  }

  /// Permanently removes a photo row and its local file after the server
  /// DELETE has been confirmed.
  Future<void> purgePhoto(String localPhotoId) async {
    final row = await _db.getFcLocalPhotoById(localPhotoId);
    if (row == null) return;
    await _db.deleteFcLocalPhoto(localPhotoId);
    await _safeDelete(row.localPath);
    _log.info('purgePhoto: purged $localPhotoId');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Read helpers (used by UI to render local/pending photos)
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns all non-pendingDelete local photos for an entity, oldest-first.
  Future<List<FcLocalPhoto>> getPhotosForEntity(
    String entityId,
    String entityType,
  ) async {
    final all = await _db.getFcLocalPhotosForEntity(entityId, entityType);
    return all
        .where((p) => p.syncStatus != FcLocalPhotoSyncStatus.pendingDelete)
        .toList();
  }

  /// Returns the single active photo for an entity/type slot, or null.
  Future<FcLocalPhoto?> getActivePhoto(
    String entityId,
    String entityType,
    String photoType,
  ) =>
      _db.getActiveFcLocalPhoto(entityId, entityType, photoType);

  /// Returns all photos pending upload (pending | failed).
  Future<List<FcLocalPhoto>> getPendingUploads() =>
      _db.getPendingFcLocalPhotos();

  /// Returns all photos pending server deletion.
  Future<List<FcLocalPhoto>> getPendingDeletes() =>
      _db.getPendingDeleteFcLocalPhotos();

  // ─────────────────────────────────────────────────────────────────────────
  // Sync state transitions (called by upload/delete push logic in repos)
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> markInFlight(String localPhotoId) =>
      _db.markFcLocalPhotoInFlight(localPhotoId);

  Future<void> markSynced(
    String localPhotoId, {
    String? remoteId,
    String? remoteUrl,
  }) =>
      _db.markFcLocalPhotoSynced(
        localPhotoId,
        remoteId: remoteId,
        remoteUrl: remoteUrl,
      );

  Future<void> markFailed(String localPhotoId, String error) =>
      _db.markFcLocalPhotoFailed(localPhotoId, error);

  /// Resets any in-flight photos back to pending (called on app startup).
  Future<void> recoverInFlightPhotos() =>
      _db.resetInFlightFcLocalPhotos();

  // ─────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns the SHA-256 hex digest of [file]'s bytes.
  Future<String> _hashFile(File file) async {
    final bytes = await file.readAsBytes();
    return sha256.convert(bytes).toString();
  }

  /// Resolves the permanent storage path for a new photo.
  ///
  /// Layout: `<appDocuments>/fc_photos/<localPhotoId>.<ext>`
  Future<String> _buildDestPath(String localPhotoId, String sourcePath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(appDir.path, 'fc_photos'));
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }
    final ext = p.extension(sourcePath).isNotEmpty
        ? p.extension(sourcePath)
        : '.jpg';
    return p.join(photosDir.path, '$localPhotoId$ext');
  }

  /// Copies [source] to [destPath], reading in chunks to avoid
  /// loading large images entirely into memory.
  Future<void> _copyFile(File source, String destPath) async {
    final dest = File(destPath);
    final sink = dest.openWrite();
    try {
      final stream = source.openRead();
      await for (final chunk in stream) {
        sink.add(chunk);
      }
    } finally {
      await sink.flush();
      await sink.close();
    }
  }

  /// Deletes a file at [path] without throwing if it doesn't exist.
  Future<void> _safeDelete(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (e) {
      _log.warning('_safeDelete: could not remove $path — $e');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Exceptions
// ─────────────────────────────────────────────────────────────────────────────

/// Thrown when the before/after photo slot is already occupied.
class FcPhotoSlotOccupiedException implements Exception {
  final String message;
  const FcPhotoSlotOccupiedException(this.message);
  @override
  String toString() => 'FcPhotoSlotOccupiedException: $message';
}

/// Thrown when an identical file (same SHA-256) is added a second time.
class FcPhotoDuplicateException implements Exception {
  final String message;
  const FcPhotoDuplicateException(this.message);
  @override
  String toString() => 'FcPhotoDuplicateException: $message';
}
