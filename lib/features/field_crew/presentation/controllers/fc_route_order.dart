import 'package:latlong2/latlong.dart';
import 'package:ecopin_app/features/field_crew/data/models/cleanup_task_model.dart';
import 'package:ecopin_app/features/field_crew/data/models/route_model.dart';
import 'package:ecopin_app/features/field_crew/data/models/waypoint_model.dart';

/// How the Route screen chooses the crew's next job.
enum CrewRouteOrder {
  /// Published route order, which puts the most urgent work first.
  priority,

  /// Closest stop to the crew's current position first.
  nearest,
}

extension CrewRouteOrderLabel on CrewRouteOrder {
  String get label => switch (this) {
    CrewRouteOrder.priority => 'Priority',
    CrewRouteOrder.nearest => 'Nearest',
  };
}

class CrewNextStop {
  const CrewNextStop({
    required this.task,
    required this.waypoint,
    this.distanceMeters,
  });

  final CleanupTask task;
  final WaypointModel waypoint;

  /// Straight-line distance from the crew's position. Only set when the
  /// stop was chosen by proximity; it is not a road distance.
  final double? distanceMeters;
}

/// Picks the next unfinished, non-held task that has a stop on [route].
///
/// [CrewRouteOrder.nearest] needs [origin]; without a GPS fix it falls back to
/// the published order rather than guessing.
CrewNextStop? pickNextCrewStop({
  required List<CleanupTask> tasks,
  required RouteModel route,
  required Set<String> completed,
  required Set<String> held,
  required CrewRouteOrder order,
  LatLng? origin,
}) {
  final stops = <CrewNextStop>[];
  for (final task in tasks) {
    final status = task.status.toLowerCase();
    if (status == 'completed' ||
        status == 'cancelled' ||
        completed.contains(task.id) ||
        held.contains(task.id)) {
      continue;
    }
    final waypoint = route.waypoints
        .where((w) => w.cleanupTaskId == task.id)
        .firstOrNull;
    if (waypoint != null) {
      stops.add(CrewNextStop(task: task, waypoint: waypoint));
    }
  }
  if (stops.isEmpty) return null;

  stops.sort(
    (a, b) => a.waypoint.sequenceOrder.compareTo(b.waypoint.sequenceOrder),
  );
  if (order == CrewRouteOrder.priority || origin == null) return stops.first;

  const distance = Distance();
  CrewNextStop? nearest;
  for (final stop in stops) {
    final lat = stop.waypoint.latitude;
    final lng = stop.waypoint.longitude;
    if (lat == null || lng == null) continue;
    final meters = distance.as(LengthUnit.Meter, origin, LatLng(lat, lng));
    // Strict comparison keeps the published order for equal distances.
    if (nearest == null || meters < nearest.distanceMeters!) {
      nearest = CrewNextStop(
        task: stop.task,
        waypoint: stop.waypoint,
        distanceMeters: meters,
      );
    }
  }
  // No stop has coordinates: keep the published order.
  return nearest ?? stops.first;
}
