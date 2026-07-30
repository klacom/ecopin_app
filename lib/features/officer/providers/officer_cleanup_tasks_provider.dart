import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:ecopin_app/core/services/api_service.dart';

class CleanupTask {
  final String id;
  final String? clusterId;
  final String? title;
  final String? description;
  final String? status;
  final DateTime? createdAt;
  final String? createdBy;
  final Map<String, dynamic>? cluster;
  final List<String>? beforePhotos;
  final List<String>? afterPhotos;
  final bool isCustom;
  final List<String>? reportIds;

  CleanupTask({
    required this.id,
    this.clusterId,
    this.title,
    this.description,
    this.status,
    this.createdAt,
    this.createdBy,
    this.cluster,
    this.beforePhotos,
    this.afterPhotos,
    this.isCustom = false,
    this.reportIds,
  });

  factory CleanupTask.fromJson(Map<String, dynamic> json) {
    return CleanupTask(
      id: json['id']?.toString() ?? '',
      clusterId: json['cluster_id']?.toString(),
      title: json['title'] as String?,
      description: json['description'] as String?,
      status: json['status'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      createdBy: json['created_by']?.toString(),
      cluster: json['clusters'] as Map<String, dynamic>?,
      beforePhotos: json['before_photos'] != null
          ? (json['before_photos'] as List).map((e) => e.toString()).toList()
          : null,
      afterPhotos: json['after_photos'] != null
          ? (json['after_photos'] as List).map((e) => e.toString()).toList()
          : null,
      isCustom: json['is_custom'] as bool? ?? false,
      reportIds: json['report_ids'] != null
          ? (json['report_ids'] as List).map((e) => e.toString()).toList()
          : null,
    );
  }
}

class CleanupTasksNotifier extends ChangeNotifier {
  final ApiClient _apiClient;
  AsyncValue<List<CleanupTask>> _tasks = const AsyncValue.loading();

  CleanupTasksNotifier(this._apiClient) {
    loadTasks();
  }

  AsyncValue<List<CleanupTask>> get tasks => _tasks;

  Future<void> loadTasks() async {
    _tasks = const AsyncValue.loading();
    notifyListeners();
    try {
      final response = await _apiClient.getCleanupTasks();
      final List<dynamic> data = response.data is List 
          ? response.data as List<dynamic>
          : [];
      final tasks = data.map((json) => CleanupTask.fromJson(json as Map<String, dynamic>)).toList();
      _tasks = AsyncValue.data(tasks);
      notifyListeners();
    } catch (e, stackTrace) {
      _tasks = AsyncValue.error(e, stackTrace);
      notifyListeners();
    }
  }

  void reset() {
    _tasks = const AsyncValue.loading();
    notifyListeners();
  }
}

final officerCleanupTasksProvider = ChangeNotifierProvider<CleanupTasksNotifier>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CleanupTasksNotifier(apiClient);
});

