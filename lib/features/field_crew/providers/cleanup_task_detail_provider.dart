import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/features/field_crew/data/models/cleanup_task_model.dart';
import 'package:ecopin_app/features/field_crew/providers/cleanup_tasks_provider.dart';
import 'package:ecopin_app/features/field_crew/providers/field_crew_reports_provider.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';

final cleanupTaskDetailProvider = FutureProvider.family<CleanupTask, String>((ref, id) async {
  final repository = ref.watch(cleanupTaskRepositoryProvider);
  return repository.fetchTaskById(id);
});

final taskReportsProvider = FutureProvider.family<List<ReportModel>, String>((ref, taskId) async {
  final task = await ref.watch(cleanupTaskDetailProvider(taskId).future);
  final reportRepo = ref.watch(fieldCrewReportRepositoryProvider);
  
  if (task.clusterId != null && task.clusterId!.isNotEmpty) {
    return reportRepo.fetchReportsByClusterId(task.clusterId!);
  } else if (task.reportIds.isNotEmpty) {
    return reportRepo.fetchReportsByIds(task.reportIds);
  }
  return [];
});

final taskResolvedCountProvider = Provider.family<int, String>((ref, taskId) {
  final reportsAsync = ref.watch(taskReportsProvider(taskId));
  return reportsAsync.maybeWhen(
    data: (reports) {
      int resolvedCount = 0;
      for (var r in reports) {
        bool isScouting = r.issueType == 'scouting' || r.issueType == 'acknowledge_only';
        bool isResolved = r.status.toLowerCase() == 'resolved' || r.status.toLowerCase() == 'closed';
        if (isScouting) {
          if (r.validationStatus.toLowerCase() == 'validated' || isResolved) {
            resolvedCount++;
          }
        } else {
          if (isResolved) {
            resolvedCount++;
          }
        }
      }
      return resolvedCount;
    },
    orElse: () => 0,
  );
});
