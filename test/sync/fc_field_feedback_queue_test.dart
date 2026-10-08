import 'dart:convert';

import 'package:drift/native.dart';
import 'package:ecopin_app/core/database/app_database.dart';
import 'package:ecopin_app/features/field_crew/data/models/cleanup_task_model.dart';
import 'package:ecopin_app/features/field_crew/data/repositories/fc_local_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late FcLocalRepository repository;
  final task = CleanupTask.fromJson({
    'id': 'task-1',
    'assigned_crew_ids': ['crew-1'],
    'assigned_field_crew_id': 'vehicle-1',
    'assignment_generation': 4,
    'status': 'in_progress',
  });

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = FcLocalRepository(db);
    await repository.saveTasks([task]);
  });
  tearDown(() => db.close());

  test(
    'separate load and disposal observations preserve their times and values',
    () async {
      await repository.enqueueFieldLoad(
        task: task,
        actorId: 'crew-1',
        eventType: 'load_observation',
        observedAt: DateTime.utc(2026, 10, 8, 8),
        fillPercent: 80,
        actualVolumeM3: 4.5,
        actualWeightKg: 950,
      );
      await repository.enqueueFieldLoad(
        task: task,
        actorId: 'crew-1',
        eventType: 'disposal',
        observedAt: DateTime.utc(2026, 10, 8, 9),
      );
      final queued = await repository.getAllOutboxItems();
      expect(queued, hasLength(2));
      final first =
          jsonDecode(queued.first.payloadJson) as Map<String, dynamic>;
      final second =
          jsonDecode(queued.last.payloadJson) as Map<String, dynamic>;
      expect(first['actual_volume_m3'], 4.5);
      expect(first['assignment_generation'], 4);
      expect(second['event_type'], 'disposal');
      expect(second['observed_at'], '2026-10-08T09:00:00.000Z');
    },
  );

  test(
    'site failure holds only its task while retaining photo receipt',
    () async {
      await repository.enqueueTaskFailure(
        task: task,
        actorId: 'crew-1',
        reasonCode: 'site_inaccessible',
        notes: 'Gate locked',
        observedAt: DateTime.utc(2026, 10, 8, 10),
        evidenceRefs: ['local-photo:gate-photo'],
      );
      expect(
        (await repository.getCachedTaskById(task.id))?.status,
        'cancelled',
      );
      final queued = (await repository.getAllOutboxItems()).single;
      final payload = jsonDecode(queued.payloadJson) as Map<String, dynamic>;
      expect(queued.operationType, FcOutboxOperationType.submitTaskFailure);
      expect(payload['reason_code'], 'site_inaccessible');
      expect(payload['evidence_refs'], ['local-photo:gate-photo']);
    },
  );

  test(
    'a failure without evidence is rejected before changing local task',
    () async {
      expect(
        () => repository.enqueueTaskFailure(
          task: task,
          actorId: 'crew-1',
          reasonCode: 'safety_hazard',
          notes: 'Unsafe',
          observedAt: DateTime.utc(2026, 10, 8),
          evidenceRefs: [],
        ),
        throwsArgumentError,
      );
      expect(
        (await repository.getCachedTaskById(task.id))?.status,
        'in_progress',
      );
    },
  );
}
