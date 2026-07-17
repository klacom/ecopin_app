import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:ecopin_app/core/services/api_service.dart';

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
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    final reports = json['reports'] as Map<String, dynamic>? ?? {};
    final byStatus = reports['byStatus'] as Map<String, dynamic>? ?? {};

    log.finer('Parsing DashboardStats from: $json');
    log.finer('Reports object: $reports');
    log.finer('ByStatus object: $byStatus');

    return DashboardStats(
      totalReports: reports['total'] as int? ?? 0,
      unresolved: byStatus['unresolved'] as int? ?? 0,
      inProgress: byStatus['in_progress'] as int? ?? 0,
      resolved: byStatus['resolved'] as int? ?? 0,
      closed: byStatus['closed'] as int? ?? 0,
      waitingForFeedback: byStatus['waiting_for_feedback'] as int? ?? 0,
      resolvedToday: 0, // Backend doesn't provide this yet
      avgResolutionTime: 'N/A',
      resolutionRate: 0,
      overdue: 0, // Backend doesn't provide this yet
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
      final response = await _apiClient.getSystemStats();
      log.finer('System stats response: ${response.data}');
      final stats = DashboardStats.fromJson(response.data);
      log.finer(
        'Parsed stats: total=${stats.totalReports}, unresolved=${stats.unresolved}, resolved=${stats.resolved}',
      );
      _stats = AsyncValue.data(stats);
      notifyListeners();
    } catch (e, stackTrace) {
      log.severe('Error loading stats: $e');
      log.severe('Stack trace: $stackTrace');
      _stats = AsyncValue.error(e, stackTrace);
      notifyListeners();
    }
  }
}

final lguDashboardProvider = ChangeNotifierProvider<DashboardNotifier>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DashboardNotifier(apiClient);
});
