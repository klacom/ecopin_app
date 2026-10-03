class PolylinePoint {
  final double latitude;
  final double longitude;

  PolylinePoint({required this.latitude, required this.longitude});

  factory PolylinePoint.fromJson(Map<String, dynamic> json) {
    return PolylinePoint(
      latitude: double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class WaypointModel {
  final String waypointType;
  final String? cleanupTaskId;
  final int sequenceOrder;
  final num? distanceFromPreviousMeters;
  final num? estimatedTimeFromPreviousMin;
  final double? latitude;
  final double? longitude;
  final List<PolylinePoint> polyline;

  WaypointModel({
    required this.waypointType,
    this.cleanupTaskId,
    required this.sequenceOrder,
    this.distanceFromPreviousMeters,
    this.estimatedTimeFromPreviousMin,
    this.latitude,
    this.longitude,
    this.polyline = const [],
  });

  factory WaypointModel.fromJson(Map<String, dynamic> json) {
    var polylineJson = json['polyline'] as List<dynamic>?;
    List<PolylinePoint> parsedPolyline = [];
    if (polylineJson != null) {
      parsedPolyline = polylineJson
          .map((p) => PolylinePoint.fromJson(p as Map<String, dynamic>))
          .toList();
    }

    return WaypointModel(
      waypointType: json['waypoint_type']?.toString() ?? '',
      cleanupTaskId: json['cleanup_task_id']?.toString(),
      sequenceOrder: json['sequence_order'] as int? ?? 0,
      distanceFromPreviousMeters: json['distance_from_previous_meters'] as num?,
      estimatedTimeFromPreviousMin: json['estimated_time_from_previous_min'] as num?,
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      polyline: parsedPolyline,
    );
  }
}
