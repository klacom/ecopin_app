import 'waypoint_model.dart';
import 'package:latlong2/latlong.dart';

class RouteModel {
  final String id;
  final String crewName;
  final List<WaypointModel> waypoints;
  final num? totalDistanceMeters;
  final num? totalDurationMin;
  final LatLng? startDepot;

  RouteModel({
    required this.id,
    required this.crewName,
    required this.waypoints,
    this.totalDistanceMeters,
    this.totalDurationMin,
    this.startDepot,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    LatLng? depot;
    if (json['start_depot'] != null && json['start_depot'] is String && json['start_depot'].startsWith('POINT')) {
      final parts = json['start_depot'].replaceAll('POINT(', '').replaceAll(')', '').split(' ');
      if (parts.length == 2) {
        depot = LatLng(double.parse(parts[1]), double.parse(parts[0]));
      }
    }

    final waypointsList = json['waypoints'] as List<dynamic>? ?? [];

    return RouteModel(
      id: json['id']?.toString() ?? '',
      crewName: json['field_crews']?['name']?.toString() ?? 'My Crew',
      waypoints: waypointsList.map((e) => WaypointModel.fromJson(e as Map<String, dynamic>)).toList(),
      totalDistanceMeters: json['total_distance_meters'] as num?,
      totalDurationMin: json['total_duration_min'] as num?,
      startDepot: depot,
    );
  }
}
