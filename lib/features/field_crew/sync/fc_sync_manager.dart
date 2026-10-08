import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:ecopin_app/core/constants/api_constants.dart';
import 'package:ecopin_app/core/database/app_database.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/features/field_crew/data/repositories/fc_local_repository.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_result.dart';
import 'package:logging/logging.dart';

/// Maximum outbox operations sent in a single HTTP request.
const int _kBatchSize = 50;

/// After this many cumulative retries an outbox item is permanently failed
/// and will not be picked up again without manual intervention.
const int _kMaxRetries = 5;

/// Minimum delay before the first retry (doubles each attempt — exponential
/// back-off).  Only used when [FcSyncManager.syncWithBackoff] is called.
const Duration _kBaseBackoff = Duration(seconds: 2);

/// [FcSyncManager] drains the [FcOutboxItems] table by sending batched
/// requests to `POST /api/fc/sync/batch`.
///
/// Design properties
/// ─────────────────
/// • **FIFO ordering** — items are fetched oldest-first, so the server sees
///   mutations in the same order they were applied locally.
///
/// • **Resumable** — if 40 operations exist and only 17 succeed, the 23
///   remaining stay in the outbox with `status = 'pending'` and are picked up
///   on the next run.
///
/// • **Idempotent retries** — each item carries a stable `operationId` UUID.
///   The server deduplicates on that key, so replaying an already-applied
///   operation never causes a double-write.
///
/// • **Crash recovery** — any item stuck in `in_flight` at startup is reset
///   to `pending` via [recoverInFlight], which must be called once at app
///   launch before the first sync attempt.
///
/// • **Backoff** — [syncWithBackoff] retries with exponential back-off
///   (2 s → 4 s → 8 s … capped at 64 s) on transient network failures.
///
/// • **Permanent failure** — items that exceed [_kMaxRetries] are moved to
///   `failed` status and are no longer retried automatically.
class FcSyncManager {
  final ApiClient _api;
  final FcLocalRepository _local;
  final _log = Logger('FcSyncManager');

  FcSyncManager(this._api, this._local);

  // ── Public interface ───────────────────────────────────────────────────────

  /// Resets items stuck in `in_flight` back to `pending`.
  ///
  /// Must be called once at app startup before the first sync.
  Future<void> recoverInFlight() async {
    await _local.recoverInFlightItems();
    _log.info('recoverInFlight: reset in-flight outbox items to pending');
  }

  /// Drains all pending outbox items in FIFO batches.
  ///
  /// Returns an aggregated [FcSyncRunResult] describing what happened.
  /// Never throws — network errors are caught and recorded in the outbox.
  Future<FcSyncRunResult> sync({bool reconciliationOnly = false}) async {
    final allResults = <FcOpResult>[];
    int total = 0,
        succeeded = 0,
        merged = 0,
        conflicted = 0,
        retryable = 0,
        permanent = 0;

    while (true) {
      // Fetch the next batch of pending items.
      final batch = await _local.getPendingOutboxItems();
      if (batch.isEmpty) break;

      // Skip items already at max retries — they are permanently failed and
      // will never be retried.  Without this guard, the loop would spin
      // forever re-processing a permanently-failed item that is still returned
      // by getPendingOutboxItems (which selects status='pending' | 'failed').
      final page = <FcOutboxItem>[];
      for (final item in batch) {
        if (item.retryCount >= _kMaxRetries ||
            item.operationType.startsWith('fc.photo.')) {
          continue;
        }
        final isReconciliation =
            item.operationType == FcOutboxOperationType.reconcileReportOutcome;
        if (isReconciliation != reconciliationOnly) continue;
        if (isReconciliation) {
          final payload = jsonDecode(item.payloadJson) as Map<String, dynamic>;
          final refs = (payload['evidence_refs'] as List).cast<String>();
          if (await _local.resolveOutcomeEvidence(refs) == null) break;
        }
        page.add(item);
        if (page.length == _kBatchSize) break;
      }
      if (page.isEmpty) break;

      total += page.length;

      // Mark every item in this page as in-flight so a crash doesn't re-send
      // them before we finish processing the response.
      for (final item in page) {
        await _local.markOutboxItemInFlight(item.operationId);
      }

      List<FcOpResult> pageResults;
      try {
        pageResults = await _sendBatch(page);
      } on DioException catch (e) {
        if (_isNetworkError(e)) {
          // Transient failure — reset to pending so they can be retried.
          _log.warning(
            'syncBatch: network error, resetting batch to pending: ${e.message}',
          );
          for (final item in page) {
            await _local.markOutboxItemFailed(
              item.operationId,
              e.message ?? 'network_error',
            );
          }
          retryable += page.length;
          // Stop the loop; remaining items were not touched.
          break;
        } else {
          // Non-network 4xx/5xx — treat as transient server-side failure.
          final msg = 'HTTP ${e.response?.statusCode}: ${e.message}';
          _log.warning('syncBatch: server error: $msg');
          for (final item in page) {
            await _local.markOutboxItemFailed(item.operationId, msg);
          }
          retryable += page.length;
          break;
        }
      } catch (e) {
        // Unexpected error — fail the batch.
        _log.severe('syncBatch: unexpected error', e);
        for (final item in page) {
          await _local.markOutboxItemFailed(item.operationId, e.toString());
        }
        retryable += page.length;
        break;
      }

      // Process per-operation results.
      for (final result in pageResults) {
        allResults.add(result);
        await _applyResult(result, page);

        if (result.isTerminalSuccess) {
          if (result.status == FcOpStatus.merged) {
            merged++;
          } else {
            succeeded++;
          }
          if (result.status == FcOpStatus.contested ||
              result.status == FcOpStatus.verificationRequired) {
            conflicted++;
          }
        } else if (result.isTerminalFailure) {
          permanent++;
          conflicted += (result.status == FcOpStatus.conflict) ? 1 : 0;
        } else if (result.isRetryable) {
          retryable++;
        }
      }

      // Handle items not covered by the server response (missing result).
      final respondedIds = pageResults.map((r) => r.operationId).toSet();
      for (final item in page) {
        if (!respondedIds.contains(item.operationId)) {
          _log.warning(
            'syncBatch: no result for ${item.operationId} — resetting to pending',
          );
          await _local.markOutboxItemFailed(
            item.operationId,
            'no_result_in_response',
          );
          retryable++;
        }
      }

      // If every item in this page was terminal, continue to the next batch.
      // If any were retryable we stop — we don't want to advance past failures.
      final anyRetryable = pageResults.any((r) => r.isRetryable);
      if (anyRetryable) break;
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

  /// Wraps [sync] with exponential back-off on transient failures.
  ///
  /// Retries up to [maxAttempts] times (default 3).  Each delay doubles
  /// from [_kBaseBackoff], capped at 64 seconds.
  Future<FcSyncRunResult> syncWithBackoff({
    int maxAttempts = 3,
    bool reconciliationOnly = false,
  }) async {
    FcSyncRunResult? last;
    Duration delay = _kBaseBackoff;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      last = await sync(reconciliationOnly: reconciliationOnly);
      if (last.retryable == 0) return last;

      if (attempt < maxAttempts) {
        _log.info(
          'syncWithBackoff: attempt $attempt had ${last.retryable} retryable '
          'items — waiting ${delay.inSeconds}s before retry',
        );
        await Future<void>.delayed(delay);
        delay = Duration(seconds: (delay.inSeconds * 2).clamp(2, 64));
      }
    }

    return last!;
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  /// Sends one batch of outbox items to the backend.
  Future<List<FcOpResult>> _sendBatch(List<FcOutboxItem> items) async {
    final ops = await Future.wait(items.map(_outboxItemToPayload));

    final response = await _api.dioClient.post(
      ApiConstants.fcSyncBatch,
      data: {'operations': ops},
      options: Options(
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    final raw = response.data;
    if (raw == null || raw['results'] is! List) {
      throw const FormatException(
        'Invalid batch response: missing results array',
      );
    }

    return (raw['results'] as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(FcOpResult.fromJson)
        .toList();
  }

  /// Converts a Drift [FcOutboxItem] to the JSON payload expected by the
  /// backend.
  Future<Map<String, dynamic>> _outboxItemToPayload(FcOutboxItem item) async {
    final payload = jsonDecode(item.payloadJson) as Map<String, dynamic>;
    if (item.operationType == FcOutboxOperationType.reconcileReportOutcome) {
      final refs = (payload['evidence_refs'] as List).cast<String>();
      final remoteRefs = await _local.resolveOutcomeEvidence(refs);
      if (remoteRefs == null) {
        throw StateError('Outcome photo has not uploaded yet');
      }
      payload['evidence_refs'] = remoteRefs;
    }
    return {
      'operation_id': item.operationId,
      'operation_type': item.operationType,
      'entity_id': item.entityId,
      'entity_type': item.entityType,
      'payload': payload,
      if (item.baseVersion != null)
        'base_version': int.tryParse(item.baseVersion!),
    };
  }

  /// Applies a server-side result back to the local outbox.
  Future<void> _applyResult(FcOpResult result, List<FcOutboxItem> page) async {
    final item = page
        .where((i) => i.operationId == result.operationId)
        .firstOrNull;
    if (item == null) return;

    if (result.isTerminalSuccess) {
      // Delete the outbox entry — it's been accepted by the server.
      await _local.deleteOutboxItem(item.operationId);

      // If the server returned an authoritative server_record, patch the local
      // cache so the UI sees the server's version immediately.
      if (result.serverRecord != null) {
        await _patchLocalCache(item, result.serverRecord!);
      }
      _log.fine(
        'Applied ${item.operationType} for ${item.entityId}: $result.status',
      );
    } else if (result.isTerminalFailure) {
      // Conflict or invalid — permanently fail; do not retry.
      await _local.markOutboxItemFailed(
        item.operationId,
        result.errorMessage ?? result.status.name,
      );
      // Bump retry count to max so the item is not picked up again.
      for (int i = item.retryCount; i < _kMaxRetries; i++) {
        await _local.markOutboxItemFailed(
          item.operationId,
          'terminal_${result.status.name}',
        );
      }
      _log.warning(
        'Terminal failure for ${item.operationId} '
        '(${item.operationType}): $result.status — $result.errorMessage',
      );
    } else {
      // Transient failure — increment retry counter.
      final newCount = item.retryCount + 1;
      if (newCount >= _kMaxRetries) {
        // Exceeded max retries — permanently fail.
        await _local.markOutboxItemFailed(
          item.operationId,
          'max_retries_exceeded: $result.errorMessage',
        );
        _log.warning(
          'Max retries exceeded for ${item.operationId} '
          '(${item.operationType}) — permanently failed',
        );
      } else {
        await _local.markOutboxItemFailed(
          item.operationId,
          result.errorMessage ?? 'server_failed',
        );
        _log.fine(
          'Retryable failure for ${item.operationId} '
          '(attempt $newCount/$_kMaxRetries)',
        );
      }
    }
  }

  /// Patches the local Drift cache with the authoritative server record
  /// returned after a successful operation.
  Future<void> _patchLocalCache(
    FcOutboxItem item,
    Map<String, dynamic> serverRecord,
  ) async {
    try {
      if (item.entityType == 'report') {
        await _local.applyLocalReportPatch(item.entityId, serverRecord);
        await _local.markFcReportSynced(item.entityId);
      } else if (item.entityType == 'task') {
        await _local.applyLocalTaskPatch(item.entityId, serverRecord);
        await _local.markFcTaskSynced(item.entityId);
      }
    } catch (e) {
      // Non-fatal — UI will refresh on next poll.
      _log.warning('_patchLocalCache failed for ${item.entityId}: $e');
    }
  }

  bool _isNetworkError(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError ||
        (e.error is SocketException);
  }
}
