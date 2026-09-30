import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/features/field_crew/data/repositories/field_crew_report_repository.dart';
import 'package:ecopin_app/features/field_crew/providers/fc_local_repository_provider.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import 'package:ecopin_app/features/field_crew/data/models/agency_response_model.dart';
import 'package:ecopin_app/features/field_crew/providers/cleanup_tasks_provider.dart';
import 'package:ecopin_app/core/services/cache_service.dart';

class AssignedReportsData {
  final List<ReportModel> reports;
  final Map<String, String> reportTaskMap;

  AssignedReportsData({required this.reports, required this.reportTaskMap});
}

final fieldCrewReportRepositoryProvider = Provider<FieldCrewReportRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final cacheService = ref.watch(cacheServiceProvider);
  final localRepo = ref.watch(fcLocalRepositoryProvider);
  final localPhotoRepo = ref.watch(fcLocalPhotoRepositoryProvider);
  return FieldCrewReportRepository(apiClient, cacheService, localRepo, localPhotoRepo);
});

final fieldCrewReportsProvider = FutureProvider<List<ReportModel>>((ref) {
  final repository = ref.watch(fieldCrewReportRepositoryProvider);
  return repository.fetchFilteredReports();
});

final fieldCrewReportDetailProvider = FutureProvider.family<ReportModel, String>((ref, id) {
  final repository = ref.watch(fieldCrewReportRepositoryProvider);
  return repository.fetchReportById(id);
});

final issueTypesProvider = FutureProvider<List<String>>((ref) {
  final repository = ref.watch(fieldCrewReportRepositoryProvider);
  return repository.fetchIssueTypes();
});

final reportEvidenceProvider = FutureProvider.family<List<dynamic>, String>((ref, reportId) {
  final repository = ref.watch(fieldCrewReportRepositoryProvider);
  return repository.fetchReportEvidence(reportId);
});

final agencyResponsesProvider = FutureProvider.family<List<AgencyResponse>, String>((ref, reportId) {
  final repository = ref.watch(fieldCrewReportRepositoryProvider);
  return repository.fetchAgencyResponses(reportId);
});

final assignedReportsProvider = FutureProvider<AssignedReportsData>((ref) async {
  final allReports = await ref.watch(fieldCrewReportsProvider.future);
  final allTasks = await ref.watch(allCleanupTasksProvider.future);

  final allowedClusterIds = <String>{};
  final allowedReportIds = <String>{};
  final reportTaskMap = <String, String>{};

  // Build the allowed sets from tasks
  for (final task in allTasks) {
    if (task.clusterId != null && task.clusterId!.isNotEmpty) {
      allowedClusterIds.add(task.clusterId!);
    }
    for (final rId in task.reportIds) {
      allowedReportIds.add(rId);
    }
    if (task.reports != null) {
      for (final r in task.reports!) {
        allowedReportIds.add(r.id);
        if (r.clusterId != null) allowedClusterIds.add(r.clusterId!);
      }
    }
  }

  // Filter reports down to only those linked to a cleanup task
  final assignedReports = allReports.where((report) {
    final cMatch = report.clusterId != null && allowedClusterIds.contains(report.clusterId);
    final rMatch = allowedReportIds.contains(report.id);
    return cMatch || rMatch;
  }).toList();

  for (final report in assignedReports) {
    final matchingTask = allTasks.firstWhere((t) =>
      (t.clusterId != null && t.clusterId == report.clusterId) ||
      t.reportIds.contains(report.id) ||
      (t.reports?.any((r) => r.id == report.id) ?? false),
    );
    reportTaskMap[report.id] = matchingTask.id;
  }

  assignedReports.sort((a, b) => b.createdAt.compareTo(a.createdAt));

  return AssignedReportsData(reports: assignedReports, reportTaskMap: reportTaskMap);
});

