// ─────────────────────────────────────────────────────────────────────────────
// fc_offline_package.dart
//
// Data model for the Field Crew Offline Work Package.
//
// An Offline Work Package is the complete set of data a crew member needs to
// operate without network access during a field assignment.  It is downloaded
// intentionally before leaving the depot — not accumulated passively through
// normal app usage.
//
// What is included
// ────────────────
//   • Assigned cleanup tasks (assigned to the current user)
//   • All reports linked to those tasks (via clusterId or reportIds)
//   • Evidence metadata for each report (URLs, types — no full-res binaries)
//   • Agency response notes for each report
//   • Issue-type reference data
//   • (Optionally) compressed thumbnails of existing Before/After photos
//
// What is intentionally excluded
// ───────────────────────────────
//   • Reports not related to assigned tasks (the entire dataset)
//   • Full-resolution photo binaries that are already on the server
//   • Other users' tasks
//   • Admin/analytics data
// ─────────────────────────────────────────────────────────────────────────────

/// Phase of the offline package download.
enum FcOfflinePackagePhase {
  idle,
  estimating,   // calculating storage requirement
  downloading,  // actively fetching data
  ready,        // all data cached; safe to go offline
  failed,       // download encountered a fatal error
}

/// One step in the download sequence shown to the user.
class FcDownloadStep {
  final String label;
  final bool completed;
  final bool inProgress;
  final String? error;

  const FcDownloadStep({
    required this.label,
    this.completed  = false,
    this.inProgress = false,
    this.error,
  });

  FcDownloadStep copyWith({
    bool? completed,
    bool? inProgress,
    String? error,
  }) =>
      FcDownloadStep(
        label:      label,
        completed:  completed  ?? this.completed,
        inProgress: inProgress ?? this.inProgress,
        error:      error,
      );
}

/// Immutable snapshot of the offline package state.
class FcOfflinePackageState {
  final FcOfflinePackagePhase phase;

  // Storage estimate (bytes) — calculated during the estimating phase.
  final int estimatedBytes;

  // Counts discovered during download.
  final int taskCount;
  final int reportCount;
  final int evidenceCount;
  final int noteCount;

  // Download progress steps (ordered).
  final List<FcDownloadStep> steps;

  // When the last successful package was prepared.
  final DateTime? preparedAt;

  final String? errorMessage;

  const FcOfflinePackageState({
    this.phase         = FcOfflinePackagePhase.idle,
    this.estimatedBytes = 0,
    this.taskCount     = 0,
    this.reportCount   = 0,
    this.evidenceCount = 0,
    this.noteCount     = 0,
    this.steps         = const [],
    this.preparedAt,
    this.errorMessage,
  });

  bool get isReady     => phase == FcOfflinePackagePhase.ready;
  bool get isDownloading =>
      phase == FcOfflinePackagePhase.downloading ||
      phase == FcOfflinePackagePhase.estimating;

  /// Approximate storage budget in human-readable form.
  String get formattedEstimate {
    if (estimatedBytes <= 0) return 'Unknown';
    if (estimatedBytes < 1024) return '$estimatedBytes B';
    if (estimatedBytes < 1024 * 1024) {
      return '${(estimatedBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(estimatedBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  FcOfflinePackageState copyWith({
    FcOfflinePackagePhase? phase,
    int? estimatedBytes,
    int? taskCount,
    int? reportCount,
    int? evidenceCount,
    int? noteCount,
    List<FcDownloadStep>? steps,
    DateTime? preparedAt,
    String? errorMessage,
  }) =>
      FcOfflinePackageState(
        phase:           phase           ?? this.phase,
        estimatedBytes:  estimatedBytes  ?? this.estimatedBytes,
        taskCount:       taskCount       ?? this.taskCount,
        reportCount:     reportCount     ?? this.reportCount,
        evidenceCount:   evidenceCount   ?? this.evidenceCount,
        noteCount:       noteCount       ?? this.noteCount,
        steps:           steps           ?? this.steps,
        preparedAt:      preparedAt      ?? this.preparedAt,
        errorMessage:    errorMessage,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Well-known step labels (used to construct the steps list)
// ─────────────────────────────────────────────────────────────────────────────

abstract class FcOfflineStepLabel {
  static const String tasks      = 'Assigned cleanup tasks';
  static const String reports    = 'Assigned reports';
  static const String evidence   = 'Citizen evidence metadata';
  static const String notes      = 'Field notes';
  static const String issueTypes = 'Reference data';
  static const String routes     = 'Active routes';
}

/// Constructs the initial (all pending) steps list.
List<FcDownloadStep> buildInitialSteps() => [
      const FcDownloadStep(label: FcOfflineStepLabel.tasks),
      const FcDownloadStep(label: FcOfflineStepLabel.reports),
      const FcDownloadStep(label: FcOfflineStepLabel.evidence),
      const FcDownloadStep(label: FcOfflineStepLabel.notes),
      const FcDownloadStep(label: FcOfflineStepLabel.issueTypes),
      const FcDownloadStep(label: FcOfflineStepLabel.routes),
    ];
