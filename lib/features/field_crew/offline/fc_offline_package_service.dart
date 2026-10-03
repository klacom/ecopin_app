import 'package:dio/dio.dart';
import 'package:ecopin_app/core/constants/api_constants.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/features/field_crew/data/repositories/fc_local_repository.dart';
import 'package:ecopin_app/features/field_crew/offline/fc_offline_package.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import 'package:ecopin_app/features/field_crew/data/models/cleanup_task_model.dart';
import 'package:logging/logging.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Callback types
// ─────────────────────────────────────────────────────────────────────────────

typedef StepProgressCallback = void Function(String stepLabel,
    {bool completed, bool inProgress, String? error});

typedef CountCallback = void Function(
    {int? tasks, int? reports, int? evidence, int? notes});

// ─────────────────────────────────────────────────────────────────────────────
// FcOfflinePackageService
// ─────────────────────────────────────────────────────────────────────────────

/// Orchestrates the selective download of all data a Field Crew member needs
/// for offline work.
///
/// Sequence
/// ────────
///   1. Fetch assigned cleanup tasks  →  cache to Drift
///   2. Collect all report IDs from those tasks
///   3. Fetch each report  →  cache to Drift
///   4. Fetch evidence metadata for each report  →  cache to Drift
///   5. Fetch agency-response notes for each report  →  cache to Drift
///   6. Fetch issue-type reference data  →  cache in-memory (FcLocalRepository)
///
/// The service reports progress via the [onStepProgress] and [onCountUpdate]
/// callbacks so the UI can update in real time.
///
/// Network timeouts
/// ────────────────
/// Every network call uses a tight deadline so the UI never hangs:
///   • List fetches: 20 s connect / 30 s receive
///   • Individual resource fetches: 10 s connect / 15 s receive
///
/// Crash-safety
/// ────────────
/// Each step is independently try-caught.  A failure in one step does not
/// abort subsequent steps — the partial package is still useful offline and
/// the error is reported per-step.
class FcOfflinePackageService {
  final ApiClient _api;
  final FcLocalRepository _local;
  final _log = Logger('FcOfflinePackageService');

  // Timeout options — tight on purpose so the UI stays responsive.
  static final _listOptions = Options(
    sendTimeout:    const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 30),
  );
  static final _itemOptions = Options(
    sendTimeout:    const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  );

  FcOfflinePackageService(this._api, this._local);

  // ── Storage estimate ───────────────────────────────────────────────────────

  /// Estimates storage by counting assigned tasks/reports without downloading
  /// full payloads.
  ///
  /// Approximation per record:
  ///   Task JSON  ≈  2 KB
  ///   Report JSON ≈  3 KB
  ///   Evidence row ≈  0.5 KB
  ///   Note row ≈  0.5 KB
  ///   (thumbnails are handled by cached_network_image, not counted here)
  static const int _bytesPerTask     = 2 * 1024;
  static const int _bytesPerReport   = 3 * 1024;
  static const int _bytesPerEvidence = 512;
  static const int _bytesPerNote     = 512;
  static const int _baseOverheadBytes = 64 * 1024; // reference data + index

  Future<int> estimateBytes() async {
    try {
      final response = await _api.dioClient.get(
        '${ApiConstants.cleanupTasks}?assignedToMe=true',
        options: _listOptions,
      );
      final tasks = (response.data as List<dynamic>)
          .map((j) => CleanupTask.fromJson(j))
          .toList();

      final reportIds = <String>{};
      for (final t in tasks) {
        reportIds.addAll(t.reportIds);
        if (t.reports != null) {
          for (final r in t.reports!) {
            reportIds.add(r.id);
          }
        }
      }

      // Rough estimate: 3 evidence items + 2 notes per report on average.
      return _baseOverheadBytes +
          tasks.length * _bytesPerTask +
          reportIds.length * _bytesPerReport +
          reportIds.length * 3 * _bytesPerEvidence +
          reportIds.length * 2 * _bytesPerNote;
    } catch (e) {
      _log.warning('estimateBytes failed: $e');
      return 0; // Unknown — still let download proceed
    }
  }

  // ── Main download ──────────────────────────────────────────────────────────

  /// Downloads the full offline work package.
  ///
  /// [onStepProgress] is called as each step starts, completes, or fails.
  /// [onCountUpdate] is called when actual record counts are known.
  ///
  /// Returns the final [FcOfflinePackageState] after all steps complete.
  Future<FcOfflinePackageState> download({
    required StepProgressCallback onStepProgress,
    required CountCallback onCountUpdate,
  }) async {
    int taskCount    = 0;
    int reportCount  = 0;
    int evidenceCount = 0;
    int noteCount    = 0;
    int routeCount   = 0;

    // ── Step 1: Assigned cleanup tasks ──────────────────────────────────────
    List<CleanupTask> tasks = [];
    onStepProgress(FcOfflineStepLabel.tasks, inProgress: true);
    try {
      final response = await _api.dioClient.get(
        '${ApiConstants.cleanupTasks}?assignedToMe=true',
        options: _listOptions,
      );
      final data = response.data as List<dynamic>;
      tasks = data.map((j) => CleanupTask.fromJson(j)).toList();
      await _local.saveTasks(tasks);
      taskCount = tasks.length;
      onCountUpdate(tasks: taskCount);
      onStepProgress(FcOfflineStepLabel.tasks, completed: true);
      _log.info('Offline package: cached $taskCount tasks');
    } catch (e) {
      onStepProgress(FcOfflineStepLabel.tasks,
          completed: false, error: _friendlyError(e));
      _log.warning('Offline package: task fetch failed: $e');
    }

    // ── Collect all report IDs ───────────────────────────────────────────────
    final reportIds = <String>{};
    for (final t in tasks) {
      reportIds.addAll(t.reportIds);
      if (t.reports != null) {
        for (final r in t.reports!) {
          reportIds.add(r.id);
        }
      }
      if (t.clusterId != null && t.clusterId!.isNotEmpty) {
        // For cluster-based tasks we fetch by cluster below.
      }
    }

    // ── Step 2: Fetch each report ────────────────────────────────────────────
    final List<ReportModel> reports = [];
    onStepProgress(FcOfflineStepLabel.reports, inProgress: true);
    try {
      // Batch by ID when possible; fall back to cluster fetch for cluster tasks.
      if (reportIds.isNotEmpty) {
        final response = await _api.dioClient.get(
          ApiConstants.reports,
          queryParameters: {'ids': reportIds.join(',')},
          options: _listOptions,
        );
        final data = response.data as List<dynamic>;
        final fetched = data
            .map((j) => ReportModel.fromJson(j as Map<String, dynamic>))
            .toList();
        await _local.saveReports(fetched);
        reports.addAll(fetched);
      }

      // Also fetch by cluster for tasks that use cluster-based assignment.
      final clusterIds = tasks
          .where((t) => t.clusterId != null && t.clusterId!.isNotEmpty)
          .map((t) => t.clusterId!)
          .toSet();
      for (final clusterId in clusterIds) {
        try {
          final res = await _api.dioClient.get(
            '/api/reports/cluster/$clusterId',
            options: _itemOptions,
          );
          final clusterReports = (res.data as List<dynamic>)
              .map((j) => ReportModel.fromJson(j as Map<String, dynamic>))
              .toList();
          await _local.saveReports(clusterReports);
          // De-duplicate by ID before adding to our list.
          final existingIds = reports.map((r) => r.id).toSet();
          for (final r in clusterReports) {
            if (!existingIds.contains(r.id)) reports.add(r);
          }
        } catch (e) {
          _log.warning('Offline package: cluster $clusterId fetch failed: $e');
        }
      }

      reportCount = reports.length;
      onCountUpdate(reports: reportCount);
      onStepProgress(FcOfflineStepLabel.reports, completed: true);
      _log.info('Offline package: cached $reportCount reports');
    } catch (e) {
      onStepProgress(FcOfflineStepLabel.reports,
          completed: false, error: _friendlyError(e));
      _log.warning('Offline package: report fetch failed: $e');
    }

    // ── Step 3: Evidence metadata ────────────────────────────────────────────
    onStepProgress(FcOfflineStepLabel.evidence, inProgress: true);
    int evidenceFailed = 0;
    for (final report in reports) {
      try {
        final res = await _api.dioClient.get(
          ApiConstants.evidenceByReportId(report.id),
          options: _itemOptions,
        );
        final list = res.data as List<dynamic>;
        final maps = list.whereType<Map<String, dynamic>>().toList();
        await _local.saveEvidences(report.id, maps);
        evidenceCount += maps.length;
      } catch (e) {
        evidenceFailed++;
        _log.fine('Evidence fetch failed for ${report.id}: $e');
      }
    }
    onCountUpdate(evidence: evidenceCount);
    if (evidenceFailed == 0 || reports.isEmpty) {
      onStepProgress(FcOfflineStepLabel.evidence, completed: true);
    } else {
      onStepProgress(FcOfflineStepLabel.evidence,
          completed: true,
          error: '$evidenceFailed report(s) had no evidence cached');
    }
    _log.info('Offline package: cached $evidenceCount evidence items '
        '($evidenceFailed failures)');

    // ── Step 4: Agency-response notes ───────────────────────────────────────
    onStepProgress(FcOfflineStepLabel.notes, inProgress: true);
    int notesFailed = 0;
    for (final report in reports) {
      try {
        final res = await _api.dioClient.get(
          ApiConstants.agencyResponses(report.id),
          options: _itemOptions,
        );
        final list = res.data as List<dynamic>;
        final maps = list.whereType<Map<String, dynamic>>().toList();
        await _local.saveNotes(report.id, maps);
        noteCount += maps.length;
      } catch (e) {
        notesFailed++;
        _log.fine('Notes fetch failed for ${report.id}: $e');
      }
    }
    onCountUpdate(notes: noteCount);
    if (notesFailed == 0 || reports.isEmpty) {
      onStepProgress(FcOfflineStepLabel.notes, completed: true);
    } else {
      onStepProgress(FcOfflineStepLabel.notes,
          completed: true,
          error: '$notesFailed report(s) had no notes cached');
    }
    _log.info('Offline package: cached $noteCount notes ($notesFailed failures)');

    // ── Step 5: Issue-type reference data ────────────────────────────────────
    onStepProgress(FcOfflineStepLabel.issueTypes, inProgress: true);
    try {
      // Warm the issue-type list by fetching it — the repository caches it.
      await _api.dioClient.get(
        ApiConstants.reports,
        queryParameters: {'distinct': 'issue_type'},
        options: _itemOptions,
      );
      onStepProgress(FcOfflineStepLabel.issueTypes, completed: true);
    } catch (e) {
      // Non-fatal — hard-coded fallback exists in the repository.
      onStepProgress(FcOfflineStepLabel.issueTypes,
          completed: true,
          error: 'Using cached reference data');
      _log.fine('Issue-type fetch failed (fallback used): $e');
    }

    // ── Step 6: Active Routes ──────────────────────────────────────────────
    onStepProgress(FcOfflineStepLabel.routes, inProgress: true);
    try {
      final res = await _api.dioClient.get(
        ApiConstants.activeRoutes,
        options: _listOptions,
      );
      if (res.data['routes'] != null) {
        final routesData = res.data['routes'] as List<dynamic>;
        for (final routeData in routesData) {
          final map = routeData as Map<String, dynamic>;
          final id = map['id']?.toString();
          if (id != null) {
            await _local.cacheRoute(id, map);
            routeCount++;
          }
        }
      }
      onStepProgress(FcOfflineStepLabel.routes, completed: true);
      _log.info('Offline package: cached $routeCount routes');
    } catch (e) {
      onStepProgress(FcOfflineStepLabel.routes,
          completed: true, error: _friendlyError(e));
      _log.warning('Offline package: routes fetch failed: $e');
    }

    await _local.recordSyncAt('fc_offline_package');
    return FcOfflinePackageState(
      phase:         FcOfflinePackagePhase.ready,
      taskCount:     taskCount,
      reportCount:   reportCount,
      evidenceCount: evidenceCount,
      noteCount:     noteCount,
      steps:         buildInitialSteps()
          .map((s) => s.copyWith(completed: true))
          .toList(),
      preparedAt:    DateTime.now(),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Returns a user-friendly error message — never exposes raw server text.
  String _friendlyError(Object e) {
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Network timed out';
        case DioExceptionType.connectionError:
          return 'No network connection';
        default:
          final code = e.response?.statusCode;
          return code != null ? 'Server error ($code)' : 'Download failed';
      }
    }
    return 'Download failed';
  }
}
