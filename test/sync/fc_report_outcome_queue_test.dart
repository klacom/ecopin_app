import 'dart:convert';

import 'package:drift/native.dart';
import 'package:ecopin_app/core/database/app_database.dart';
import 'package:ecopin_app/features/field_crew/data/models/cleanup_task_model.dart';
import 'package:ecopin_app/features/field_crew/data/repositories/fc_local_repository.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late FcLocalRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = FcLocalRepository(db);
  });
  tearDown(() => db.close());

  final task = CleanupTask.fromJson({
    'id': 'task-1', 'report_ids': ['report-1'], 'assigned_field_crew_id': 'crew-1',
    'assignment_generation': 3,
  });
  final report = ReportModel.fromJson({
    'id': 'report-1', 'title': 'Waste', 'latitude': 14.5, 'longitude': 121.0,
    'report_claim_generation': 7, 'fc_version': 2,
  });

  test('each observed outcome keeps its original receipt and operation ID', () async {
    final first = await repository.enqueueReportOutcome(
      task: task, report: report, crewId: 'crew-1', outcome: 'already_resolved',
      observedAt: DateTime.utc(2026, 10, 8, 5), evidenceRefs: ['photo-1'],
      notes: 'Already clear on arrival',
    );
    final second = await repository.enqueueReportOutcome(
      task: task, report: report, crewId: 'crew-1', outcome: 'cleaned',
      observedAt: DateTime.utc(2026, 10, 8, 6), evidenceRefs: ['photo-2'],
      notes: 'New waste appeared',
    );
    final queued = await repository.getAllOutboxItems();
    expect(second, isNot(first));
    expect(queued, hasLength(2));
    final firstPayload = jsonDecode(queued.first.payloadJson) as Map<String, dynamic>;
    expect(firstPayload, containsPair('assignment_generation', 3));
    expect(firstPayload, containsPair('report_claim_generation', 7));
    expect(firstPayload, containsPair('base_fc_version', 2));
    expect(firstPayload, containsPair('outcome', 'already_resolved'));
    expect(firstPayload['evidence_refs'], ['photo-1']);
    expect(queued.first.baseVersion, '2');
  });

  test('a missing server receipt cannot be queued as physical work', () async {
    final noReceipt = ReportModel.fromJson({
      'id': 'report-1', 'title': 'Waste', 'latitude': 14.5, 'longitude': 121.0,
    });
    expect(
      () => repository.enqueueReportOutcome(
        task: task, report: noReceipt, crewId: 'crew-1', outcome: 'cleaned',
        observedAt: DateTime.utc(2026, 10, 8), evidenceRefs: ['photo-1'],
      ),
      throwsArgumentError,
    );
    expect(await repository.getAllOutboxItems(), isEmpty);
  });
}
