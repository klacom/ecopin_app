import 'dart:async';
import 'dart:io';
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

typedef StepProgressCallback =
    void Function(
      String stepLabel, {
      bool completed,
      bool inProgress,
      String? error,
    });

typedef CountCallback =
    void Function({int? tasks, int? reports, int? evidence, int? notes});

// ─────────────────────────────────────────────────────────────────────────────
// FcOfflinePackageService
// ─────────────────────────────────────────────────────────────────────────────

/// Orchestrates the selective download of all data a Field Crew member needs
/// for offline work.
///
/// Downloads assigned records in bounded ID batches, then evidence metadata,
/// notes and route records. Reference choices are bundled with the app.
/// Each request is paced and cancelled after 20 seconds. Authorization and
/// rate-limit failures stop subsequent network steps; no automatic retry loop.
/// Partial records remain cached and section failures are retained in the receipt.
class FcOfflinePackageService {
  final ApiClient _api;
  final FcLocalRepository _local;
  final _log = Logger('FcOfflinePackageService');

  // Timeout options — tight on purpose so the UI stays responsive.
  static final _itemOptions = Options(
    sendTimeout: const Duration(seconds: 10),
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
  static const int _bytesPerTask = 2 * 1024;
  static const int _bytesPerReport = 3 * 1024;
  static const int _bytesPerEvidence = 512;
  static const int _bytesPerNote = 512;
  static const int _baseOverheadBytes = 64 * 1024; // reference data + index

  Future<int> estimateBytes() async {
    try {
      final response = await _request(
        '${ApiConstants.cleanupTasks}?assignedToMe=true',
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
  DateTime? _lastRequest;
  DateTime? _retryAfter;
  bool _running = false;

  Future<Response<dynamic>> _request(
    String path, {
    Map<String, dynamic>? query,
    Object? data,
  }) async {
    final now = DateTime.now();
    if (_retryAfter != null && now.isBefore(_retryAfter!)) {
      throw StateError('Preparation is cooling down after a rate limit');
    }
    final elapsed = _lastRequest == null
        ? 250
        : now.difference(_lastRequest!).inMilliseconds;
    if (elapsed < 250) {
      await Future<void>.delayed(Duration(milliseconds: 250 - elapsed));
    }
    _lastRequest = DateTime.now();
    final cancel = CancelToken();
    final deadline = Timer(
      const Duration(seconds: 20),
      () => cancel.cancel('Preparation request timed out'),
    );
    try {
      return data == null
          ? await _api.dioClient.get(
              path,
              queryParameters: query,
              cancelToken: cancel,
              options: _itemOptions,
            )
          : await _api.dioClient.post(
              path,
              data: data,
              cancelToken: cancel,
              options: _itemOptions,
            );
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        final header = e.response?.headers.value('retry-after');
        final seconds = int.tryParse(header ?? '');
        var retry = DateTime.now().add(Duration(seconds: seconds ?? 60));
        if (seconds == null && header != null) {
          try {
            retry = HttpDate.parse(header);
          } catch (_) {}
        }
        final minimum = DateTime.now().add(const Duration(seconds: 60));
        _retryAfter = retry.isAfter(minimum) ? retry : minimum;
      }
      rethrow;
    } finally {
      deadline.cancel();
    }
  }

  Future<FcOfflinePackageState> download({
    required StepProgressCallback onStepProgress,
    required CountCallback onCountUpdate,
  }) async {
    if (_running) throw StateError('Preparation already running');
    if (_retryAfter != null && DateTime.now().isBefore(_retryAfter!)) {
      throw StateError('Please wait before retrying preparation');
    }
    _running = true;
    final steps = buildInitialSteps();
    final taskTitles = <String>[];
    final reportTitles = <String>[];
    int taskCount = 0,
        reportCount = 0,
        evidenceCount = 0,
        noteCount = 0,
        routeCount = 0;
    bool stopped = false;
    void progress(
      String label, {
      bool completed = false,
      bool inProgress = false,
      String? error,
    }) {
      final index = steps.indexWhere((s) => s.label == label);
      steps[index] = FcDownloadStep(
        label: label,
        completed: completed,
        inProgress: inProgress,
        error: error,
      );
      onStepProgress(
        label,
        completed: completed,
        inProgress: inProgress,
        error: error,
      );
    }

    Future<void> step(String label, Future<void> Function() work) async {
      if (stopped) {
        progress(
          label,
          error: 'Not downloaded. Resolve the earlier error and prepare again.',
        );
        return;
      }
      progress(label, inProgress: true);
      try {
        await work();
        progress(label, completed: true);
      } catch (e) {
        progress(label, error: _friendlyError(e));
        // Do not keep hitting a rate-limited or unauthenticated service.
        if (e is DioException &&
            {401, 403, 429}.contains(e.response?.statusCode)) {
          stopped = true;
        }
        _log.warning('Offline preparation section failed: $label', e);
      }
    }

    final reports = <String, ReportModel>{};
    List<CleanupTask> tasks = [];
    try {
      await step(FcOfflineStepLabel.tasks, () async {
        final response = await _request(
          '${ApiConstants.cleanupTasks}?assignedToMe=true',
        );
        tasks = (response.data as List)
            .map((j) => CleanupTask.fromJson(Map<String, dynamic>.from(j)))
            .toList();
        await _local.saveTasks(tasks);
        taskCount = tasks.length;
        taskTitles.addAll(tasks.map((t) => t.title));
        onCountUpdate(tasks: taskCount);
      });
      if (!steps.first.completed) stopped = true;
      await step(FcOfflineStepLabel.reports, () async {
        final ids = <String>{
          for (final t in tasks) ...t.reportIds,
          for (final t in tasks) ...?t.reports?.map((r) => r.id),
        }.toList();
        for (var offset = 0; offset < ids.length; offset += 100) {
          final chunk = ids.skip(offset).take(100).toSet();
          final response = await _request(
            ApiConstants.reports,
            query: {'ids': chunk.join(','), 'limit': 100},
          );
          final fetched = (response.data as List)
              .map((j) => ReportModel.fromJson(Map<String, dynamic>.from(j)))
              .where((r) => chunk.contains(r.id))
              .toList();
          await _local.saveReports(fetched);
          for (final r in fetched) {
            reports[r.id] = r;
          }
        }
        var failedGroups = 0;
        final clusters = tasks
            .where(
              (t) =>
                  t.reportIds.isEmpty &&
                  (t.reports?.isEmpty ?? true) &&
                  t.clusterId?.isNotEmpty == true,
            )
            .map((t) => t.clusterId!)
            .toSet();
        for (final cluster in clusters) {
          try {
            for (var page = 1; page <= 500; page++) {
              final response = await _request(
                '/api/reports/cluster/$cluster',
                query: {'limit': 100, 'page': page},
              );
              final fetched = (response.data as List)
                  .map(
                    (j) => ReportModel.fromJson(Map<String, dynamic>.from(j)),
                  )
                  .where((r) => r.clusterId == cluster)
                  .toList();
              final fresh = fetched
                  .where((r) => !reports.containsKey(r.id))
                  .toList();
              await _local.saveReports(fresh);
              for (final r in fresh) {
                reports[r.id] = r;
              }
              if (response.headers.value('x-has-more') != 'true') break;
              if (fresh.isEmpty || page == 500) {
                throw StateError('Incomplete report pagination');
              }
            }
          } catch (e) {
            if (e is DioException &&
                {401, 403, 429}.contains(e.response?.statusCode)) {
              rethrow;
            }
            failedGroups++;
          }
        }
        final missing = ids.toSet().difference(reports.keys.toSet());
        if (failedGroups > 0) {
          throw StateError(
            '$failedGroups assigned report groups could not download; ${missing.length} linked reports were not returned by the service',
          );
        }
        if (missing.isNotEmpty) {
          throw StateError(
            '${missing.length} linked reports were not returned by the service',
          );
        }
      });
      reportCount = reports.length;
      reportTitles.addAll(reports.values.map((r) => r.title));
      onCountUpdate(reports: reportCount);
      await step(FcOfflineStepLabel.evidence, () async {
        final ids = reports.keys.toList();
        for (var offset = 0; offset < ids.length; offset += 10) {
          final chunk = ids.skip(offset).take(10).toList();
          final response = await _request(
            '/api/reports/batch-evidence',
            data: {'reportIds': chunk, 'strict': true},
          );
          final data = Map<String, dynamic>.from(response.data);
          for (final id in chunk) {
            if (data[id] is! List) {
              throw StateError('Incomplete evidence response');
            }
            final rows = (data[id] as List)
                .map((j) => Map<String, dynamic>.from(j))
                .toList();
            await _local.saveEvidences(id, rows);
            evidenceCount += rows.length;
          }
          onCountUpdate(evidence: evidenceCount);
        }
      });
      await step(FcOfflineStepLabel.notes, () async {
        for (final id in reports.keys) {
          final response = await _request(ApiConstants.agencyResponses(id));
          final rows = (response.data as List)
              .map((j) => Map<String, dynamic>.from(j))
              .toList();
          await _local.saveNotes(id, rows);
          noteCount += rows.length;
          onCountUpdate(notes: noteCount);
        }
      });
      // Reference choices are bundled locally; fetching /reports?distinct did not cache them.
      progress(FcOfflineStepLabel.issueTypes, completed: true);
      await step(FcOfflineStepLabel.routes, () async {
        final response = await _request(ApiConstants.activeRoutes);
        for (final raw in response.data['routes'] as List) {
          final route = Map<String, dynamic>.from(raw);
          await _local.cacheRoute(route['id'].toString(), route);
          routeCount++;
        }
      });
      if (steps.every((s) => s.completed && s.error == null)) {
        await _local.recordSyncAt('fc_offline_package');
      }
      return FcOfflinePackageState(
        phase: steps.first.completed
            ? FcOfflinePackagePhase.ready
            : FcOfflinePackagePhase.failed,
        taskCount: taskCount,
        reportCount: reportCount,
        evidenceCount: evidenceCount,
        noteCount: noteCount,
        routeCount: routeCount,
        taskTitles: taskTitles,
        reportTitles: reportTitles,
        steps: steps,
        preparedAt: DateTime.now(),
      );
    } finally {
      _running = false;
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Returns a user-friendly error message — never exposes raw server text.
  String _friendlyError(Object e) {
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.cancel:
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Network timed out';
        case DioExceptionType.connectionError:
          return 'No network connection';
        default:
          final code = e.response?.statusCode;
          return code == 429
              ? 'Rate limited. Preparation stopped; wait at least a minute before retrying.'
              : code != null
              ? 'Server error ($code)'
              : 'Download failed';
      }
    }
    if (e is StateError && e.message.toString().contains('linked reports')) {
      return e.message.toString();
    }
    return 'Download failed';
  }
}
