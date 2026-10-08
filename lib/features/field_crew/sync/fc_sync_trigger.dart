import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/features/field_crew/providers/fc_local_repository_provider.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_photo_sync_manager.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_gate.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_manager.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final fcSyncManagerProvider = Provider<FcSyncManager>((ref) {
  final api = ref.watch(apiClientProvider);
  final local = ref.watch(fcLocalRepositoryProvider);
  return FcSyncManager(api, local);
});

final fcPhotoSyncManagerProvider = Provider<FcPhotoSyncManager>((ref) {
  final api = ref.watch(apiClientProvider);
  final photoRepo = ref.watch(fcLocalPhotoRepositoryProvider);
  final local = ref.watch(fcLocalRepositoryProvider);
  return FcPhotoSyncManager(api, photoRepo, local);
});

final fcSyncTriggerProvider = Provider<FcSyncTrigger>((ref) {
  final trigger = FcSyncTrigger(
    syncManager: ref.watch(fcSyncManagerProvider),
    photoSyncManager: ref.watch(fcPhotoSyncManagerProvider),
    stateNotifier: ref.read(fcSyncStateProvider.notifier),
    gate: ref.watch(fcSyncGateProvider),
  );
  ref.onDispose(trigger.dispose);
  return trigger;
});

// ── FcSyncState ───────────────────────────────────────────────────────────────

enum FcSyncPhase { idle, syncing, success, partialFailure, error }

class FcSyncState {
  final FcSyncPhase phase;
  final FcSyncRunResult? lastMutationResult;
  final FcPhotoSyncRunResult? lastPhotoResult;
  final String? errorMessage;
  final DateTime? lastSyncAt;
  final List<FcConflictEvent> conflictEvents;

  const FcSyncState({
    this.phase = FcSyncPhase.idle,
    this.lastMutationResult,
    this.lastPhotoResult,
    this.errorMessage,
    this.lastSyncAt,
    this.conflictEvents = const [],
  });

  FcSyncState copyWith({
    FcSyncPhase? phase,
    FcSyncRunResult? lastMutationResult,
    FcPhotoSyncRunResult? lastPhotoResult,
    String? errorMessage,
    DateTime? lastSyncAt,
    List<FcConflictEvent>? conflictEvents,
  }) => FcSyncState(
    phase: phase ?? this.phase,
    lastMutationResult: lastMutationResult ?? this.lastMutationResult,
    lastPhotoResult: lastPhotoResult ?? this.lastPhotoResult,
    errorMessage: errorMessage ?? this.errorMessage,
    lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    conflictEvents: conflictEvents ?? this.conflictEvents,
  );

  bool get hasPendingWork =>
      (lastMutationResult?.retryable ?? 0) > 0 ||
      (lastPhotoResult?.uploadFailed ?? 0) > 0 ||
      (lastPhotoResult?.deleteFailed ?? 0) > 0;
}

final fcSyncStateProvider = NotifierProvider<FcSyncStateNotifier, FcSyncState>(
  FcSyncStateNotifier.new,
);

class FcSyncStateNotifier extends Notifier<FcSyncState> {
  @override
  FcSyncState build() => const FcSyncState();

  void setSyncing() => state = state.copyWith(phase: FcSyncPhase.syncing);

  void setResult(FcSyncRunResult mutation, FcPhotoSyncRunResult photo) {
    final allGood = mutation.allSucceeded && photo.allSucceeded;
    state = state.copyWith(
      phase: allGood ? FcSyncPhase.success : FcSyncPhase.partialFailure,
      lastMutationResult: mutation,
      lastPhotoResult: photo,
      errorMessage: null,
      lastSyncAt: DateTime.now(),
      conflictEvents: mutation.conflictEvents,
    );
  }

  void setError(String message) =>
      state = state.copyWith(phase: FcSyncPhase.error, errorMessage: message);

  void setIdle() => state = state.copyWith(phase: FcSyncPhase.idle);
}

// ── FcSyncTrigger ─────────────────────────────────────────────────────────────

class FcSyncTrigger {
  final FcSyncManager syncManager;
  final FcPhotoSyncManager photoSyncManager;
  final FcSyncStateNotifier stateNotifier;
  final FcSyncGate gate;

  static const Duration _kPeriodicInterval = Duration(minutes: 5);
  static const Duration _kConnectivityDebounce = Duration(seconds: 2);

  final _log = Logger('FcSyncTrigger');
  bool _running = false;
  Timer? _periodicTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _wasOnline = true;

  FcSyncTrigger({
    required this.syncManager,
    required this.photoSyncManager,
    required this.stateNotifier,
    required this.gate,
  });

  void start() {
    _startPeriodicTimer();
    _subscribeToConnectivity();
    _log.info('FcSyncTrigger started');
  }

  void dispose() {
    _periodicTimer?.cancel();
    _connectivitySub?.cancel();
    _log.info('FcSyncTrigger disposed');
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Automatic sync — respects gate (mode + connectivity settings).
  Future<FcSyncState?> syncNow() async {
    if (_running) return null;

    final decision = await gate.checkAutoSync();
    if (!decision.allowed) {
      _log.fine('syncNow: blocked — ${decision.reason}');
      return null;
    }

    return _runSync();
  }

  /// Manual commit — bypasses auto-sync mode check but still respects
  /// offlineOnly and no-network blocks.
  Future<FcSyncState?> manualCommit() async {
    if (_running) return null;

    final decision = await gate.checkManualCommit();
    if (!decision.allowed) {
      _log.info('manualCommit: blocked — ${decision.reason}');
      return null;
    }

    return _runSync();
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  Future<FcSyncState?> _runSync() async {
    _running = true;
    stateNotifier.setSyncing();

    FcSyncRunResult mutationResult;
    FcPhotoSyncRunResult photoResult;

    try {
      final ordinaryResult = await syncManager.syncWithBackoff(maxAttempts: 3);
      photoResult = await photoSyncManager.sync();
      // A physical outcome is transmitted only after its local evidence photo
      // has a remote URL. The saved receipt and observation remain immutable.
      final outcomeResult = await syncManager.syncWithBackoff(
        maxAttempts: 3,
        reconciliationOnly: true,
      );
      mutationResult = FcSyncRunResult(
        total: ordinaryResult.total + outcomeResult.total,
        succeeded: ordinaryResult.succeeded + outcomeResult.succeeded,
        merged: ordinaryResult.merged + outcomeResult.merged,
        conflicted: ordinaryResult.conflicted + outcomeResult.conflicted,
        retryable: ordinaryResult.retryable + outcomeResult.retryable,
        permanent: ordinaryResult.permanent + outcomeResult.permanent,
        results: [...ordinaryResult.results, ...outcomeResult.results],
      );
    } catch (e) {
      _log.severe('FcSyncTrigger: unhandled sync error', e);
      stateNotifier.setError(e.toString());
      _running = false;
      return null;
    }

    _running = false;
    stateNotifier.setResult(mutationResult, photoResult);

    return FcSyncState(
      phase: (mutationResult.allSucceeded && photoResult.allSucceeded)
          ? FcSyncPhase.success
          : FcSyncPhase.partialFailure,
      lastMutationResult: mutationResult,
      lastPhotoResult: photoResult,
      lastSyncAt: DateTime.now(),
      conflictEvents: mutationResult.conflictEvents,
    );
  }

  void _startPeriodicTimer() {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(_kPeriodicInterval, (_) async {
      await syncNow();
    });
  }

  void _subscribeToConnectivity() {
    _connectivitySub?.cancel();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((
      results,
    ) async {
      final isOnline = !results.contains(ConnectivityResult.none);
      if (isOnline && !_wasOnline) {
        await Future<void>.delayed(_kConnectivityDebounce);
        await syncNow();
      }
      _wasOnline = isOnline;
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
