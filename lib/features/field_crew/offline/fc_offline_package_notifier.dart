import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/features/field_crew/data/repositories/fc_local_repository.dart';
import 'package:ecopin_app/features/field_crew/offline/fc_offline_package.dart';
import 'package:ecopin_app/features/field_crew/offline/fc_offline_package_service.dart';
import 'package:ecopin_app/features/field_crew/providers/fc_local_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kOfflinePreparedAt = 'fc_offline_prepared_at';
const _kOfflineTaskCount = 'fc_offline_task_count';
const _kOfflineReportCount = 'fc_offline_report_count';
const _kOfflineEvidenceCount = 'fc_offline_evidence_count';
const _kOfflineNoteCount = 'fc_offline_note_count';

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final fcOfflinePackageServiceProvider = Provider<FcOfflinePackageService>((ref) {
  final api   = ref.watch(apiClientProvider);
  final local = ref.watch(fcLocalRepositoryProvider);
  return FcOfflinePackageService(api, local);
});

final fcOfflinePackageNotifierProvider =
    NotifierProvider<FcOfflinePackageNotifier, FcOfflinePackageState>(
  FcOfflinePackageNotifier.new,
);

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

/// Drives the offline package preparation flow and exposes real-time progress.
class FcOfflinePackageNotifier extends Notifier<FcOfflinePackageState> {
  final _log = Logger('FcOfflinePackageNotifier');

  @override
  FcOfflinePackageState build() {
    Future.microtask(_initFromPrefs);
    return const FcOfflinePackageState();
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Calculates the storage estimate, then downloads the full package.
  Future<void> prepare() async {
    if (state.isDownloading) {
      _log.warning('[OFFLINE NOTIFIER] prepare() called but already downloading. Ignoring double-tap.');
      return;
    }

    _log.info('[OFFLINE NOTIFIER] Preparation started...');
    final service = ref.read(fcOfflinePackageServiceProvider);

    // ── Phase 1: Estimate ────────────────────────────────────────────────────
    _log.info('[OFFLINE NOTIFIER] Transitioning to estimation phase...');
    state = FcOfflinePackageState(
      phase: FcOfflinePackagePhase.estimating,
      steps: buildInitialSteps(),
    );

    final estimatedBytes = await service.estimateBytes();
    if (estimatedBytes == 0) {
      _log.warning('[OFFLINE NOTIFIER] Estimation returned 0 bytes (tasks might not be loaded yet). Continuing anyway.');
    } else {
      _log.info('[OFFLINE NOTIFIER] Estimation complete: $estimatedBytes bytes');
    }

    // ── Phase 2: Download ────────────────────────────────────────────────────
    _log.info('[OFFLINE NOTIFIER] Transitioning to download phase...');
    state = state.copyWith(
      phase:          FcOfflinePackagePhase.downloading,
      estimatedBytes: estimatedBytes,
    );

    try {
      final result = await service.download(
        onStepProgress: _handleStepProgress,
        onCountUpdate:  _handleCountUpdate,
      );
      _log.info('[OFFLINE NOTIFIER] Download phase completed successfully.');
      state = result;
      _saveToPrefs(result);
    } catch (e, st) {
      _log.severe('[OFFLINE NOTIFIER] Download phase failed', e, st);
      state = state.copyWith(
        phase:        FcOfflinePackagePhase.failed,
        errorMessage: 'Preparation failed: $e',
      );
    }
  }

  /// Resets to idle so the user can retry.
  void reset() {
    state = const FcOfflinePackageState();
    SharedPreferences.getInstance().then((prefs) => _clearPrefs(prefs));
  }

  // ── Private ────────────────────────────────────────────────────────────────

  Future<void> _initFromPrefs() async {
    _log.info('[OFFLINE NOTIFIER] Attempting to initialize state from SharedPreferences...');
    final prefs = await SharedPreferences.getInstance();
    final preparedAtMs = prefs.getInt(_kOfflinePreparedAt);
    
    if (preparedAtMs != null) {
      final preparedAt = DateTime.fromMillisecondsSinceEpoch(preparedAtMs);
      if (DateTime.now().difference(preparedAt).inHours < 24) {
        _log.info('[OFFLINE NOTIFIER] Loaded valid state from SharedPreferences (prepared at $preparedAt)');
        state = state.copyWith(
          phase: FcOfflinePackagePhase.ready,
          preparedAt: preparedAt,
          taskCount: prefs.getInt(_kOfflineTaskCount) ?? 0,
          reportCount: prefs.getInt(_kOfflineReportCount) ?? 0,
          evidenceCount: prefs.getInt(_kOfflineEvidenceCount) ?? 0,
          noteCount: prefs.getInt(_kOfflineNoteCount) ?? 0,
        );
      } else {
        _log.info('[OFFLINE NOTIFIER] Loaded state is stale (older than 24h). Clearing.');
        await _clearPrefs(prefs);
      }
    } else {
      _log.info('[OFFLINE NOTIFIER] No previous offline package state found in SharedPreferences.');
    }
  }

  Future<void> _saveToPrefs(FcOfflinePackageState result) async {
    if (result.preparedAt == null) return;
    
    _log.info('[OFFLINE NOTIFIER] Saving offline package state to SharedPreferences...');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kOfflinePreparedAt, result.preparedAt!.millisecondsSinceEpoch);
    await prefs.setInt(_kOfflineTaskCount, result.taskCount);
    await prefs.setInt(_kOfflineReportCount, result.reportCount);
    await prefs.setInt(_kOfflineEvidenceCount, result.evidenceCount);
    await prefs.setInt(_kOfflineNoteCount, result.noteCount);
    _log.info('[OFFLINE NOTIFIER] State saved successfully.');
  }

  Future<void> _clearPrefs(SharedPreferences prefs) async {
    await prefs.remove(_kOfflinePreparedAt);
    await prefs.remove(_kOfflineTaskCount);
    await prefs.remove(_kOfflineReportCount);
    await prefs.remove(_kOfflineEvidenceCount);
    await prefs.remove(_kOfflineNoteCount);
  }

  void _handleStepProgress(
    String stepLabel, {
    bool completed  = false,
    bool inProgress = false,
    String? error,
  }) {
    final updated = state.steps.map((s) {
      if (s.label != stepLabel) return s;
      return FcDownloadStep(
        label:      s.label,
        completed:  completed,
        inProgress: inProgress && !completed,
        error:      error,
      );
    }).toList();
    state = state.copyWith(steps: updated);
  }

  void _handleCountUpdate({
    int? tasks,
    int? reports,
    int? evidence,
    int? notes,
  }) {
    state = state.copyWith(
      taskCount:     tasks     ?? state.taskCount,
      reportCount:   reports   ?? state.reportCount,
      evidenceCount: evidence  ?? state.evidenceCount,
      noteCount:     notes     ?? state.noteCount,
    );
  }
}
