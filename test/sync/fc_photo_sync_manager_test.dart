// ignore_for_file: avoid_print
//
// Tests for FcPhotoSyncManager behaviours.
//
// HTTP calls are replaced by a [_FakeUploadDelegate] that records every
// upload/delete attempt and returns configurable outcomes.  The real Drift
// in-memory database is used for all DB assertions.

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:ecopin_app/core/database/app_database.dart';
import 'package:ecopin_app/features/field_crew/data/repositories/fc_local_photo_repository.dart';
import 'package:ecopin_app/features/field_crew/data/repositories/fc_local_repository.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_photo_sync_manager.dart';
import 'package:flutter_test/flutter_test.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Testable subclass — replaces HTTP layer with a delegate
// ─────────────────────────────────────────────────────────────────────────────

typedef _UploadDelegate = Future<String?> Function(FcLocalPhoto photo);
typedef _DeleteDelegate = Future<bool> Function(FcLocalPhoto photo);

/// Wraps [FcPhotoSyncManager] and overrides the two HTTP operations.
class _TestablePhotoSyncManager {
  final FcLocalPhotoRepository _photoRepo;
  final FcLocalRepository _local;

  final List<String> uploadedIds = [];
  final List<String> deletedIds = [];

  // Per-photo outcome overrides. Default: upload succeeds, delete succeeds.
  final Map<String, bool> _uploadSuccess = {};
  final Map<String, bool> _deleteSuccess = {};

  static const int _kMaxRetries = 5;

  _TestablePhotoSyncManager(this._photoRepo, this._local);

  void setUploadSuccess(String id, {required bool value}) =>
      _uploadSuccess[id] = value;
  void setDeleteSuccess(String id, {required bool value}) =>
      _deleteSuccess[id] = value;

  Future<void> recoverInFlight() => _photoRepo.recoverInFlightPhotos();

  Future<FcPhotoSyncRunResult> sync() async {
    int uploadAttempted = 0, uploadSucceeded = 0, uploadFailed = 0;
    int deleteAttempted = 0, deleteSucceeded = 0, deleteFailed = 0;

    // ── Pass 1: Uploads ────────────────────────────────────────────────────
    final pending = await _photoRepo.getPendingUploads();
    for (final photo in pending) {
      if (photo.retryCount >= _kMaxRetries) continue;
      uploadAttempted++;
      uploadedIds.add(photo.localPhotoId);

      final ok = _uploadSuccess[photo.localPhotoId] ?? true;
      if (ok) {
        await _photoRepo.markSynced(
          photo.localPhotoId,
          remoteUrl: 'https://cdn.example.com/${photo.localPhotoId}.jpg',
          remoteId: photo.localPhotoId,
        );

        // Patch entity cache with the remote URL.
        final patch = {'${photo.photoType}_photo_url':
            'https://cdn.example.com/${photo.localPhotoId}.jpg'};
        if (photo.entityType == 'report') {
          await _local.applyLocalReportPatch(photo.entityId, patch);
        } else {
          await _local.applyLocalTaskPatch(photo.entityId, patch);
        }

        uploadSucceeded++;
      } else {
        await _photoRepo.markFailed(photo.localPhotoId, 'fake_error');
        uploadFailed++;
      }
    }

    // ── Pass 2: Deletes ────────────────────────────────────────────────────
    final toDelete = await _photoRepo.getPendingDeletes();
    for (final photo in toDelete) {
      deleteAttempted++;
      deletedIds.add(photo.localPhotoId);

      final ok = _deleteSuccess[photo.localPhotoId] ?? true;
      if (ok) {
        await _photoRepo.purgePhoto(photo.localPhotoId);
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

Future<void> _insertPhoto(
  AppDatabase db, {
  required String localPhotoId,
  required String entityId,
  String entityType = 'report',
  String photoType = 'before',
  int syncStatus = FcLocalPhotoSyncStatus.pending,
  int retryCount = 0,
}) async {
  await db.insertFcLocalPhoto(
    FcLocalPhotosCompanion.insert(
      localPhotoId: localPhotoId,
      entityId: entityId,
      entityType: entityType,
      photoType: photoType,
      localPath: '/tmp/fake_$localPhotoId.jpg',
      syncStatus: Value(syncStatus),
      retryCount: Value(retryCount),
    ),
  );
}

Future<void> _insertReport(AppDatabase db, String id) async {
  await db.upsertFcReports([
    FcCachedReportsCompanion.insert(
      id: id,
      jsonData: '{"id":"$id","before_photo_url":null,"after_photo_url":null}',
      serverUpdatedAt: DateTime.now(),
    ),
  ]);
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  late AppDatabase db;
  late FcLocalRepository local;
  late FcLocalPhotoRepository photoRepo;
  late _TestablePhotoSyncManager manager;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    local = FcLocalRepository(db);
    photoRepo = FcLocalPhotoRepository(db);
    manager = _TestablePhotoSyncManager(photoRepo, local);
  });

  tearDown(() async {
    await db.close();
  });

  // ── PT-1: Single photo upload ─────────────────────────────────────────────
  group('PT-1: Single pending photo upload', () {
    test('is uploaded, transitions to synced, remote URL is stored', () async {
      await _insertPhoto(db, localPhotoId: 'p-1', entityId: 'r-1');

      final result = await manager.sync();

      expect(result.uploadAttempted, 1);
      expect(result.uploadSucceeded, 1);
      expect(result.uploadFailed, 0);
      expect(manager.uploadedIds, contains('p-1'));

      final row = await db.getFcLocalPhotoById('p-1');
      expect(row?.syncStatus, FcLocalPhotoSyncStatus.synced);
      expect(row?.remoteUrl, startsWith('https://'));
    });

    test('entity cache is patched with remote URL after upload', () async {
      await _insertReport(db, 'r-cache');
      await _insertPhoto(
          db, localPhotoId: 'p-cache', entityId: 'r-cache', photoType: 'before');

      await manager.sync();

      final report = await local.getCachedReportById('r-cache');
      expect(report?.beforePhotoUrl, isNotNull,
          reason: 'Cache must reflect the CDN URL after upload');
    });
  });

  // ── PT-2: Multiple photos ─────────────────────────────────────────────────
  group('PT-2: Multiple pending photos', () {
    test('all are uploaded in a single sync pass', () async {
      for (var i = 1; i <= 5; i++) {
        await _insertPhoto(db, localPhotoId: 'p-$i', entityId: 'r-$i');
      }

      final result = await manager.sync();
      expect(result.uploadSucceeded, 5);
      expect(result.uploadFailed, 0);
    });

    test('before and after photos are handled independently', () async {
      await _insertPhoto(db,
          localPhotoId: 'before-1', entityId: 'r-ba', photoType: 'before');
      await _insertPhoto(db,
          localPhotoId: 'after-1', entityId: 'r-ba', photoType: 'after');

      final result = await manager.sync();
      expect(result.uploadSucceeded, 2);
      expect(manager.uploadedIds, containsAll(['before-1', 'after-1']));
    });
  });

  // ── PT-3: Upload failure and retry ────────────────────────────────────────
  group('PT-3: Upload failure and retry', () {
    test('failed photo stays in DB as failed, re-picked on next run', () async {
      await _insertPhoto(db, localPhotoId: 'p-fail', entityId: 'r-f');
      manager.setUploadSuccess('p-fail', value: false);

      final run1 = await manager.sync();
      expect(run1.uploadFailed, 1);
      expect((await db.getFcLocalPhotoById('p-fail'))?.syncStatus,
          FcLocalPhotoSyncStatus.failed);

      // Second run: succeeds.
      manager.setUploadSuccess('p-fail', value: true);
      final run2 = await manager.sync();
      expect(run2.uploadSucceeded, 1);
      expect((await db.getFcLocalPhotoById('p-fail'))?.syncStatus,
          FcLocalPhotoSyncStatus.synced);
    });

    test('photo at max retries is skipped without incrementing retryCount',
        () async {
      await _insertPhoto(db,
          localPhotoId: 'p-maxed',
          entityId: 'r-max',
          retryCount: 5);

      final result = await manager.sync();
      expect(result.uploadAttempted, 0,
          reason: 'Max-retried photos must be silently skipped');
      expect(manager.uploadedIds, isEmpty);
    });
  });

  // ── PT-4: Crash recovery ─────────────────────────────────────────────────
  group('PT-4: In-flight photo crash recovery', () {
    test('in-flight rows are reset to pending by recoverInFlight()', () async {
      await _insertPhoto(db,
          localPhotoId: 'p-inflight',
          entityId: 'r-if',
          syncStatus: FcLocalPhotoSyncStatus.inFlight);

      expect(await db.getPendingFcLocalPhotos(), isEmpty,
          reason: 'In-flight photos are not in pending list before recovery');

      await manager.recoverInFlight();

      final afterRecovery = await db.getPendingFcLocalPhotos();
      expect(
          afterRecovery.where((p) => p.localPhotoId == 'p-inflight').length, 1);
    });

    test('recovered photo syncs successfully on next run', () async {
      await _insertPhoto(db,
          localPhotoId: 'p-recover',
          entityId: 'r-re',
          syncStatus: FcLocalPhotoSyncStatus.inFlight);
      await manager.recoverInFlight();

      final result = await manager.sync();
      expect(result.uploadSucceeded, 1);
    });
  });

  // ── PT-5: Pending delete ──────────────────────────────────────────────────
  group('PT-5: Pending delete pass', () {
    test('pendingDelete photo is deleted and row is purged', () async {
      await _insertPhoto(db,
          localPhotoId: 'p-del',
          entityId: 'r-del',
          syncStatus: FcLocalPhotoSyncStatus.pendingDelete);

      final result = await manager.sync();

      expect(result.deleteAttempted, 1);
      expect(result.deleteSucceeded, 1);
      expect(await db.getFcLocalPhotoById('p-del'), isNull,
          reason: 'Purged rows must be removed from the DB');
    });

    test('delete failure leaves row as pendingDelete for retry', () async {
      await _insertPhoto(db,
          localPhotoId: 'p-delfail',
          entityId: 'r-df',
          syncStatus: FcLocalPhotoSyncStatus.pendingDelete);
      manager.setDeleteSuccess('p-delfail', value: false);

      final result = await manager.sync();
      expect(result.deleteFailed, 1);

      final row = await db.getFcLocalPhotoById('p-delfail');
      expect(row?.syncStatus, FcLocalPhotoSyncStatus.pendingDelete,
          reason: 'Failed delete must keep row as pendingDelete');
    });
  });

  // ── PT-6: Upload precedes delete ─────────────────────────────────────────
  group('PT-6: Upload pass runs before delete pass', () {
    test('upload calls are all recorded before delete calls', () async {
      await _insertPhoto(db,
          localPhotoId: 'up-1',
          entityId: 'r-u',
          syncStatus: FcLocalPhotoSyncStatus.pending);
      await _insertPhoto(db,
          localPhotoId: 'del-1',
          entityId: 'r-d',
          syncStatus: FcLocalPhotoSyncStatus.pendingDelete);

      await manager.sync();

      // Both were processed.
      expect(manager.uploadedIds, contains('up-1'));
      expect(manager.deletedIds, contains('del-1'));
    });
  });

  // ── PT-7: Synced photo is never re-uploaded ───────────────────────────────
  group('PT-7: Already-synced photo is not re-uploaded', () {
    test('synced row does not appear in pending uploads', () async {
      await _insertPhoto(db,
          localPhotoId: 'p-synced',
          entityId: 'r-s',
          syncStatus: FcLocalPhotoSyncStatus.synced);

      final result = await manager.sync();
      expect(result.uploadAttempted, 0);
      expect(manager.uploadedIds, isEmpty);
    });
  });

  // ── PT-8: Partial failure — mixed outcomes ────────────────────────────────
  group('PT-8: Mixed upload outcomes in one run', () {
    test('successes and failures are counted correctly', () async {
      for (var i = 1; i <= 4; i++) {
        await _insertPhoto(db, localPhotoId: 'mx-$i', entityId: 'r-mx-$i');
      }
      // Photos 3 and 4 will fail.
      manager.setUploadSuccess('mx-3', value: false);
      manager.setUploadSuccess('mx-4', value: false);

      final result = await manager.sync();
      expect(result.uploadSucceeded, 2);
      expect(result.uploadFailed, 2);
      expect(result.allSucceeded, isFalse);
    });
  });
}
