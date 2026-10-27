import '../data/models/report_model.dart';

enum DeadlineState { scheduled, atRisk, overdue }

class ResponseDeadline {
  const ResponseDeadline(this.state, this.deadlineAt, this.timeLabel);
  final DeadlineState state;
  final DateTime deadlineAt;
  final String timeLabel;
  String get label => switch (state) {
    DeadlineState.scheduled => 'Response deadline',
    DeadlineState.atRisk => 'Response deadline approaching',
    DeadlineState.overdue => 'Response overdue',
  };
}

// Display policy only. Use the real SLA window, including grandfathered clocks.
ResponseDeadline? responseDeadline(ReportModel report, DateTime now) {
  const terminal = {'resolved', 'completed', 'closed', 'rejected', 'cancelled'};
  if ([
        report.status,
        report.lifecycleStage,
        report.lifecycleState,
      ].any((value) => terminal.contains(value?.trim().toLowerCase())) ||
      report.validationStatus.trim().toLowerCase() == 'rejected') {
    return null;
  }
  final deadline = report.deadlineAt;
  if (deadline == null) return null;
  final start = report.slaStartedAt;
  final remaining = deadline.difference(now).inMilliseconds;
  final state = remaining <= 0
      ? DeadlineState.overdue
      : start != null &&
            start.isBefore(deadline) &&
            remaining <= deadline.difference(start).inMilliseconds / 5
      ? DeadlineState.atRisk
      : DeadlineState.scheduled;
  final rounded = (remaining.abs() / 60000).ceil();
  final minutes = rounded < 1 ? 1 : rounded;
  final duration = minutes < 60
      ? '${minutes}m'
      : '${minutes ~/ 60}h${minutes % 60 == 0 ? '' : ' ${minutes % 60}m'}';
  return ResponseDeadline(
    state,
    deadline,
    '$duration ${state == DeadlineState.overdue ? 'overdue' : 'left'}',
  );
}
