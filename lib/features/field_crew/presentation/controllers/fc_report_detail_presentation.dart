import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import 'fc_dashboard_presentation.dart';
import 'fc_task_detail_presentation.dart';

/// Where a report is in the crew's work, resolved from its response status and
/// lifecycle stage exactly as the old action button did.
enum CrewReportStage {
  toAcknowledge,
  inProgress,
  completed,
  closed,
  rejected,
  unknown,
}

String _crewStatusKey(ReportModel report) {
  final status = report.status.toLowerCase();
  final stage = report.lifecycleStage?.toLowerCase();
  return const {
        'resolved',
        'completed',
        'closed',
        'rejected',
        'waiting_for_feedback',
      }.contains(status)
      ? status
      : status == 'in_progress' || status == 'responded' || stage == 'responded'
      ? 'responded'
      : status == 'acknowledged' || stage == 'acknowledged'
      ? 'acknowledged'
      : status;
}

CrewReportStage crewReportStage(ReportModel report) => switch (_crewStatusKey(
  report,
)) {
  'unresolved' || 'submitted' || 'pending' => CrewReportStage.toAcknowledge,
  'acknowledged' || 'responded' || 'in_progress' => CrewReportStage.inProgress,
  'resolved' ||
  'completed' ||
  'waiting_for_feedback' => CrewReportStage.completed,
  'closed' => CrewReportStage.closed,
  'rejected' => CrewReportStage.rejected,
  _ => CrewReportStage.unknown,
};

/// Scouting and acknowledge-only reports are completed without photos.
bool crewReportIsScouting(ReportModel report) {
  final type = report.issueType?.toLowerCase() ?? '';
  return type == 'scouting' || type == 'acknowledge_only';
}

/// Whether Before and After photos may be added now: Before until the report
/// is finished, After once it has been acknowledged.
({bool before, bool after}) crewReportPhotoRules(ReportModel report) {
  final status = report.status.toLowerCase();
  final terminal = const {
    'resolved',
    'completed',
    'closed',
    'rejected',
    'waiting_for_feedback',
  }.contains(status);
  final acknowledgedStatus = !const [
    'unresolved',
    'submitted',
    'pending',
  ].contains(status);
  final lifecycle = report.lifecycleStage?.toLowerCase();
  final acknowledgedStage =
      lifecycle != null &&
      !const [
        'new',
        'pending',
        'under_review',
        'submitted',
      ].contains(lifecycle);
  return (
    before: !terminal,
    after: (acknowledgedStatus || acknowledgedStage) && !terminal,
  );
}

({String primary, String? detail}) crewReportPlace(ReportModel report) {
  final hasArea =
      report.streetAddress?.trim().isNotEmpty == true ||
      report.barangay?.trim().isNotEmpty == true;
  if (hasArea) return (primary: report.formattedAddress, detail: null);
  return (
    primary: 'Address not provided',
    detail:
        'Map pin ${report.location.latitude.toStringAsFixed(4)}, ${report.location.longitude.toStringAsFixed(4)}',
  );
}

String _joinParts(List<String> parts) {
  if (parts.length < 3) return parts.join(' and ');
  return '${parts.sublist(0, parts.length - 1).join(', ')} and ${parts.last}';
}

/// Why “Complete report” is not available yet, or null when every existing
/// rule is met. It mirrors the rules (photos, site visit); it adds none.
String? crewReportCompletionBlocker({
  required bool scouting,
  required bool hasBefore,
  required bool hasAfter,
  required bool siteRecorded,
  required bool hasJob,
  Duration? siteTimeLeft,
}) {
  if (!hasJob) return 'Open this report from its job to complete it';
  final parts = [
    if (!scouting && !hasBefore) 'add a Before photo',
    if (!scouting && !hasAfter) 'add an After photo',
    if (!siteRecorded)
      siteTimeLeft == null
          ? 'finish the site visit'
          : 'stay on site ${crewClock(siteTimeLeft)} more',
  ];
  if (parts.isEmpty) return null;
  final text = _joinParts(parts);
  return '${text[0].toUpperCase()}${text.substring(1)} first';
}

/// One line telling the crew what to do before acknowledging.
String crewReportAcknowledgeHint({
  required bool scouting,
  required bool hasBefore,
}) => scouting
    ? 'Acknowledge the report when you arrive'
    : hasBefore
    ? 'Before photos added. Acknowledge when you are done adding them.'
    : 'Add Before photos first, then acknowledge';

String crewActivityActor(String userId, String? currentUserId) {
  if (userId.isNotEmpty && userId == currentUserId) return 'You';
  return 'Team member';
}

String crewActivityLabel(String actionType) => switch (actionType) {
  'status_update' => 'Status changed',
  'manual_note' => 'Note',
  'evidence_upload' => 'Photo added',
  _ => crewTaskLabel(actionType),
};
