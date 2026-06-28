import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logging/logging.dart';

class CameraService {
  final ImagePicker _picker = ImagePicker();
  final Logger camServiceLog = Logger("Camera Service");

  Future<bool> _checkCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<bool> _checkLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  Future<Map<String, dynamic>?> captureImage() async {
    // Check camera permission
    final hasCameraPermission = await _checkCameraPermission();
    if (!hasCameraPermission) {
      throw Exception('Camera permission denied');
    }

    // Check location permission for metadata
    final hasLocationPermission = await _checkLocationPermission();
    
    // Capture image from camera only (no gallery)
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (image == null) {
      return null;
    }

    final LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 1, // 1 Meter 
    );

    // Get current location for metadata
    Map<String, dynamic>? locationData;
    if (hasLocationPermission) {
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: locationSettings
        );
        locationData = {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
          'timestamp': position.timestamp.toIso8601String(),
        };
      } catch (e) {
        camServiceLog.severe('Error getting location: $e');
      }
    }

    return {
      'file': File(image.path),
      'path': image.path,
      'name': image.name,
      'location': locationData,
      'capturedAt': DateTime.now().toIso8601String(),
    };
  }
}
