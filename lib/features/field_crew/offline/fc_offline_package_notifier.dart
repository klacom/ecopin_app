import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/features/field_crew/data/repositories/fc_local_repository.dart';
import 'package:ecopin_app/features/field_crew/offline/fc_offline_package.dart';
import 'package:ecopin_app/features/field_crew/offline/fc_offline_package_service.dart';
import 'package:ecopin_app/features/field_crew/providers/fc_local_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  @override
  FcOfflinePackageState build() => const FcOfflinePackageState();

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Calculates the storage estimate, then downloads the full package.
  Future<void> prepare() async {
    if (state.isDownloading) return; // prevent double-tap

    final service = ref.read(fcOfflinePackageServiceProvider);

    // ── Phase 1: Estimate ────────────────────────────────────────────────────
    state = FcOfflinePackageState(
      phase: FcOfflinePackagePhase.estimating,
      steps: buildInitialSteps(),
    );

    final estimatedBytes = await service.estimateBytes();
    if (estimatedBytes == 0) {
      // Continue anyway — estimate may fail if tasks aren't loaded yet.
    }

    // ── Phase 2: Download ────────────────────────────────────────────────────
    state = state.copyWith(
      phase:          FcOfflinePackagePhase.downloading,
      estimatedBytes: estimatedBytes,
    );

    try {
      final result = await service.download(
        onStepProgress: _handleStepProgress,
        onCountUpdate:  _handleCountUpdate,
      );
      state = result;
    } catch (e) {
      state = state.copyWith(
        phase:        FcOfflinePackagePhase.failed,
        errorMessage: 'Preparation failed: $e',
      );
    }
  }

  /// Resets to idle so the user can retry.
  void reset() => state = const FcOfflinePackageState();

  // ── Private ────────────────────────────────────────────────────────────────

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
