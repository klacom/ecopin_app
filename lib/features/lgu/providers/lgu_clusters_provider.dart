import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:ecopin_app/core/services/api_service.dart';

class Cluster {
  final String id;
  final String? issueType;
  final String? severity;
  final int? reportCount;
  final DateTime? createdAt;
  final String? status;

  Cluster({
    required this.id,
    this.issueType,
    this.severity,
    this.reportCount,
    this.createdAt,
    this.status,
  });

  factory Cluster.fromJson(Map<String, dynamic> json) {
    return Cluster(
      id: json['id']?.toString() ?? '',
      issueType: json['issue_type'] as String?,
      severity: json['severity'] as String?,
      reportCount: json['report_count'] as int?,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null,
      status: json['status'] as String?,
    );
  }
}

class ClustersNotifier extends ChangeNotifier {
  final ApiClient _apiClient;
  AsyncValue<List<Cluster>> _clusters = const AsyncValue.loading();

  ClustersNotifier(this._apiClient) {
    loadClusters();
  }

  AsyncValue<List<Cluster>> get clusters => _clusters;

  Future<void> loadClusters() async {
    _clusters = const AsyncValue.loading();
    notifyListeners();
    try {
      final response = await _apiClient.getClusters();
      final List<dynamic> data = response.data is List 
          ? response.data as List<dynamic>
          : [];
      final clusters = data.map((json) => Cluster.fromJson(json as Map<String, dynamic>)).toList();
      _clusters = AsyncValue.data(clusters);
      notifyListeners();
    } catch (e, stackTrace) {
      _clusters = AsyncValue.error(e, stackTrace);
      notifyListeners();
    }
  }

  void reset() {
    _clusters = const AsyncValue.loading();
    notifyListeners();
  }
}

final lguClustersProvider = ChangeNotifierProvider<ClustersNotifier>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ClustersNotifier(apiClient);
});
