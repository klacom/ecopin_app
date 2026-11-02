import 'package:ecopin_app/features/field_crew/data/models/cleanup_task_model.dart';
import 'package:ecopin_app/features/field_crew/data/models/route_model.dart';

String crewTaskKey(String value) =>
    value.trim().toLowerCase().replaceAll(' ', '_');
String crewTaskLabel(String value) {
  final label = value.trim().replaceAll('_', ' ').toLowerCase();
  return label.isEmpty
      ? 'Unavailable'
      : '${label[0].toUpperCase()}${label.substring(1)}';
}

String crewTaskPath(String id) =>
    '/field-crew/tasks/${Uri.encodeComponent(id)}';

/// The crew's established order of work: in progress first, then route stop
/// order, then high/urgent priority, then oldest first. Sorts [tasks] in place.
void sortCrewTasks(List<CleanupTask> tasks, {RouteModel? route}) {
  final order = <String, int>{};
  for (final stop in route?.waypoints ?? []) {
    if (stop.cleanupTaskId != null) {
      order[stop.cleanupTaskId!] = stop.sequenceOrder;
    }
  }
  tasks.sort((a, b) {
    if (a.status == 'in_progress' && b.status != 'in_progress') return -1;
    if (b.status == 'in_progress' && a.status != 'in_progress') return 1;
    final routeOrder = (order[a.id] ?? 9999).compareTo(order[b.id] ?? 9999);
    if (routeOrder != 0) return routeOrder;
    final aHigh = {'high', 'urgent'}.contains(a.priority.toLowerCase());
    final bHigh = {'high', 'urgent'}.contains(b.priority.toLowerCase());
    if (aHigh != bHigh) return aHigh ? -1 : 1;
    return a.createdAt.compareTo(b.createdAt);
  });
}

List<CleanupTask> orderedCrewTasks(
  List<CleanupTask> tasks, {
  RouteModel? route,
  Set<String> held = const {},
  Set<String> locallyCompleted = const {},
}) {
  final active = tasks
      .where(
        (task) =>
            !{'completed', 'cancelled'}.contains(crewTaskKey(task.status)) &&
            !held.contains(task.id) &&
            !locallyCompleted.contains(task.id),
      )
      .toList();
  sortCrewTasks(active, route: route);
  return active;
}

final _coordinatePair = RegExp(r'^-?\d+(\.\d+)?, -?\d+(\.\d+)?$');

/// Where a job is, in words a crew member can act on. A street address wins;
/// bare coordinates are labelled as a map pin rather than shown as the address.
({String primary, String? detail}) crewTaskPlace(CleanupTask task) {
  final address = task.streetAddress?.trim();
  if (address != null && address.isNotEmpty) {
    return (primary: address, detail: null);
  }
  final location = crewTaskLocation(task);
  if (_coordinatePair.hasMatch(location)) {
    return (primary: 'Address not provided', detail: 'Map pin $location');
  }
  return (primary: location, detail: null);
}

/// One-line place for compact lists.
String crewTaskPlaceLine(CleanupTask task) {
  final place = crewTaskPlace(task);
  return place.detail ?? place.primary;
}

String crewTaskLocation(CleanupTask task) {
  final address = task.streetAddress?.trim();
  if (address != null && address.isNotEmpty) return address;
  double? latitude, longitude;
  if (task.reports?.isNotEmpty == true) {
    latitude = task.reports!.first.location.latitude;
    longitude = task.reports!.first.location.longitude;
  } else {
    final point = RegExp(
      r'^POINT\s*\(\s*([^\s]+)\s+([^\s]+)\s*\)$',
      caseSensitive: false,
    ).firstMatch(task.location.trim());
    if (point != null) {
      longitude = double.tryParse(point[1]!);
      latitude = double.tryParse(point[2]!);
    }
  }
  if (latitude != null &&
      longitude != null &&
      latitude.isFinite &&
      longitude.isFinite &&
      latitude.abs() <= 90 &&
      longitude.abs() <= 180 &&
      (latitude != 0 || longitude != 0)) {
    return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  }
  final location = task.location.trim();
  return location.isEmpty ||
          location.toLowerCase() == 'unknown location' ||
          location.toUpperCase().startsWith('POINT')
      ? 'Location unavailable'
      : location;
}
