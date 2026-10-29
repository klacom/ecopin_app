import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'fc_investigation_provider.dart';
import '../location/crew_investigation_session.dart';
import 'package:ecopin_app/core/services/location_search_service.dart';
import '../presentation/controllers/fc_task_detail_presentation.dart';
import 'fc_local_repository_provider.dart';
import 'package:ecopin_app/features/field_crew/data/models/cleanup_task_model.dart';
import 'package:ecopin_app/features/field_crew/providers/cleanup_tasks_provider.dart';
import 'package:ecopin_app/features/field_crew/providers/field_crew_reports_provider.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';

/// Holds all screen state for a single task detail view.
class FcTaskDetailState {
  final CleanupTask? task;
  final List<ReportModel> reports;
  final bool isLoading;
  final String? errorMessage;
  final Map<String, List<dynamic>> evidenceByReport;
  final bool isEvidenceLoading;
  final String? evidenceError;
  final String? resolvedAddress;

  const FcTaskDetailState({
    this.task,
    this.reports = const [],
    this.isLoading = false,
    this.errorMessage,
    this.evidenceByReport = const {},
    this.isEvidenceLoading = false,
    this.evidenceError,
    this.resolvedAddress,
  });

  FcTaskDetailState copyWith({
    CleanupTask? task,
    List<ReportModel>? reports,
    bool? isLoading,
    String? errorMessage,
    Map<String, List<dynamic>>? evidenceByReport,
    bool? isEvidenceLoading,
    String? evidenceError,
    String? resolvedAddress,
  }) {
    return FcTaskDetailState(
      task: task ?? this.task,
      reports: reports ?? this.reports,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      evidenceByReport: evidenceByReport ?? this.evidenceByReport,
      isEvidenceLoading: isEvidenceLoading ?? this.isEvidenceLoading,
      evidenceError: evidenceError,
      resolvedAddress: resolvedAddress ?? this.resolvedAddress,
    );
  }
}

class FcTaskDetailNotifier extends Notifier<FcTaskDetailState> {
  final String taskId;

  FcTaskDetailNotifier(this.taskId);
  int _generation = 0;

  @override
  FcTaskDetailState build() {
    Future.microtask(_load);
    return const FcTaskDetailState(isLoading: true);
  }

  Future<void> _load() async {
    final generation = ++_generation;
    state = state.copyWith(isLoading: true);
    try {
      final task = await ref
          .read(cleanupTaskRepositoryProvider)
          .fetchTaskById(taskId, refresh: true);
      final repo = ref.read(fieldCrewReportRepositoryProvider);
      final wanted = taskReportIds(task);
      final fetched = await repo.fetchReportsByIds(wanted.toList());
      if (!ref.mounted || generation != _generation) return;
      final byId = {
        for (final r in fetched)
          if (wanted.contains(r.id) &&
              (r.cleanupTaskId == null || r.cleanupTaskId == task.id))
            r.id: r,
      };
      final reports = [
        for (final id in wanted)
          if (byId[id] != null) byId[id]!,
      ];
      state = FcTaskDetailState(
        task: task,
        reports: reports,
        errorMessage: reports.length < wanted.length
            ? '${reports.length} of ${wanted.length} linked reports available. Refresh before completing this task.'
            : null,
        isEvidenceLoading: reports.isNotEmpty,
      );
      await Future.wait([
        refreshEvidence(generation: generation),
        _resolveAddress(task, generation),
      ]);
    } catch (_) {
      if (ref.mounted && generation == _generation) {
        state = state.copyWith(
          isLoading: false,
          errorMessage:
              'Task details could not refresh. Check your connection and try again.',
        );
      }
    }
  }

  Future<void> refreshEvidence({int? generation}) async {
    if (generation == null && state.isEvidenceLoading) return;
    final token = generation ?? _generation;
    final ids = state.reports.map((r) => r.id).toList();
    if (ids.isEmpty) return;
    state = state.copyWith(
      isEvidenceLoading: true,
      errorMessage: state.errorMessage,
    );
    try {
      final rows = await ref
          .read(fieldCrewReportRepositoryProvider)
          .fetchEvidenceByReportIds(ids);
      if (ref.mounted && token == _generation) {
        state = state.copyWith(
          evidenceByReport: rows,
          isEvidenceLoading: false,
          errorMessage: state.errorMessage,
        );
      }
    } catch (_) {
      if (ref.mounted && token == _generation) {
        state = state.copyWith(
          isEvidenceLoading: false,
          evidenceError:
              'Citizen evidence could not load. This does not mean no photos were submitted.',
          errorMessage: state.errorMessage,
        );
      }
    }
  }

  Future<void> _resolveAddress(CleanupTask task, int generation) async {
    if (task.streetAddress?.trim().isNotEmpty == true) return;
    final point = taskPoint(task);
    if (point == null) return;
    try {
      final address = await ref
          .read(taskAddressResolverProvider)
          .getAddressFromCoordinates(point.latitude, point.longitude);
      if (!ref.mounted || generation != _generation || address == null) return;
      state = state.copyWith(
        resolvedAddress: address,
        errorMessage: state.errorMessage,
        evidenceError: state.evidenceError,
      );
      await ref.read(taskAddressCacheProvider)(task, address);
    } catch (_) {
      /* Coordinates remain available offline. */
    }
  }

  Future<void> refresh() => _load();

  /// Marks the task as complete optimistically.
  Future<void> markComplete() async {
    final current = state.task;
    if (current == null) return;
    if (state.isLoading ||
        state.reports.length != taskReportIds(current).length ||
        !state.reports.every(reportIsHandled)) {
      throw StateError(
        'Finish every linked report before completing this task.',
      );
    }
    final investigation = ref.read(fcInvestigationProvider(taskId));
    final receipts = investigation.taskReceipts;
    final taskRepo = ref.read(cleanupTaskRepositoryProvider);
    await taskRepo.markTaskComplete(taskId, investigations: receipts);
    if (ref.mounted) {
      state = state.copyWith(
        task: _patchTask(current, {'status': 'completed'}),
      );
    }
  }

  void holdFailedLocation(String reasonCode) {
    final current = state.task;
    if (current == null) return;
    ref.read(heldTasksProvider.notifier).holdTask(taskId);
    state = state.copyWith(
      task: _patchTask(current, {
        'status': 'cancelled',
        'failure_reason_code': reasonCode,
      }),
    );
  }

  CleanupTask _patchTask(CleanupTask t, Map<String, dynamic> patch) {
    final json = t.toJson();
    json.addAll(patch);
    return CleanupTask.fromJson(json);
  }
}

/// Family provider — one notifier per taskId.
final fcTaskDetailNotifierProvider =
    NotifierProvider.family<FcTaskDetailNotifier, FcTaskDetailState, String>(
      (taskId) => FcTaskDetailNotifier(taskId),
    );

final taskAddressResolverProvider = Provider<LocationSearchService>(
  (ref) => LocationSearchService(),
);
final taskAddressCacheProvider =
    Provider<Future<void> Function(CleanupTask, String)>((ref) {
      return (task, address) async {
        final data = task.toJson()..['street_address'] = address;
        await ref.read(fcLocalRepositoryProvider).saveTasks([
          CleanupTask.fromJson(data),
        ]);
      };
    });

/// Screen-owned subscription; action guards depend only on the session provider.
final fcActiveInvestigationProvider = Provider.autoDispose
    .family<CrewInvestigationSession, String>((ref, taskId) {
      final session = ref.watch(fcInvestigationProvider(taskId));
      void configure(FcTaskDetailState state) {
        if (state.task != null) session.configure(state.task!, state.reports);
      }

      configure(ref.read(fcTaskDetailNotifierProvider(taskId)));
      ref.listen(
        fcTaskDetailNotifierProvider(taskId),
        (_, state) => configure(state),
      );
      return session;
    });
