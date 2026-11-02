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

/// Address and coordinates for the job header. When no address is known the
/// coordinates are labelled as a map pin rather than shown as the address.
({String primary, String? detail}) taskPlaceParts(
  CleanupTask task, {
  String? resolvedAddress,
}) {
  final place = taskPlace(task, resolvedAddress: resolvedAddress);
  const marker = 'Address unavailable · ';
  if (place.startsWith(marker)) {
    return (
      primary: 'Address not provided',
      detail: 'Map pin ${place.substring(marker.length)}',
    );
  }
  return (primary: place, detail: null);
}

/// Reports still to handle, earliest response deadline first (no deadline last).
List<ReportModel> reportsToHandle(List<ReportModel> reports) {
  final open = reports.where((r) => !reportIsHandled(r)).toList();
  open.sort((a, b) {
    final x = a.deadlineAt, y = b.deadlineAt;
    if (x == null && y == null) return a.title.compareTo(b.title);
    if (x == null) return 1;
    if (y == null) return -1;
    return x.compareTo(y);
  });
  return open;
}

ReportModel? nextReportToHandle(List<ReportModel> reports) =>
    reportsToHandle(reports).firstOrNull;

int citizenPhotoCount(
  List<ReportModel> reports,
  Map<String, List<dynamic>> evidenceByReport,
) {
  var count = 0;
  for (final report in reports) {
    for (final row in evidenceByReport[report.id] ?? const []) {
      if (citizenEvidenceUrl(row) != null && !citizenEvidenceIsVideo(row)) {
        count++;
      }
    }
  }
  return count;
}

String crewClock(Duration value) {
  final seconds = value.inSeconds < 0 ? 0 : value.inSeconds;
  return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}

/// Why “Complete job” is not available yet, in the crew's words, or null when
/// every existing completion rule is met. It mirrors the rules; it adds none.
String? crewCompletionBlocker({
  required bool investigationComplete,
  required bool refreshing,
  required int missing,
  required int unhandled,
  Duration? siteTimeLeft,
}) {
  if (refreshing) return 'Refreshing the job. Wait a moment.';
  if (missing > 0) {
    return 'Refresh the job to load $missing missing ${missing == 1 ? 'report' : 'reports'} first';
  }
  final parts = [
    if (!investigationComplete)
      siteTimeLeft == null
          ? 'finish the site visit'
          : 'stay on site ${crewClock(siteTimeLeft)} more',
    if (unhandled > 0)
      'handle $unhandled more ${unhandled == 1 ? 'report' : 'reports'}',
  ];
  if (parts.isEmpty) return null;
  final text = parts.join(' and ');
  return '${text[0].toUpperCase()}${text.substring(1)} first';
}
