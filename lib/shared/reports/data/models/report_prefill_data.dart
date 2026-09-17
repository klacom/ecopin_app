import 'package:latlong2/latlong.dart';

/// Carries optional prefill data from a rejected report into CreateReportScreen.
/// Passed via go_router's `extra` parameter on the /create-report route.
class ReportPrefillData {
  /// GPS location for the report, if available.
  final LatLng? location;

  /// Pre-filled title copied from the rejected report.
  final String? title;

  /// Pre-filled description copied from the rejected report.
  final String? description;

  const ReportPrefillData({
    this.location,
    this.title,
    this.description,
  });
}
