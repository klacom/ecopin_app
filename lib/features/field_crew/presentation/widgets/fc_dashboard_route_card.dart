import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ecopin_app/features/field_crew/data/models/cleanup_task_model.dart';
import 'package:ecopin_app/features/field_crew/data/models/route_model.dart';
import 'package:ecopin_app/routes/app_routes.dart';

class FcDashboardRouteCard extends StatelessWidget {
  const FcDashboardRouteCard({
    super.key,
    required this.route,
    this.currentTask,
  });
  final RouteModel? route;
  final CleanupTask? currentTask;
  @override
  Widget build(BuildContext context) {
    final stops = route?.waypoints
        .where(
          (stop) => !{'depot_start', 'depot_end'}.contains(stop.waypointType),
        )
        .toList();
    stops?.sort((a, b) => a.sequenceOrder.compareTo(b.sequenceOrder));
    final reportIds = {
      ...?currentTask?.reportIds,
      ...?currentTask?.reports?.map((report) => report.id),
    };
    final matching = stops
        ?.where(
          (stop) =>
              currentTask != null &&
              (stop.cleanupTaskId == currentTask!.id ||
                  reportIds.contains(stop.reportId)),
        )
        .toList();
    final next = matching?.firstOrNull;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.map_outlined),
      title: const Text('Route overview'),
      subtitle: Text(
        route == null
            ? 'No route loaded. Check task instructions.'
            : '${stops!.length} stops${next == null ? '' : ' · Stop ${next.sequenceOrder} for current task'}',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.go(FieldCrewAppRoutes.map),
    );
  }
}
