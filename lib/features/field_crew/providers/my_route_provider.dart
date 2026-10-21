import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/features/field_crew/data/models/route_model.dart';
import 'package:ecopin_app/features/field_crew/providers/cleanup_tasks_provider.dart';
import 'package:ecopin_app/features/field_crew/providers/field_crew_reports_provider.dart';
import 'package:ecopin_app/core/database/app_database.dart';
import 'package:ecopin_app/features/field_crew/presentation/controllers/fc_dashboard_presentation.dart';

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

    rethrow;
  }
});

final myRouteProvider = FutureProvider<RouteModel?>((ref) async {
  final activeRoutes = await ref.watch(activeRoutesProvider.future);
  final assignedTasks = await ref.watch(myCleanupTasksProvider.future);
  final reports = await ref.watch(fieldCrewReportsProvider.future);
  final heldTasks = ref.watch(heldTasksProvider);
  final completedTasks = ref.watch(completedTasksProvider);

  if (activeRoutes.isEmpty) return null;

  final byId = {for (final route in activeRoutes) route.id: route};
  final ordered = orderedCrewTasks(
    assignedTasks,
    held: heldTasks,
    locallyCompleted: completedTasks,
  );
  for (final task in ordered) {
    final route = byId[task.crewRouteId];
    if (route != null) {
      final settledReports = reports
          .where(
            (report) => const {
              'resolved',
              'completed',
              'closed',
              'rejected',
            }.contains(report.status.toLowerCase()),
          )
          .map((report) => report.id)
          .toSet();
      final cancelledTasks = assignedTasks
          .where(
            (task) =>
                {
                  'completed',
                  'cancelled',
                }.contains(task.status.toLowerCase()) ||
                completedTasks.contains(task.id),
          )
          .map((task) => task.id)
          .toSet();
      return RouteModel(
        id: route.id,
        crewName: route.crewName,
        waypoints: route.waypoints
            .where(
              (waypoint) =>
                  waypoint.reportId == null ||
                  !settledReports.contains(waypoint.reportId),
            )
            .where(
              (waypoint) =>
                  waypoint.cleanupTaskId == null ||
                  (!heldTasks.contains(waypoint.cleanupTaskId) &&
                      !cancelledTasks.contains(waypoint.cleanupTaskId)),
            )
            .toList(),
        totalDistanceMeters: route.totalDistanceMeters,
        totalDurationMin: route.totalDurationMin,
        startDepot: route.startDepot,
      );
    }
  }

  return null;
});
