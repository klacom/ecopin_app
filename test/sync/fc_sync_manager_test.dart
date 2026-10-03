// ignore_for_file: avoid_print
//
// Acceptance tests for the FcSyncManager-level behaviour.
//
// Rather than subclassing FcSyncManager (which requires a live ApiClient),
// these tests drive the logic through the actual Drift database layer.
// The "HTTP layer" is replaced by a simple Dart function that processes
// outbox items and returns per-operation results directly — exactly what
// FcSyncManager does internally when it receives a server response.
//
// This validates:
//   • FIFO ordering
//   • In-flight marking and crash recovery
//   • Per-op result handling (success, merged, failed, conflict, duplicate, invalid)
//   • Retry counting and max-retry enforcement
//   • Resumable sync (N succeed, M remain pending)
//   • Duplicate submission (idempotency on the client side)


import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:ecopin_app/core/database/app_database.dart';
import 'package:ecopin_app/features/field_crew/data/repositories/fc_local_repository.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_result.dart';
import 'package:flutter_test/flutter_test.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Mini sync engine — processes outbox items against a fake server
// ─────────────────────────────────────────────────────────────────────────────

/// Minimal sync loop that replicates FcSyncManager's core logic without
/// requiring a real ApiClient or network.
class _MiniSyncEngine {
  static const int maxRetries = 5;

  final FcLocalRepository local;

  /// Fake server: map of operationId → FcOpResult to return.
  /// Items not in the map receive 'success' by default.
  final Map<String, FcOpResult> serverResponses = {};

  /// If true, the next batch call throws a network-style exception.
  bool throwNetworkError = false;

  /// All operation payloads received by the "server".
  final List<Map<String, dynamic>> receivedBatches = [];

  _MiniSyncEngine(this.local);

  void enqueue(String operationId, FcOpStatus status,
      {Map<String, dynamic>? serverRecord, String? error}) {
    serverResponses[operationId] = FcOpResult(
      operationId: operationId,
      status: status,
      serverRecord: serverRecord,
      errorMessage: error,
    );
  }

  Future<void> recoverInFlight() => local.recoverInFlightItems();

  Future<FcSyncRunResult> sync() async {
    final allResults = <FcOpResult>[];
    int total = 0, succeeded = 0, merged = 0, conflicted = 0,
        retryable = 0, permanent = 0;

    while (true) {
      final batch = await local.getPendingOutboxItems();
      if (batch.isEmpty) break;

      // Mirror the production guard: skip items already at max retries so
      // permanently-failed rows don't cause an infinite loop.
      final page = batch
          .where((i) => i.retryCount < maxRetries)
          .take(50)
          .toList();
      if (page.isEmpty) break;

      total += page.length;

      if (throwNetworkError) {
        throwNetworkError = false;
        for (final item in page) {
          await local.markOutboxItemFailed(item.operationId, 'network_error');
        }
        retryable += page.length;
        break;
      }

      for (final item in page) {
        receivedBatches.add({
          'operation_id': item.operationId,
          'operation_type': item.operationType,
          'entity_id': item.entityId,
        });
      }

      final pageResults = page.map((item) {
        return serverResponses[item.operationId] ??
            FcOpResult(operationId: item.operationId, status: FcOpStatus.success);
      }).toList();

      for (final result in pageResults) {
        allResults.add(result);
        final item =
            page.where((i) => i.operationId == result.operationId).firstOrNull;
        if (item == null) continue;

        if (result.isTerminalSuccess) {
          await local.deleteOutboxItem(item.operationId);
          result.status == FcOpStatus.merged ? merged++ : succeeded++;
        } else if (result.isTerminalFailure) {
          // Exhaust retry count so this item is filtered out next loop.
          for (int i = item.retryCount; i < maxRetries; i++) {
            await local.markOutboxItemFailed(
                item.operationId, result.errorMessage ?? result.status.name);
          }
          permanent++;
          if (result.status == FcOpStatus.conflict) conflicted++;
        } else {
          // Transient failure.
          final newCount = item.retryCount + 1;
          await local.markOutboxItemFailed(
              item.operationId, result.errorMessage ?? 'failed');
          if (newCount >= maxRetries) {
            permanent++;
          } else {
            retryable++;
          }
        }
      }

      // Stop the loop if there are retryable items — don't advance past them.
      if (pageResults.any((r) => r.isRetryable)) break;
    }

    return FcSyncRunResult(
      total: total,
      succeeded: succeeded,
      merged: merged,
      conflicted: conflicted,
      retryable: retryable,
      permanent: permanent,
      results: allResults,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

Future<void> _enqueue(
  AppDatabase db, {
  required String operationId,
  required String entityId,
  String entityType = 'report',
  String operationType = 'fc.report.update_status',
  String payload = '{"status":"resolved"}',
  String? baseVersion,
  int retryCount = 0,
  String status = 'pending',
}) async {
  await db.enqueueOutboxItem(
    FcOutboxItemsCompanion.insert(
      operationId: operationId,
      operationType: operationType,
      entityId: entityId,
      entityType: entityType,
      payloadJson: payload,
      baseVersion: Value(baseVersion),
      status: Value(status),
      retryCount: Value(retryCount),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  late AppDatabase db;
  late FcLocalRepository local;
  late _MiniSyncEngine engine;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    local = FcLocalRepository(db);
    engine = _MiniSyncEngine(local);
  });

  tearDown(() async {
    await db.close();
  });

  // ── AT-1: Single pending operation ────────────────────────────────────────
  group('AT-1: Single pending operation', () {
    test('is sent, succeeds, and is removed from the outbox', () async {
      await _enqueue(db, operationId: 'op-1', entityId: 'r-1');

      final result = await engine.sync();

      expect(result.total, 1);
      expect(result.succeeded, 1);
      expect(result.retryable, 0);
      expect(engine.receivedBatches.length, 1);
      expect(engine.receivedBatches.first['operation_id'], 'op-1');

      final remaining = await db.getPendingOutboxItems();
      expect(remaining, isEmpty);
    });
  });

  // ── AT-2: Multiple pending operations ─────────────────────────────────────
  group('AT-2: Multiple pending operations', () {
    test('all sent in a single pass and removed on success', () async {
      for (var i = 1; i <= 5; i++) {
        await _enqueue(db, operationId: 'op-$i', entityId: 'r-$i');
      }

      final result = await engine.sync();

      expect(result.total, 5);
      expect(result.succeeded, 5);
      expect(engine.receivedBatches.length, 5);
      expect(await db.getPendingOutboxItems(), isEmpty);
    });

    test('items are sent in FIFO order', () async {
      final ids = ['op-a', 'op-b', 'op-c'];
      for (final id in ids) {
        await _enqueue(db, operationId: id, entityId: 'r-x');
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }

      await engine.sync();

      final sentIds = engine.receivedBatches
          .map((b) => b['operation_id'] as String)
          .toList();
      expect(sentIds, equals(ids));
    });
  });

  // ── AT-3: Network disconnect halfway ──────────────────────────────────────
  group('AT-3: Network disconnect halfway through sync', () {
    test('3 succeed, 3 fail — survivors stay in the outbox', () async {
      for (var i = 1; i <= 6; i++) {
        await _enqueue(db, operationId: 'op-$i', entityId: 'r-$i');
      }

      for (var i = 1; i <= 3; i++) {
        engine.enqueue('op-$i', FcOpStatus.success);
      }
      for (var i = 4; i <= 6; i++) {
        engine.enqueue('op-$i', FcOpStatus.failed, error: 'server_unavailable');
      }

      final result = await engine.sync();
      expect(result.succeeded, 3);
      expect(result.retryable, 3);

      final remaining = await db.getPendingOutboxItems();
      final ids = remaining.map((r) => r.operationId).toSet();
      expect(ids, containsAll(['op-4', 'op-5', 'op-6']));
      expect(ids, isNot(contains('op-1')));
    });

    test('DioException-style flag resets batch to failed and stops loop',
        () async {
      for (var i = 1; i <= 3; i++) {
        await _enqueue(db, operationId: 'op-$i', entityId: 'r-$i');
      }

      engine.throwNetworkError = true;
      final result = await engine.sync();

      expect(result.total, 3);
      expect(result.succeeded, 0);
      expect(result.retryable, 3);
      expect(await db.getPendingOutboxItems(), hasLength(3));
    });
  });

  // ── AT-4: App restart during sync (crash recovery) ────────────────────────
  group('AT-4: App restart — crash recovery', () {
    test('in-flight items reset to pending', () async {
      for (var i = 1; i <= 3; i++) {
        await _enqueue(
            db, operationId: 'op-$i', entityId: 'r-$i', status: 'in_flight');
      }

      expect(await db.getPendingOutboxItems(), isEmpty,
          reason: 'In-flight items are not pending before recovery');

      await engine.recoverInFlight();

      expect(await db.getPendingOutboxItems(), hasLength(3));
    });

    test('recovered items sync successfully', () async {
      for (var i = 1; i <= 2; i++) {
        await _enqueue(
            db, operationId: 'op-$i', entityId: 'r-$i', status: 'in_flight');
      }
      await engine.recoverInFlight();

      final result = await engine.sync();
      expect(result.succeeded, 2);
      expect(await db.getPendingOutboxItems(), isEmpty);
    });
  });

  // ── AT-5: Retry after failed operation ────────────────────────────────────
  group('AT-5: Retry after failed operation', () {
    test('failed item is retried and succeeds on second run', () async {
      await _enqueue(db, operationId: 'op-retry', entityId: 'r-retry');

      engine.enqueue('op-retry', FcOpStatus.failed, error: 'timeout');
      final run1 = await engine.sync();
      expect(run1.retryable, 1);
      expect(run1.succeeded, 0);

      engine.serverResponses.remove('op-retry'); // default → success
      final run2 = await engine.sync();
      expect(run2.succeeded, 1);
      expect(await db.getPendingOutboxItems(), isEmpty);
    });

    test('item with retryCount at max-1 fails permanently on next failure',
        () async {
      await _enqueue(db,
          operationId: 'op-max',
          entityId: 'r-max',
          retryCount: _MiniSyncEngine.maxRetries - 1);

      engine.enqueue('op-max', FcOpStatus.failed, error: 'still_failing');
      final result = await engine.sync();

      // retryCount >= max → counted as permanent, not retryable.
      expect(result.permanent, 1);
      expect(result.retryable, 0);
    });

    test('conflict permanently fails the item', () async {
      await _enqueue(db, operationId: 'op-conflict', entityId: 'r-c');

      engine.enqueue('op-conflict', FcOpStatus.conflict,
          error: 'Unresolvable conflict');
      final result = await engine.sync();

      expect(result.conflicted, 1);
      expect(result.permanent, 1);

      final items = await db.getAllOutboxItems();
      final item = items.where((i) => i.operationId == 'op-conflict').firstOrNull;
      expect(item, isA<FcOutboxItem>());
      expect(item!.status, 'failed');
    });
  });

  // ── AT-6: Duplicate submission (idempotency) ──────────────────────────────
  group('AT-6: Duplicate submission — idempotency', () {
    test('server duplicate result removes the outbox entry', () async {
      await _enqueue(db, operationId: 'op-dup', entityId: 'r-d');

      engine.enqueue('op-dup', FcOpStatus.duplicate);
      final result = await engine.sync();

      expect(result.succeeded, 1,
          reason: 'duplicate counts as terminal success');
      expect(await db.getPendingOutboxItems(), isEmpty);
    });

    test('outbox is empty on the second run — no HTTP calls made', () async {
      await _enqueue(db, operationId: 'op-safe', entityId: 'r-s');

      await engine.sync();
      engine.receivedBatches.clear();

      final run2 = await engine.sync();
      expect(run2.total, 0);
      expect(engine.receivedBatches, isEmpty);
    });
  });

  // ── AT-7: Resumable sync ──────────────────────────────────────────────────
  group('AT-7: Resumable sync — 40 ops, 17 succeed first run', () {
    test('17 removed, 23 remain, second run clears all', () async {
      for (var i = 1; i <= 40; i++) {
        await _enqueue(db, operationId: 'op-$i', entityId: 'r-$i');
      }

      for (var i = 1; i <= 17; i++) {
        engine.enqueue('op-$i', FcOpStatus.success);
      }
      for (var i = 18; i <= 40; i++) {
        engine.enqueue('op-$i', FcOpStatus.failed, error: 'timeout');
      }

      final run1 = await engine.sync();
      expect(run1.succeeded, 17);
      expect(run1.retryable, 23);
      expect(await db.getPendingOutboxItems(), hasLength(23));

      // Second run — clear overrides so all return success.
      engine.serverResponses.clear();
      final run2 = await engine.sync();
      expect(run2.succeeded, 23);
      expect(await db.getPendingOutboxItems(), isEmpty);
    });
  });

  // ── AT-8: Merged result ───────────────────────────────────────────────────
  group('AT-8: Merged result (OCC field-authority resolution)', () {
    test('merged counts as terminal success and removes the outbox entry',
        () async {
      await _enqueue(
        db,
        operationId: 'op-merge',
        entityId: 'r-m',
        baseVersion: DateTime.now()
            .subtract(const Duration(hours: 1))
            .toIso8601String(),
      );

      engine.enqueue('op-merge', FcOpStatus.merged,
          serverRecord: {'id': 'r-m', 'status': 'resolved'});
      final result = await engine.sync();

      expect(result.merged, 1);
      expect(result.succeeded, 0);
      expect(await db.getPendingOutboxItems(), isEmpty);
    });
  });

  // ── AT-9: Invalid operation ───────────────────────────────────────────────
  group('AT-9: Invalid operation (bad payload)', () {
    test('invalid status permanently fails and is not retried', () async {
      await _enqueue(
        db,
        operationId: 'op-bad',
        entityId: 'r-b',
        operationType: 'fc.photo.upload_before',
      );

      engine.enqueue('op-bad', FcOpStatus.invalid,
          error: 'Photo ops must use dedicated endpoint');
      final result = await engine.sync();

      expect(result.permanent, 1);

      final items = await db.getAllOutboxItems();
      final item = items.where((i) => i.operationId == 'op-bad').firstOrNull;
      expect(item, isA<FcOutboxItem>());
      expect(item!.status, 'failed');
    });
  });

  // ── AT-10: FcOpResult helper properties ──────────────────────────────────
  group('AT-10: FcOpResult helper properties', () {
    test('isTerminalSuccess covers success, merged, duplicate', () {
      expect(FcOpResult(operationId: 'x', status: FcOpStatus.success).isTerminalSuccess, isTrue);
      expect(FcOpResult(operationId: 'x', status: FcOpStatus.merged).isTerminalSuccess, isTrue);
      expect(FcOpResult(operationId: 'x', status: FcOpStatus.duplicate).isTerminalSuccess, isTrue);
      expect(FcOpResult(operationId: 'x', status: FcOpStatus.failed).isTerminalSuccess, isFalse);
    });

    test('isTerminalFailure covers conflict and invalid', () {
      expect(FcOpResult(operationId: 'x', status: FcOpStatus.conflict).isTerminalFailure, isTrue);
      expect(FcOpResult(operationId: 'x', status: FcOpStatus.invalid).isTerminalFailure, isTrue);
      expect(FcOpResult(operationId: 'x', status: FcOpStatus.failed).isTerminalFailure, isFalse);
    });

    test('isRetryable is true only for failed', () {
      expect(FcOpResult(operationId: 'x', status: FcOpStatus.failed).isRetryable, isTrue);
      expect(FcOpResult(operationId: 'x', status: FcOpStatus.success).isRetryable, isFalse);
    });

    test('FcOpResult.fromJson parses all status strings', () {
      for (final entry in {
        'success': FcOpStatus.success,
        'merged': FcOpStatus.merged,
        'conflict': FcOpStatus.conflict,
        'duplicate': FcOpStatus.duplicate,
        'failed': FcOpStatus.failed,
        'invalid': FcOpStatus.invalid,
        'unknown_value': FcOpStatus.failed, // fallback
      }.entries) {
        final r = FcOpResult.fromJson({
          'operation_id': 'id',
          'status': entry.key,
          'server_record': null,
          'error_message': null,
        });
        expect(r.status, entry.value,
            reason: '${entry.key} should parse to ${entry.value}');
      }
    });
  });
}
