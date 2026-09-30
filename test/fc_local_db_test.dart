import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:ecopin_app/core/database/app_database.dart';
import 'dart:convert';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('Reports can be saved locally and read back', () async {
    final reportJson = {
      'id': 'report-123',
      'title': 'Test Report',
      'latitude': 10.0,
      'longitude': 20.0,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    await db.upsertFcReports([
      FcCachedReportsCompanion.insert(
        id: 'report-123',
        jsonData: jsonEncode(reportJson),
        serverUpdatedAt: DateTime.now(),
        localSyncState: const Value(0), // synced
      )
    ]);

    final reports = await db.getAllFcReports();
    expect(reports.length, 1);
    expect(reports.first.id, 'report-123');
    expect(reports.first.localSyncState, 0);
  });

  test('Tasks can be saved locally and read back', () async {
    final taskJson = {
      'id': 'task-456',
      'name': 'Cleanup river',
    };

    await db.upsertFcTasks([
      FcCachedTasksCompanion.insert(
        id: 'task-456',
        jsonData: jsonEncode(taskJson),
        serverUpdatedAt: DateTime.now(),
      )
    ]);

    final tasks = await db.getAllFcTasks();
    expect(tasks.length, 1);
    expect(tasks.first.id, 'task-456');
  });

  test('Local records can distinguish synced vs locally modified state', () async {
    // Insert as synced
    await db.upsertFcReports([
      FcCachedReportsCompanion.insert(
        id: 'report-789',
        jsonData: '{}',
        serverUpdatedAt: DateTime.now(),
        localSyncState: const Value(0),
      )
    ]);

    // Mark modified
    await db.markFcReportLocallyModified('report-789');

    final modifiedReports = await db.getLocallyModifiedFcReports();
    expect(modifiedReports.length, 1);
    expect(modifiedReports.first.localSyncState, 1);
    
    // Mark synced
    await db.markFcReportSynced('report-789');
    final modifiedReportsAfter = await db.getLocallyModifiedFcReports();
    expect(modifiedReportsAfter.length, 0);
  });

  test('A test mutation can be inserted into the sync queue', () async {
    await db.enqueueOutboxItem(
      FcOutboxItemsCompanion.insert(
        operationId: 'op-1',
        operationType: 'fc.report.update_status',
        entityId: 'report-1',
        entityType: 'report',
        payloadJson: '{"status": "resolved"}',
      ),
    );

    final pending = await db.getPendingOutboxItems();
    expect(pending.length, 1);
    expect(pending.first.operationId, 'op-1');
    expect(pending.first.status, 'pending');
  });
}
