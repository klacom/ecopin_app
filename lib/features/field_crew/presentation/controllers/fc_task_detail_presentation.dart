import 'package:latlong2/latlong.dart';
import '../../data/models/cleanup_task_model.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';

Set<String> taskReportIds(CleanupTask task) => {
  ...task.reportIds,
  ...task.satelliteReportIds,
  ...task.reportClaimGenerations.keys,
  ...?task.reports?.map((r) => r.id),
}..removeWhere((id) => id.trim().isEmpty);
bool reportIsHandled(ReportModel report) =>
    {
      'resolved',
      'completed',
      'closed',
      'rejected',
    }.contains(report.status.toLowerCase()) ||
    ({
          'scouting',
          'acknowledge_only',
        }.contains(report.issueType?.toLowerCase()) &&
        {
          'approved',
          'validated',
        }.contains(report.validationStatus.toLowerCase()));
LatLng? taskPoint(CleanupTask task) {
  final raw = task.location.trim();
  if (!raw.startsWith('POINT') && !RegExp(r'^[0-9A-Fa-f]+$').hasMatch(raw)) {
    return null;
  }
  try {
    final point = ReportModel.fromJson({'location': raw}).location;
    if (point.latitude.isFinite &&
        point.longitude.isFinite &&
        point.latitude.abs() <= 90 &&
        point.longitude.abs() <= 180 &&
        (point.latitude != 0 || point.longitude != 0)) {
      return point;
    }
  } catch (_) {}
  return null;
}

String taskPlace(CleanupTask task, {String? resolvedAddress}) {
  for (final value in [resolvedAddress, task.streetAddress]) {
    if (value != null && value.trim().isNotEmpty) return value.trim();
  }
  final location = task.location.trim();
  if (location.isNotEmpty &&
      !location.startsWith('POINT') &&
      !RegExp(r'^[0-9A-Fa-f]+$').hasMatch(location) &&
      location != 'Unknown Location') {
    return location;
  }
  final point = taskPoint(task);
  return point == null
      ? 'Location unavailable'
      : 'Address unavailable · ${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
}

String? citizenEvidenceUrl(dynamic row) {
  if (row is! Map) return null;
  for (final key in ['url', 'file_url', 'evidence_url', 'secure_url']) {
    final value = row[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
  }
  return null;
}

bool citizenEvidenceIsVideo(dynamic row) =>
    row is Map &&
    (row['resource_type'] == 'video' ||
        row['media_type'] == 'video' ||
        (row['mime_type']?.toString().startsWith('video/') ?? false) ||
        RegExp(
          r'\.(mp4|mov|webm|m4v)$',
          caseSensitive: false,
        ).hasMatch(Uri.tryParse(citizenEvidenceUrl(row) ?? '')?.path ?? ''));
