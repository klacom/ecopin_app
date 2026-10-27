import 'dart:async';
import 'fc_sync_settings.dart';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/features/field_crew/providers/fc_local_repository_provider.dart';
import 'package:ecopin_app/features/field_crew/providers/cleanup_tasks_provider.dart';
import 'package:ecopin_app/features/field_crew/providers/field_crew_reports_provider.dart';
import 'package:ecopin_app/features/field_crew/providers/my_route_provider.dart';
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

final fcPendingWritesProvider = StreamProvider<List<String>>(
  (ref) => ref.watch(fcLocalRepositoryProvider).watchPendingWrites(),
);

final fcSyncTriggerProvider = Provider<FcSyncTrigger>((ref) {
  final trigger = FcSyncTrigger(
    syncManager: ref.watch(fcSyncManagerProvider),
    photoSyncManager: ref.watch(fcPhotoSyncManagerProvider),
    stateNotifier: ref.read(fcSyncStateProvider.notifier),
    gate: ref.watch(fcSyncGateProvider),
    onSynced: () {
      ref.invalidate(myCleanupTasksProvider);
      ref.invalidate(fieldCrewReportsProvider);
      ref.invalidate(activeRoutesProvider);
      ref.invalidate(myRouteProvider);
    },
  );
  ref.listen(fcPendingWritesProvider, (_, next) {
    if (next.hasValue) trigger.observeWrites(next.value!);
  }, fireImmediately: true);
  ref.listen(fcSyncSettingsProvider, (_, _) => trigger.requestSync());
  trigger.start();
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
      (lastPhotoResult?.uploadSkipped ?? 0) > 0 ||
      (lastPhotoResult?.deleteFailed ?? 0) > 0;

  String? get resultMessage {
    if (phase != FcSyncPhase.success && phase != FcSyncPhase.partialFailure) {
      return null;
    }
    final saved = lastMutationResult?.succeeded ?? 0;
    final uploads =
        (lastPhotoResult?.uploadFailed ?? 0) +
        (lastPhotoResult?.uploadSkipped ?? 0);
    final removals = lastPhotoResult?.deleteFailed ?? 0;
    final parts = <String>[
      if (saved > 0) '$saved ${saved == 1 ? 'change' : 'changes'} saved.',
      if (uploads > 0)
        '$uploads photo ${uploads == 1 ? 'upload needs' : 'uploads need'} attention.',
      if (removals > 0)
        '$removals photo ${removals == 1 ? 'removal needs' : 'removals need'} attention.',
    ];
    return parts.isEmpty ? null : parts.join(' ');
  }
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
    state = FcSyncState(
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
  final void Function() onSynced;

  static const Duration _kPeriodicInterval = Duration(minutes: 5);
  static const Duration _kConnectivityDebounce = Duration(seconds: 2);

  final _log = Logger('FcSyncTrigger');
  bool _running = false;
  bool _started = false;
  bool _disposed = false;
  bool _rerun = false;
  Set<String> _writes = {};
  Timer? _editTimer;
  Timer? _periodicTimer;
  Timer? _connectivityTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  FcNetworkType _lastNetwork = FcNetworkType.none;

  FcSyncTrigger({
    required this.syncManager,
    required this.photoSyncManager,
    required this.stateNotifier,
    required this.gate,
    required this.onSynced,
  });

  void start() {
    if (_started || _disposed) return;
    _started = true;
    _startPeriodicTimer();
    _subscribeToConnectivity();
    _log.info('FcSyncTrigger started');
  }

  void dispose() {
    _disposed = true;
    _editTimer?.cancel();
    _periodicTimer?.cancel();
    _connectivityTimer?.cancel();
    _connectivitySub?.cancel();
    _log.info('FcSyncTrigger disposed');
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Automatic sync — respects gate (mode + connectivity settings).
  void observeWrites(List<String> fingerprints) {
    final next = fingerprints.toSet();
    final hasNew = next.difference(_writes).isNotEmpty;
    _writes = next;
    if (hasNew) requestSync();
  }

  void requestSync() {
    if (_disposed) return;
    if (_running) {
      _rerun = true;
      return;
    }
    _editTimer?.cancel();
    _editTimer = Timer(const Duration(milliseconds: 150), () {
      unawaited(syncNow());
    });
  }

  Future<FcSyncState?> syncNow() => _checkAndRun(manual: false);
  Future<FcSyncState?> manualCommit() => _checkAndRun(manual: true);

  Future<FcSyncState?> _checkAndRun({required bool manual}) async {
    if (_disposed) return null;
    if (_running) {
      _rerun = true;
      return null;
    }
    _running = true;
    try {
      final decision = manual
          ? await gate.checkManualCommit()
          : await gate.checkAutoSync();
      if (!decision.allowed || _disposed) return null;
      return await _runSync();
    } catch (error) {
      if (!_disposed) stateNotifier.setError('Sync could not start: $error');
      return null;
    } finally {
      _running = false;
      if (_rerun) {
        _rerun = false;
        requestSync();
      }
    }
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  Future<FcSyncState?> _runSync() async {
    stateNotifier.setSyncing();

    FcSyncRunResult mutationResult;
    FcPhotoSyncRunResult photoResult;

    try {
      final ordinaryResult = await syncManager.syncWithBackoff(maxAttempts: 3);
      photoResult = await photoSyncManager.sync();
      // A physical outcome is transmitted only after its local evidence photo
      // has a remote URL. The saved receipt and observation remain immutable.
      final outcomeResult = photoResult.allSucceeded
          ? await syncManager.syncWithBackoff(
              maxAttempts: 3,
              evidenceDependentOnly: true,
            )
          : const FcSyncRunResult(
              total: 0,
              succeeded: 0,
              merged: 0,
              conflicted: 0,
              retryable: 0,
              permanent: 0,
              results: [],
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
      if (!_disposed) stateNotifier.setError(e.toString());
      return null;
    }

    if (_disposed) return null;
    stateNotifier.setResult(mutationResult, photoResult);
    onSynced();

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
    _connectivitySub = Connectivity().onConnectivityChanged.listen(
      networkChanged,
    );
  }

  void networkChanged(List<ConnectivityResult> results) {
    final network = results.contains(ConnectivityResult.wifi)
        ? FcNetworkType.wifi
        : results.contains(ConnectivityResult.mobile)
        ? FcNetworkType.mobile
        : FcNetworkType.none;
    if (network == _lastNetwork) return;
    _lastNetwork = network;
    _connectivityTimer?.cancel();
    if (network != FcNetworkType.none && !_disposed) {
      _connectivityTimer = Timer(_kConnectivityDebounce, () {
        if (_writes.isNotEmpty) unawaited(syncNow());
      });
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
