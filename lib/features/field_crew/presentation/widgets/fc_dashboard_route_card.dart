import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ecopin_app/core/theme/colors.dart';
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
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        side: BorderSide(color: theme.dividerTheme.color ?? theme.dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        minVerticalPadding: 12,
        leading: const Icon(Icons.map_outlined, size: 28),
        title: const Text('Route overview'),
        subtitle: Text(
          route == null
              ? 'No route loaded. Check your job instructions.'
              : '${stops!.length} stops${next == null ? '' : ' · Stop ${next.sequenceOrder} for your job now'}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.go(FieldCrewAppRoutes.map),
      ),
    );
  }
}
