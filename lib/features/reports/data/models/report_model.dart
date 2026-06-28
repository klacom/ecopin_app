import 'package:latlong2/latlong.dart';
import 'package:geobase/geobase.dart';
import 'package:logging/logging.dart';

class ReportModel {
  final String id;
  final String? userId;
  final String title;
  final String? description;
  final String? issueType;
  final LatLng location;
  final String validationStatus;
  final String status;
  final String? clusterId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? userFullName;

  ReportModel({
    required this.id,
    this.userId,
    required this.title,
    this.description,
    this.issueType,
    required this.location,
    required this.validationStatus,
    required this.status,
    this.clusterId,
    required this.createdAt,
    required this.updatedAt,
    this.userFullName,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    LatLng latLng;
    final Logger _log = Logger("Report Model");

    // 1. Try direct latitude/longitude (from reports_view)
    if (json.containsKey('latitude') &&
        json.containsKey('longitude') &&
        json['latitude'] != null) {
      latLng = LatLng(
        (json['latitude'] as num).toDouble(),
        (json['longitude'] as num).toDouble(),
      );
    }

    // 2. Try GeoJSON location (from updated reports_view)
    else if (json['location'] != null &&
        json['location'] is Map &&
        json['location']['type'] == 'Point') {
      final coords = json['location']['coordinates'] as List;
      latLng = LatLng(coords[1].toDouble(), coords[0].toDouble());
    }

    // 3. Fallback for raw POINT string
    else if (json['location'] != null &&
        json['location'] is String &&
        json['location'].startsWith('POINT')) {
      final parts = json['location']
          .replaceAll('POINT(', '')
          .replaceAll(')', '')
          .split(' ');
      latLng = LatLng(double.parse(parts[1]), double.parse(parts[0]));
    }

    // 4. Handle EWKB hex string (common in Supabase Realtime stream)
    else if (json['location'] != null && json['location'] is String) {
      try {
        final point = Point.decodeHex(json['location'], format: WKB.geometry);
        _log.info('point: $point');
        latLng = LatLng(point.position.y, point.position.x);
      } catch (e, stackTrace) {
        _log.severe('Error parsing EWKB: $e', stackTrace);
        latLng = const LatLng(0, 0);
      }
    } else {
      latLng = const LatLng(0, 0);
    }

    _log.finer('JSON: $json');
    _log.info('LAT & LONG: $latLng');

    return ReportModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString(),
      title: json['title']?.toString() ?? 'Untitled Report',
      description: json['description']?.toString(),
      issueType: json['issue_type']?.toString(),
      location: latLng,
      validationStatus: json['validation_status']?.toString() ?? 'pending',
      status: json['status']?.toString() ?? 'unresolved',
      clusterId: json['cluster_id']?.toString(),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
      userFullName: json['profiles']?['full_name']?.toString(),
    );
  }
}
