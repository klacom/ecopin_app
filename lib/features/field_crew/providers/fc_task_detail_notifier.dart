import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  const FcTaskDetailState({
    this.task,
    this.reports = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  FcTaskDetailState copyWith({
    CleanupTask? task,
    List<ReportModel>? reports,
    bool? isLoading,
    String? errorMessage,
  }) {
    return FcTaskDetailState(
      task: task ?? this.task,
      reports: reports ?? this.reports,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class FcTaskDetailNotifier extends Notifier<FcTaskDetailState> {
  final String taskId;

  FcTaskDetailNotifier(this.taskId);

  @override
  FcTaskDetailState build() {
    Future.microtask(_load);
    return const FcTaskDetailState(isLoading: true);
  }

  Future<void> _load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final taskRepo = ref.read(cleanupTaskRepositoryProvider);
      final reportRepo = ref.read(fieldCrewReportRepositoryProvider);

      final task = await taskRepo.fetchTaskById(taskId);
      List<ReportModel> reports = [];
      if (task.reportIds.isNotEmpty) {
        reports = await reportRepo.fetchReportsByIds(task.reportIds);
      } else if (task.clusterId != null && task.clusterId!.isNotEmpty) {
        reports = await reportRepo.fetchReportsByClusterId(task.clusterId!);
      }

      state = FcTaskDetailState(task: task, reports: reports, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> refresh() => _load();

  /// Marks the task as complete optimistically.
  Future<void> markComplete() async {
    final current = state.task;
    if (current == null) return;
    state = state.copyWith(task: _patchTask(current, {'status': 'completed'}));
    final taskRepo = ref.read(cleanupTaskRepositoryProvider);
    await taskRepo.markTaskComplete(taskId);
  }

  void holdFailedLocation(String reasonCode) {
    final current = state.task;
    if (current == null) return;
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
