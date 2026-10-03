import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/core/services/cache_service.dart';
import 'package:ecopin_app/features/field_crew/data/models/cleanup_task_model.dart';
import 'package:ecopin_app/features/field_crew/data/repositories/cleanup_task_repository.dart';

import 'package:ecopin_app/features/field_crew/providers/fc_local_repository_provider.dart';

final cleanupTaskRepositoryProvider = Provider<CleanupTaskRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final cacheService = ref.watch(cacheServiceProvider);
  final fcLocal = ref.watch(fcLocalRepositoryProvider);
  final fcLocalPhoto = ref.watch(fcLocalPhotoRepositoryProvider);
  return CleanupTaskRepository(apiClient, cacheService, fcLocal, fcLocalPhoto);
});

final allCleanupTasksProvider = FutureProvider<List<CleanupTask>>((ref) {
  final repository = ref.watch(cleanupTaskRepositoryProvider);
  return repository.fetchAllTasks();
});

final myCleanupTasksProvider = FutureProvider<List<CleanupTask>>((ref) {
  final repository = ref.watch(cleanupTaskRepositoryProvider);
  return repository.fetchMyTasks();
});

class CompletedTasksNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void addCompletedTask(String taskId) {
    state = {...state, taskId};
  }
}

final completedTasksProvider = NotifierProvider<CompletedTasksNotifier, Set<String>>(() => CompletedTasksNotifier());