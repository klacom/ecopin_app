import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ecopin_app/features/field_crew/data/models/cleanup_task_model.dart';
import 'package:ecopin_app/features/field_crew/data/models/route_model.dart';
import 'package:ecopin_app/routes/app_routes.dart';
import 'fc_offline_ui.dart';

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
    final distance = route?.totalDistanceMeters,
        duration = route?.totalDurationMin;
    return FcOfflineCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Route overview',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          if (route == null)
            const Text(
              'No route is available in the loaded records. The task details still contain its assigned instructions.',
            )
          else ...[
            Text(
              '${stops!.length} stops in the supplied route.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (next != null)
              FcOfflineFact(
                'Next recorded stop for the current task',
                'Stop ${next.sequenceOrder}${next.reportId == null ? '' : ' · report stop'}',
              )
            else
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'No route stop matches the current task in the loaded records. Review the map and task instructions.',
                ),
              ),
            if (distance != null && distance.isFinite && distance > 0)
              FcOfflineFact(
                'Dispatch distance estimate',
                '${(distance / 1000).toStringAsFixed(1)} km',
              ),
            if (duration != null && duration.isFinite && duration > 0)
              FcOfflineFact(
                'Dispatch duration estimate',
                '${duration.toStringAsFixed(0)} minutes',
              ),
            const SizedBox(height: 12),
            Text(
              'Estimates describe the supplied route, not live travel time or remaining work. Map tiles may need a connection.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => context.go(FieldCrewAppRoutes.map),
            icon: const Icon(Icons.map_outlined),
            label: const Text('Open route map'),
          ),
        ],
      ),
    );
  }
}
