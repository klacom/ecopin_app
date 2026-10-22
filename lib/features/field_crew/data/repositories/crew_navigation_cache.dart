import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/crew_navigation_plan.dart';

/// Keep only the last downloaded destination per signed-in account.
class CrewNavigationCache {
  static Future<void> save(
    String owner,
    String route,
    String task,
    LatLng destination,
    CrewNavigationPlan plan,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setString(
      'fc_navigation_v1:$owner',
      jsonEncode({
        'route': route,
        'task': task,
        'destination': [destination.longitude, destination.latitude],
        'directions': plan.toJson(),
      }),
    );
    if (!saved) throw StateError('Could not save offline directions');
  }

  static Future<CrewNavigationPlan?> load(
    String owner,
    String route,
    String task,
    LatLng destination,
    LatLng origin,
  ) async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(
        'fc_navigation_v1:$owner',
      );
      if (raw == null) return null;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      if (data['route'] != route ||
          data['task'] != task ||
          const Distance().as(
                LengthUnit.Meter,
                destination,
                CrewNavigationPlan.coordinate(data['destination']),
              ) >
              10) {
        return null;
      }
      return CrewNavigationPlan.fromOsrm(
        Map<String, dynamic>.from(data['directions']),
      ).fromPosition(origin);
    } catch (_) {
      return null;
    }
  }
}
