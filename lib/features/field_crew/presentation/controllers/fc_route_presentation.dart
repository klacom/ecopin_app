import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:ecopin_app/features/field_crew/data/models/cleanup_task_model.dart';
import 'package:ecopin_app/features/field_crew/data/models/route_model.dart';
import 'package:ecopin_app/features/field_crew/data/models/waypoint_model.dart';
import 'fc_dashboard_presentation.dart';

/// Close enough to the destination pin to offer “Open this job”. It comes from
/// this phone's GPS and never completes or changes anything.
const crewArrivalMeters = 30.0;

String crewFormatDistance(num? meters) {
  if (meters == null) return '—';
  if (meters >= 1000) return '${(meters / 1000).toStringAsFixed(1)} km';
  return '${meters.round()} m';
}

String crewFormatDuration(num? minutes) {
  if (minutes == null) return '—';
  final h = (minutes / 60).floor();
  final m = (minutes % 60).round();
  return h > 0 ? '${h}h ${m}m' : '${m}m';
}

/// “2.4 km · about 35 min”, or null when neither is known.
String? crewRouteTotals(num? meters, num? minutes) {
  final parts = [
    if (meters != null) crewFormatDistance(meters),
    if (minutes != null) 'about ${crewFormatDuration(minutes)}',
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}

bool crewIsNearDestination(LatLng? position, LatLng destination) =>
    position != null &&
    const Distance().as(LengthUnit.Meter, position, destination) <=
        crewArrivalMeters;

/// Arrow for the next turn, from the OSRM maneuver modifier.
IconData crewTurnIcon(Map<String, dynamic>? step) {
  final maneuver = step?['maneuver'] as Map? ?? const {};
  if (maneuver['type'] == 'arrive') return Icons.flag_outlined;
  return switch (maneuver['modifier']?.toString()) {
    'left' => Icons.turn_left,
    'right' => Icons.turn_right,
    'slight left' || 'slight_left' => Icons.turn_slight_left,
    'slight right' || 'slight_right' => Icons.turn_slight_right,
    'sharp left' || 'sharp_left' => Icons.turn_sharp_left,
    'sharp right' || 'sharp_right' => Icons.turn_sharp_right,
    'uturn' => Icons.u_turn_left,
    _ => Icons.straight,
  };
}

enum CrewStopState { next, inProgress, todo, held, markedDone, done, cancelled }

/// One route stop for the “All stops” list, in published sequence.
class CrewStopRow {
  const CrewStopRow({
    required this.number,
    required this.task,
    required this.waypoint,
    required this.state,
  });
  final int number;
  final CleanupTask task;
  final WaypointModel waypoint;
  final CrewStopState state;

  bool get finished =>
      state == CrewStopState.done ||
      state == CrewStopState.cancelled ||
      state == CrewStopState.markedDone;

  String get label => switch (state) {
    CrewStopState.next => 'Next',
    CrewStopState.inProgress => 'In progress',
    CrewStopState.todo => 'To do',
    CrewStopState.held => 'On hold on this phone',
    CrewStopState.markedDone => 'Marked done on this phone',
    CrewStopState.done => 'Done',
    CrewStopState.cancelled => 'Cancelled',
  };

  String get place => crewTaskPlaceLine(task);
}

List<CrewStopRow> crewRouteStops({
  required RouteModel route,
  required List<CleanupTask> tasks,
  required Set<String> completed,
  required Set<String> held,
  String? nextTaskId,
}) {
  final stops =
      route.waypoints
          .where((w) => w.waypointType == 'task' && w.cleanupTaskId != null)
          .toList()
        ..sort((a, b) => a.sequenceOrder.compareTo(b.sequenceOrder));
  final rows = <CrewStopRow>[];
  for (final stop in stops) {
    final task = tasks.where((t) => t.id == stop.cleanupTaskId).firstOrNull;
    if (task == null) continue;
    final status = crewTaskKey(task.status);
    final state = status == 'completed'
        ? CrewStopState.done
        : status == 'cancelled'
        ? CrewStopState.cancelled
        : completed.contains(task.id)
        ? CrewStopState.markedDone
        : held.contains(task.id)
        ? CrewStopState.held
        : task.id == nextTaskId
        ? CrewStopState.next
        : status == 'in_progress'
        ? CrewStopState.inProgress
        : CrewStopState.todo;
    rows.add(
      CrewStopRow(
        number: stop.sequenceOrder,
        task: task,
        waypoint: stop,
        state: state,
      ),
    );
  }
  return rows;
}

/// Where the directions on screen came from.
enum CrewDirectionsSource {
  /// Fetched from the internet when the job started.
  live,

  /// A saved copy, because the internet request did not work.
  savedAfterFailure,

  /// A saved copy, because the phone has no signal.
  savedOffline,
}

/// What the directions banner says about its source: a bold headline that names
/// one source, and a sentence about what that means for the crew.
class CrewDirectionsStatus {
  const CrewDirectionsStatus({
    required this.source,
    required this.title,
    required this.detail,
    required this.icon,
  });

  final CrewDirectionsSource source;
  final String title;
  final String detail;
  final IconData icon;
}

CrewDirectionsStatus crewDirectionsStatus({
  required bool usingSaved,
  required bool liveFailed,
  required bool hasTurnSteps,
  required bool copySaved,
}) {
  if (!usingSaved) {
    return CrewDirectionsStatus(
      source: CrewDirectionsSource.live,
      title: 'Online · live directions',
      detail: copySaved
          ? 'A copy is also saved on this phone for when you have no signal.'
          : 'A copy could not be saved on this phone.',
      icon: Icons.wifi,
    );
  }
  final detail = hasTurnSteps
      ? 'Using a copy saved earlier. Turns will not update.'
      : 'Showing the saved route line only. There are no turn directions.';
  if (liveFailed) {
    return CrewDirectionsStatus(
      source: CrewDirectionsSource.savedAfterFailure,
      title: 'Saved directions · live did not load',
      detail: detail,
      icon: Icons.history,
    );
  }
  return CrewDirectionsStatus(
    source: CrewDirectionsSource.savedOffline,
    title: 'Offline · saved directions',
    detail: detail,
    icon: Icons.cloud_off_outlined,
  );
}
