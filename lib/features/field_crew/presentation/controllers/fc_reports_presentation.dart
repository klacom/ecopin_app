import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import 'package:ecopin_app/shared/reports/presentation/response_deadline.dart';
import 'fc_dashboard_presentation.dart';
import 'fc_task_detail_presentation.dart';

/// The deadline choices on the Reports tab. They apply to To handle only,
/// because a handled report has no deadline.
enum CrewDeadlineFilter {
  all('All'),
  approaching('Due soon'),
  overdue('Overdue');

  const CrewDeadlineFilter(this.label);
  final String label;
}

/// “Illegal dumping”, “General concern”: the report's type in plain words.
String crewReportTypeLabel(ReportModel report) =>
    crewTaskLabel(report.issueType ?? 'General concern');

/// The report types present in [reports], sorted by their plain label.
List<String> crewReportTypes(List<ReportModel> reports) {
  final types = {
    for (final r in reports)
      if (r.issueType?.trim().isNotEmpty == true) r.issueType!,
  }.toList();
  types.sort((a, b) => crewTaskLabel(a).compareTo(crewTaskLabel(b)));
  return types;
}

bool _matchesQuery(ReportModel report, String query) {
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) return true;
  return report.title.toLowerCase().contains(needle) ||
      (report.description?.toLowerCase().contains(needle) ?? false) ||
      report.formattedAddress.toLowerCase().contains(needle);
}

/// The two lists on the Reports tab. Search and type apply to both; the
/// deadline choice applies to To handle only. To handle lists the earliest
/// response deadline first, as it does inside a job; Handled lists the newest.
class CrewReportLists {
  const CrewReportLists({required this.toHandle, required this.handled});
  final List<ReportModel> toHandle;
  final List<ReportModel> handled;
}

CrewReportLists splitCrewReports(
  List<ReportModel> reports, {
  String query = '',
  CrewDeadlineFilter deadline = CrewDeadlineFilter.all,
  String? type,
  DateTime? now,
}) {
  final moment = now ?? DateTime.now();
  final scoped = reports
      .where(
        (r) => _matchesQuery(r, query) && (type == null || r.issueType == type),
      )
      .toList();
  final open = reportsToHandle(scoped).where((r) {
    if (deadline == CrewDeadlineFilter.all) return true;
    final state = responseDeadline(r, moment)?.state;
    return state ==
        (deadline == CrewDeadlineFilter.approaching
            ? DeadlineState.atRisk
            : DeadlineState.overdue);
  }).toList();
  final handled = scoped.where(reportIsHandled).toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return CrewReportLists(toHandle: open, handled: handled);
}
