import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/features/field_crew/data/models/route_model.dart';
import 'package:ecopin_app/features/field_crew/providers/cleanup_tasks_provider.dart';
import 'package:ecopin_app/features/field_crew/providers/field_crew_reports_provider.dart';
import 'package:ecopin_app/core/database/app_database.dart';

final activeRoutesProvider = FutureProvider<List<RouteModel>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final db = ref.watch(databaseProvider);
  
  try {
    final response = await apiClient.getActiveRoutes();
    
    if (response.data['routes'] == null) return [];
    
    final routesData = response.data['routes'] as List<dynamic>;
    
    // Cache routes for offline use
    for (final routeJson in routesData) {
      final id = routeJson['id']?.toString();
      if (id != null) {
        await db.cacheFcRoute(id, jsonEncode(routeJson));
      }
    }
    
    return routesData.map((e) => RouteModel.fromJson(e)).toList();
  } catch (e) {
    // Fallback to local cache when offline
    final cachedRoutes = await db.getAllFcRoutes();
    if (cachedRoutes.isNotEmpty) {
      return cachedRoutes.map((cr) {
        final Map<String, dynamic> json = jsonDecode(cr.jsonData);
        return RouteModel.fromJson(json);
      }).toList();
    }
    
    return [];
  }
});

final myRouteProvider = FutureProvider<RouteModel?>((ref) async {
  final activeRoutes = await ref.watch(activeRoutesProvider.future);
  final assignedTasks = await ref.watch(myCleanupTasksProvider.future);
  final reports = await ref.watch(fieldCrewReportsProvider.future);
  final heldTasks = ref.watch(heldTasksProvider);

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
        final route = activeRoutes.firstWhere((r) => r.id == crewRouteId);
        final settledReports = reports
            .where((report) => const {
                  'resolved', 'completed', 'closed', 'rejected',
                }.contains(report.status.toLowerCase()))
            .map((report) => report.id)
            .toSet();
        final cancelledTasks = assignedTasks
            .where((task) => task.status.toLowerCase() == 'cancelled')
            .map((task) => task.id)
            .toSet();
        return RouteModel(
          id: route.id,
          crewName: route.crewName,
          waypoints: route.waypoints
              .where((waypoint) => waypoint.reportId == null ||
                  !settledReports.contains(waypoint.reportId))
              .where((waypoint) => waypoint.cleanupTaskId == null ||
                  (!heldTasks.contains(waypoint.cleanupTaskId) &&
                      !cancelledTasks.contains(waypoint.cleanupTaskId)))
              .toList(),
          totalDistanceMeters: route.totalDistanceMeters,
          totalDurationMin: route.totalDurationMin,
          startDepot: route.startDepot,
        );
      } catch (e) {
        // Not found
      }
    }
  }

  return null;
});
