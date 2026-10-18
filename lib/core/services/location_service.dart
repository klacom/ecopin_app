import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:logging/logging.dart';

class LocationService {
  static final Logger locServiceLog = Logger("Location Service");

  // Fetches the current GPS location of the user.
  // Returns null if permissions are denied or service is disabled.

  static Future<LatLng?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      locServiceLog.info("Service Disabled");
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    // 1. Try high accuracy with a 10s timeout
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      locServiceLog.warning("High accuracy position timed out or failed: $e. Trying fallback...");
    }

    // 2. Fallback to last known position
    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        locServiceLog.info("Using last known position");
        return LatLng(lastKnown.latitude, lastKnown.longitude);
      }
    } catch (_) {}

    // 3. Fallback to medium accuracy with a 6s timeout
    try {
      final fallbackPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 6),
        ),
      );
      return LatLng(fallbackPosition.latitude, fallbackPosition.longitude);
    } catch (e) {
      locServiceLog.severe("All location attempts failed: $e");
      return null;
    }
  }

  // Returns a stream of the user's location updates.
  static Stream<LatLng>? getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Update every 5 meters
      ),
    ).map((position) => LatLng(position.latitude, position.longitude));
  }
}
