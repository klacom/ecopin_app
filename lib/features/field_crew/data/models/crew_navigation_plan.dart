import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

class CrewNavigationPlan {
  final List<LatLng> points;
  final List<Map<String, dynamic>> steps;
  final double? distanceMeters;
  final double? durationMinutes;
  const CrewNavigationPlan({
    required this.points,
    this.steps = const [],
    this.distanceMeters,
    this.durationMinutes,
  });

  static LatLng coordinate(dynamic value) {
    if (value is! List ||
        value.length < 2 ||
        value[0] is! num ||
        value[1] is! num) {
      throw const FormatException('Invalid route coordinate');
    }
    final lon = (value[0] as num).toDouble(),
        lat = (value[1] as num).toDouble();
    if (!lat.isFinite || !lon.isFinite || lat.abs() > 90 || lon.abs() > 180) {
      throw const FormatException('Invalid route coordinate');
    }
    return LatLng(lat, lon);
  }

  factory CrewNavigationPlan.fromOsrm(Map<String, dynamic> data) {
    if (data['code'] != 'Ok' ||
        data['routes'] is! List ||
        (data['routes'] as List).isEmpty) {
      throw const FormatException('No road route returned');
    }
    final route = data['routes'][0] as Map;
    final points = (route['geometry']['coordinates'] as List)
        .map(coordinate)
        .toList();
    if (points.length < 2 || points.every((point) => point == points.first)) {
      throw const FormatException('No usable road geometry');
    }
    final steps = <Map<String, dynamic>>[];
    for (final leg in route['legs'] as List? ?? const []) {
      for (final raw in leg['steps'] as List? ?? const []) {
        final step = Map<String, dynamic>.from(raw as Map);
        coordinate(step['maneuver']['location']);
        steps.add(step);
      }
    }
    if (steps.isEmpty) {
      throw const FormatException('No turn directions returned');
    }
    final distance = (route['distance'] as num?)?.toDouble();
    final duration = (route['duration'] as num?)?.toDouble();
    if ((distance != null && (!distance.isFinite || distance < 0)) ||
        (duration != null && (!duration.isFinite || duration < 0))) {
      throw const FormatException('Invalid route estimates');
    }
    return CrewNavigationPlan(
      points: points,
      steps: steps,
      distanceMeters: distance,
      durationMinutes: duration == null ? null : duration / 60,
    );
  }

  Map<String, dynamic> toJson() => {
    'code': 'Ok',
    'routes': [
      {
        'geometry': {
          'coordinates': points.map((p) => [p.longitude, p.latitude]).toList(),
        },
        'legs': [
          {'steps': steps},
        ],
        'distance': distanceMeters,
        'duration': durationMinutes == null ? null : durationMinutes! * 60,
      },
    ],
  };

  /// Project onto segments, rather than skipping a long road between sparse vertices.
  ({int segment, double fraction, LatLng point, double distance}) nearest(
    LatLng origin,
  ) {
    if (points.length < 2) throw const FormatException('No saved road path');
    var best = (
      segment: 0,
      fraction: 0.0,
      point: points.first,
      distance: double.infinity,
    );
    final scale = math.cos(origin.latitude * math.pi / 180);
    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i], b = points[i + 1];
      final ax = (a.longitude - origin.longitude) * scale,
          ay = a.latitude - origin.latitude;
      final dx = (b.longitude - a.longitude) * scale,
          dy = b.latitude - a.latitude;
      final length = dx * dx + dy * dy;
      final t = length == 0
          ? 0.0
          : (-(ax * dx + ay * dy) / length).clamp(0.0, 1.0);
      final point = LatLng(
        a.latitude + (b.latitude - a.latitude) * t,
        a.longitude + (b.longitude - a.longitude) * t,
      );
      final distance = const Distance().as(LengthUnit.Meter, origin, point);
      if (distance < best.distance) {
        best = (segment: i, fraction: t, point: point, distance: distance);
      }
    }
    return best;
  }

  CrewNavigationPlan fromPosition(LatLng origin) {
    final snap = nearest(origin);
    if (snap.distance > 100) {
      throw const FormatException(
        'You are away from the saved route. Reconnect to calculate directions from here.',
      );
    }
    final remaining = <LatLng>[snap.point];
    for (final p in points.skip(snap.segment + 1)) {
      if (const Distance().as(LengthUnit.Meter, remaining.last, p) > 0.5) {
        remaining.add(p);
      }
    }
    if (remaining.length < 2) {
      throw const FormatException(
        'You are at this stop. Open the task to continue.',
      );
    }
    final upcoming = steps.where((step) {
      final point = coordinate(step['maneuver']['location']);
      final at = nearest(point);
      return at.segment > snap.segment ||
          (at.segment == snap.segment && at.fraction >= snap.fraction) ||
          const Distance().as(LengthUnit.Meter, snap.point, point) <= 15;
    }).toList();
    var distance = 0.0;
    for (var i = 1; i < remaining.length; i++) {
      distance += const Distance().as(
        LengthUnit.Meter,
        remaining[i - 1],
        remaining[i],
      );
    }
    return CrewNavigationPlan(
      points: remaining,
      steps: upcoming,
      distanceMeters: distance,
    );
  }
}

String crewTurnInstruction(Map<String, dynamic> step) {
  final maneuver = step['maneuver'] as Map? ?? const {};
  final modifier = maneuver['modifier']?.toString().replaceAll('_', ' ') ?? '';
  final name = step['name']?.toString().trim() ?? '';
  final onto = name.isEmpty ? '' : ' onto $name';
  return switch (maneuver['type']) {
    'depart' => modifier.isEmpty ? 'Head$onto' : 'Head $modifier$onto',
    'arrive' => 'Arrive at your destination',
    'turn' => 'Turn ${modifier.isEmpty ? 'ahead' : modifier}$onto',
    'roundabout' || 'rotary' =>
      'At the roundabout, take ${maneuver['exit'] == null ? 'the exit' : 'exit ${maneuver['exit']}'}$onto',
    'merge' => 'Merge${modifier.isEmpty ? '' : ' $modifier'}$onto',
    _ => 'Continue${modifier.isEmpty ? '' : ' $modifier'}$onto',
  };
}
