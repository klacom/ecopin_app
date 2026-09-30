import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/features/field_crew/data/models/route_model.dart';
import 'package:ecopin_app/features/field_crew/providers/cleanup_tasks_provider.dart';

final activeRoutesProvider = FutureProvider<List<RouteModel>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.getActiveRoutes();
  
  if (response.data['routes'] == null) return [];
  
  final routesData = response.data['routes'] as List<dynamic>;
  return routesData.map((e) => RouteModel.fromJson(e)).toList();
});

final myRouteProvider = FutureProvider<RouteModel?>((ref) async {
  final activeRoutes = await ref.watch(activeRoutesProvider.future);
  final assignedTasks = await ref.watch(myCleanupTasksProvider.future);

  if (activeRoutes.isEmpty) return null;

  // Find which route belongs to the user
  if (assignedTasks.isNotEmpty) {
    // Tasks should have a `crew_route_id`
    // Let's look for the first task that has a crew_route_id
    String? crewRouteId;
    for (var task in assignedTasks) {
      if (task.crewRouteId != null && task.crewRouteId!.isNotEmpty) {
        crewRouteId = task.crewRouteId;
        break;
      }
    }
    
    if (crewRouteId != null) {
      try {
        return activeRoutes.firstWhere((r) => r.id == crewRouteId);
      } catch (e) {
        // Not found
      }
    }
  }

  return null;
});
