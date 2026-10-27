import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import 'package:ecopin_app/shared/reports/presentation/response_deadline.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final json = <String, dynamic>{
    'id': 'report',
    'status': 'unresolved',
    'validation_status': 'approved',
    'sla_started_at': '2026-10-27T00:00:00Z',
    'deadline_at': '2026-10-28T00:00:00Z',
  };
  ResponseDeadline? at(String now, [Map<String, dynamic> patch = const {}]) =>
      responseDeadline(
        ReportModel.fromJson({...json, ...patch}),
        DateTime.parse(now),
      );

  test('last 20 percent uses SLA start, not creation date', () {
    expect(at('2026-10-27T19:11:59Z')!.state, DeadlineState.scheduled);
    final result = at('2026-10-27T19:12:00Z')!;
    expect(result.state, DeadlineState.atRisk);
    expect(result.timeLabel, '4h 48m left');
  });
  test('deadline equality and minute rounding', () {
    expect(at('2026-10-27T23:59:59Z')!.timeLabel, '1m left');
    expect(at('2026-10-28T00:00:00Z')!.state, DeadlineState.overdue);
    expect(at('2026-10-28T01:30:00Z')!.timeLabel, '1h 30m overdue');
  });
  test('assignment never hides overdue and terminals stop the clock', () {
    expect(
      at('2026-10-28T00:00:00Z', {
        'lifecycle_state': 'dispatched',
        'status': 'in_progress',
      })!.state,
      DeadlineState.overdue,
    );
    for (final status in [
      'resolved',
      'completed',
      'closed',
      'rejected',
      'cancelled',
    ]) {
      expect(at('2026-10-28T00:00:00Z', {'status': status}), isNull);
    }
    expect(
      at('2026-10-28T00:00:00Z', {'validation_status': 'rejected'}),
      isNull,
    );
  });
  test('unknown timestamps do not invent a deadline or risk window', () {
    expect(at('2026-10-27T23:00:00Z', {'deadline_at': null}), isNull);
    expect(at('2026-10-27T23:00:00Z', {'deadline_at': 'invalid'}), isNull);
    expect(
      at('2026-10-27T23:00:00Z', {'sla_started_at': null})!.state,
      DeadlineState.scheduled,
    );
  });
  test('deadline timestamps survive caching in UTC', () {
    final report = ReportModel.fromJson({
      ...json,
      'deadline_at': '2026-10-28T08:00:00+08:00',
    });
    final cached = ReportModel.fromJson(report.toJson());
    expect(cached.deadlineAt, report.deadlineAt);
    expect(cached.slaStartedAt, report.slaStartedAt);
    expect(
      cached.deadlineAt!.toUtc().toIso8601String(),
      '2026-10-28T00:00:00.000Z',
    );
  });
}
