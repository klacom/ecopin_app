import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/features/officer/presentation/screens/officer_reports_screen.dart';
import 'package:ecopin_app/features/officer/providers/officer_cleanup_tasks_provider.dart';
import 'package:ecopin_app/features/officer/providers/officer_clusters_provider.dart';

class DashboardStats {
  final int totalReports;
  final int unresolved;
  final int inProgress;
  final int resolved;
  final int closed;
  final int waitingForFeedback;
  final int resolvedToday;
  final String avgResolutionTime;
  final int resolutionRate;
  final int overdue;

  // Aligned with Web Hero Strip & Command Center
  final int activeFieldUnits;
  final int slaRiskCount;
  final int manualReviewCount;
  final List<CleanupTask> activeTasks;
  final List<OfficerReportSummary> slaRiskReports;
  final List<OfficerReportSummary> manualReviewReports;
  final List<OfficerReportSummary> activeReports;
  final List<Cluster> criticalClusters;

  DashboardStats({
    required this.totalReports,
    required this.unresolved,
    required this.inProgress,
    required this.resolved,
    required this.closed,
    required this.waitingForFeedback,
    required this.resolvedToday,
    required this.avgResolutionTime,
    required this.resolutionRate,
    required this.overdue,
    this.activeFieldUnits = 0,
    this.slaRiskCount = 0,
    this.manualReviewCount = 0,
    this.activeTasks = const [],
    this.slaRiskReports = const [],
    this.manualReviewReports = const [],
    this.activeReports = const [],
    this.criticalClusters = const [],
  });

  factory DashboardStats.fromJson(
    Map<String, dynamic> json, {
    List<CleanupTask> tasks = const [],
    List<OfficerReportSummary> reports = const [],
    List<Cluster> clusters = const [],
  }) {
    final reportsMap = json['reports'] as Map<String, dynamic>? ?? {};
    final byStatus = reportsMap['byStatus'] as Map<String, dynamic>? ?? {};

    // 1. In-progress cleanup tasks -> Active Field Units & Active Targets
    final activeTasks = tasks.where((t) {
      final status = t.status?.toLowerCase().replaceAll(RegExp(r'[\s-]'), '_');
      return status == 'in_progress';
    }).toList();

    // 2. Active reports (not resolved & not closed)
    final activeReports = reports.where((r) {
      final s = r.status?.toLowerCase();
      return s != 'resolved' && s != 'closed';
    }).toList();

    // 3. SLA Risk calculation (overdue or unresolved for > 48 hours)
    final now = DateTime.now();
    final slaRiskReports = activeReports.where((r) {
      if (r.isOverdue == true) return true;
      if (r.createdAt != null) {
        final diffHours = now.difference(r.createdAt!).inHours;
        return diffHours > 48;
      }
      return false;
    }).toList();

    // 4. Manual Review validation reports
    final manualReviewReports = reports.where((r) {
      final val = r.validationStatus?.toLowerCase();
      return val == 'manual_review';
    }).toList();

    // 5. Critical Clusters (sorted by priority score or severity)
    final sortedClusters = List<Cluster>.from(clusters)
      ..sort((a, b) {
        final scoreA = a.priorityScore ?? ((a.reportCount ?? 0) * 10.0);
        final scoreB = b.priorityScore ?? ((b.reportCount ?? 0) * 10.0);
        return scoreB.compareTo(scoreA);
      });
    final criticalClusters = sortedClusters.take(3).toList();

    final unresolvedCount = activeReports.isNotEmpty
        ? activeReports.length
        : (byStatus['unresolved'] as int? ?? 0);

    final totalReportsCount = reports.isNotEmpty
        ? reports.length
        : (reportsMap['total'] as int? ?? 0);

    return DashboardStats(
      totalReports: totalReportsCount,
      unresolved: unresolvedCount,
      inProgress: byStatus['in_progress'] as int? ?? activeTasks.length,
      resolved: byStatus['resolved'] as int? ?? 0,
      closed: byStatus['closed'] as int? ?? 0,
      waitingForFeedback: byStatus['waiting_for_feedback'] as int? ?? 0,
      resolvedToday: 0,
      avgResolutionTime: 'N/A',
      resolutionRate: totalReportsCount > 0
          ? (((byStatus['resolved'] as int? ?? 0) / totalReportsCount) * 100).round()
          : 0,
      overdue: slaRiskReports.length,
      activeFieldUnits: activeTasks.length,
      slaRiskCount: slaRiskReports.length,
      manualReviewCount: manualReviewReports.length,
      activeTasks: activeTasks,
      slaRiskReports: slaRiskReports,
      manualReviewReports: manualReviewReports,
      activeReports: activeReports,
      criticalClusters: criticalClusters,
    );
  }
}

class DashboardNotifier extends ChangeNotifier {
  final ApiClient _apiClient;
  AsyncValue<DashboardStats> _stats = const AsyncValue.loading();

  DashboardNotifier(this._apiClient) {
    loadStats();
  }

  AsyncValue<DashboardStats> get stats => _stats;

  Future<void> loadStats() async {
    _stats = const AsyncValue.loading();
    notifyListeners();
    try {
      Future<dynamic> safeFetch(Future<dynamic> Function() fetcher, String label) async {
        try {
          return await fetcher();
        } catch (e) {
          log.warning('Failed to fetch $label: $e');
          return null;
        }
      }

      final results = await Future.wait([
        safeFetch(() => _apiClient.getSystemStats(), 'system stats'),
        safeFetch(() => _apiClient.getPublicReports(), 'public reports'),
        safeFetch(() => _apiClient.getCleanupTasks(), 'cleanup tasks'),
        safeFetch(() => _apiClient.getClusters(), 'clusters'),
      ]);

      final dynamic systemStatsResp = results[0];
      final dynamic reportsResp = results[1];
      final dynamic tasksResp = results[2];
      final dynamic clustersResp = results[3];

      final Map<String, dynamic> systemStatsJson = (systemStatsResp != null && systemStatsResp.data is Map<String, dynamic>)
          ? systemStatsResp.data as Map<String, dynamic>
          : {};

      List<OfficerReportSummary> parsedReports = [];
      if (reportsResp != null && reportsResp.data is List) {
        parsedReports = (reportsResp.data as List)
            .map((j) => OfficerReportSummary.fromJson(j as Map<String, dynamic>))
            .where((r) => r.validationStatus?.toLowerCase() != 'rejected')
            .toList();
      }

      List<CleanupTask> parsedTasks = [];
      if (tasksResp != null && tasksResp.data is List) {
        parsedTasks = (tasksResp.data as List)
            .map((j) => CleanupTask.fromJson(j as Map<String, dynamic>))
            .toList();
      }

      List<Cluster> parsedClusters = [];
      if (clustersResp != null && clustersResp.data is List) {
        parsedClusters = (clustersResp.data as List)
            .map((j) => Cluster.fromJson(j as Map<String, dynamic>))
            .toList();
      }

      final stats = DashboardStats.fromJson(
        systemStatsJson,
        tasks: parsedTasks,
        reports: parsedReports,
        clusters: parsedClusters,
      );

      _stats = AsyncValue.data(stats);
      notifyListeners();
    } catch (e, stackTrace) {
      log.severe('Error loading officer dashboard stats: $e');
      log.severe('Stack trace: $stackTrace');
      _stats = AsyncValue.error(e, stackTrace);
      notifyListeners();
    }
  }
}

final officerDashboardProvider = ChangeNotifierProvider<DashboardNotifier>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DashboardNotifier(apiClient);
});

