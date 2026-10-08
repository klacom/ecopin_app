import 'package:flutter_test/flutter_test.dart';
import 'package:ecopin_app/features/field_crew/data/models/cleanup_task_model.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_result.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';

void main() {
  test('offline task cache preserves published assignment and report receipts', () {
    final task = CleanupTask.fromJson({
      'id': 'task-1',
      'assignment_generation': 4,
      'assigned_field_crew_id': 'crew-1',
      'report_claim_generations': {'report-1': 8},
      'satellite_report_ids': ['report-1'],
      'bundle_detour_min': 12.5,
      'created_at': '2026-10-08T00:00:00Z',
      'updated_at': '2026-10-08T00:00:00Z',
    });
    final cached = CleanupTask.fromJson(task.toJson());
    expect(cached.assignmentGeneration, 4);
    expect(cached.assignedFieldCrewId, 'crew-1');
    expect(cached.reportClaimGenerations['report-1'], 8);
    expect(cached.satelliteReportIds, ['report-1']);
    expect(cached.bundleDetourMin, 12.5);
  });

  test('report cache preserves claim generation and version', () {
    final report = ReportModel.fromJson({
      'id': 'report-1',
      'title': 'Waste',
      'latitude': 14.5,
      'longitude': 121.0,
      'report_claim_generation': 8,
      'fc_version': 3,
    });
    final cached = ReportModel.fromJson(report.toJson());
    expect(cached.reportClaimGeneration, 8);
    expect(cached.fcVersion, 3);
  });

  test('reconciliation states remain distinct from transient sync failures', () {
    for (final status in ['applied', 'acknowledged_already_resolved',
      'verification_required', 'contested']) {
      final result = FcOpResult.fromJson({'operation_id': 'op-1', 'status': status});
      expect(result.isRetryable, isFalse, reason: status);
      expect(result.isTerminalSuccess, isTrue, reason: status);
    }
    final rejected = FcOpResult.fromJson({'operation_id': 'op-2', 'status': 'rejected'});
    expect(rejected.isTerminalFailure, isTrue);
  });
}
