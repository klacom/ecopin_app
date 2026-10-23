import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/core/services/cache_service.dart';
import 'package:ecopin_app/features/field_crew/data/repositories/field_crew_report_repository.dart';
import 'package:ecopin_app/features/field_crew/data/repositories/fc_local_photo_repository.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import 'package:ecopin_app/features/field_crew/providers/fc_local_repository_provider.dart';
import 'package:ecopin_app/features/field_crew/presentation/controllers/fc_sync_ui_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:ecopin_app/core/database/app_database.dart';
import 'package:ecopin_app/features/field_crew/data/repositories/fc_local_repository.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_trigger.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_gate.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_settings.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_manager.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_result.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_photo_sync_manager.dart';

const emptyResult = FcSyncRunResult(
  total: 0,
  succeeded: 0,
  merged: 0,
  conflicted: 0,
  retryable: 0,
  permanent: 0,
  results: [],
);

class Mutations extends Fake implements FcSyncManager {
  Mutations(this.local);
  final FcLocalRepository local;
  int runs = 0;
  int outcomeRuns = 0;
  bool fail = false;
  Completer<void>? hold;
  @override
  Future<FcSyncRunResult> syncWithBackoff({
    int maxAttempts = 3,
    bool evidenceDependentOnly = false,
  }) async {
    if (evidenceDependentOnly) {
      outcomeRuns++;
      return emptyResult;
    }
    runs++;
    if (hold != null) await hold!.future;
    if (fail) {
      for (final row in await local.getPendingOutboxItems()) {
        await local.markOutboxItemFailed(
          row.operationId,
          'Synthetic unavailable',
        );
      }
      return const FcSyncRunResult(
        total: 1,
        succeeded: 0,
        merged: 0,
        conflicted: 0,
        retryable: 1,
        permanent: 0,
        results: [],
      );
    }
    for (final row in await local.getPendingOutboxItems()) {
      await local.deleteOutboxItem(row.operationId);
    }
    return emptyResult;
  }
}

class Photos extends Fake implements FcPhotoSyncManager {
  bool fail = false;
  @override
  Future<FcPhotoSyncRunResult> sync() async => FcPhotoSyncRunResult(
    uploadAttempted: fail ? 1 : 0,
    uploadSucceeded: 0,
    uploadFailed: fail ? 1 : 0,
    deleteAttempted: 0,
    deleteSucceeded: 0,
    deleteFailed: 0,
  );
}

class Gate extends Fake implements FcSyncGate {
  FcSyncMode mode = FcSyncMode.automatic;
  bool online = true;
  @override
  Future<FcGateDecision> checkAutoSync() async => FcGateDecision(
    allowed: online && mode == FcSyncMode.automatic,
    networkType: FcNetworkType.wifi,
  );
  @override
  Future<FcGateDecision> checkManualCommit() async => FcGateDecision(
    allowed: online && mode != FcSyncMode.offlineOnly,
    networkType: FcNetworkType.wifi,
  );
}

class AutoApi extends Fake implements ApiClient {
  AutoApi(this.client);
  final Dio client;
  @override
  Dio get dioClient => client;
}

class AutoCache extends Fake implements CacheService {}

void main() {
  test('completion pass waits until failed photo uploads succeed', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final local = FcLocalRepository(db);
    final mutations = Mutations(local);
    final photos = Photos()..fail = true;
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final trigger = FcSyncTrigger(
      syncManager: mutations,
      photoSyncManager: photos,
      gate: Gate(),
      stateNotifier: container.read(fcSyncStateProvider.notifier),
      onSynced: () {},
    );
    addTearDown(trigger.dispose);
    expect((await trigger.syncNow())!.phase, FcSyncPhase.partialFailure);
    expect(mutations.outcomeRuns, 0);
    photos.fail = false;
    expect((await trigger.syncNow())!.phase, FcSyncPhase.success);
    expect(mutations.outcomeRuns, 1);
  });
  test(
    'note sync updates the note cache without replacing report identity',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final local = FcLocalRepository(db);
      await local.saveReports([
        ReportModel.fromJson({
          'id': 'r',
          'title': 'Original report',
          'status': 'unresolved',
        }),
      ]);
      final note = await local.addLocalNote('r', {
        'action_details': 'Observed on site',
      });
      final operation = await local.enqueueOutboxItem(
        operationType: FcOutboxOperationType.addNote,
        entityId: 'r',
        entityType: 'report',
        payload: {'action': 'Observed on site', '_local_note_id': note},
      );
      final client = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'results': [
                      {
                        'operation_id': operation,
                        'status': 'success',
                        'server_record': {
                          'id': 'server-note',
                          'report_id': 'r',
                          'action_details': 'Observed on site',
                        },
                      },
                    ],
                  },
                ),
              );
            },
          ),
        );
      await FcSyncManager(AutoApi(client), local).syncWithBackoff();
      expect((await local.getCachedReportById('r'))!.id, 'r');
      expect((await local.getCachedNotes('r')).map((n) => n['id']), [
        'server-note',
      ]);
    },
  );
  test(
    'exhausted photo retries remain visible as failure instead of claiming synced',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final local = FcLocalRepository(db);
      final photos = FcLocalPhotoRepository(db);
      final container = ProviderContainer();
      final trigger = FcSyncTrigger(
        syncManager: Mutations(local),
        photoSyncManager: FcPhotoSyncManager(AutoApi(Dio()), photos, local),
        gate: Gate(),
        stateNotifier: container.read(fcSyncStateProvider.notifier),
        onSynced: () {},
      );
      addTearDown(() async {
        trigger.dispose();
        container.dispose();
        await db.close();
      });
      await db.insertFcLocalPhoto(
        FcLocalPhotosCompanion.insert(
          localPhotoId: 'blocked',
          entityId: 'r',
          entityType: 'report',
          photoType: 'before',
          localPath: 'unused',
          retryCount: const drift.Value(5),
          syncStatus: const drift.Value(FcLocalPhotoSyncStatus.failed),
        ),
      );
      final result = await trigger.syncNow();
      expect(result!.phase, FcSyncPhase.partialFailure);
      expect(result.lastPhotoResult!.uploadSkipped, 1);
      expect(await photos.getPendingUploads(), hasLength(1));
    },
  );
  test(
    'photo-only work resumes when switching from blocked data to allowed Wi-Fi',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final local = FcLocalRepository(db);
      final photos = FcLocalPhotoRepository(db);
      final container = ProviderContainer();
      final gate = Gate()..online = false;
      final finished = Completer<void>();
      var requests = 0;
      final client = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              requests++;
              expect(options.method, 'DELETE');
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'report': {'id': 'r', 'fc_version': 1, 'before_photos': []},
                  },
                ),
              );
            },
          ),
        );
      final trigger = FcSyncTrigger(
        syncManager: Mutations(local),
        photoSyncManager: FcPhotoSyncManager(AutoApi(client), photos, local),
        gate: gate,
        stateNotifier: container.read(fcSyncStateProvider.notifier),
        onSynced: () {
          if (!finished.isCompleted) finished.complete();
        },
      );
      final sub = local.watchPendingWrites().listen(trigger.observeWrites);
      addTearDown(() async {
        trigger.dispose();
        await sub.cancel();
        container.dispose();
        await db.close();
      });
      await local.saveReports([
        ReportModel.fromJson({'id': 'r'}),
      ]);
      await photos.queueRemoteDeletion(
        'r',
        'before',
        'legacy',
        'https://example.test/photo.jpg',
      );
      trigger.networkChanged([ConnectivityResult.mobile]);
      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(requests, 0);
      expect(await photos.getPendingDeletes(), hasLength(1));
      gate.online = true;
      trigger.networkChanged([ConnectivityResult.wifi]);
      await finished.future.timeout(const Duration(seconds: 3));
      expect(requests, 1);
      expect(await photos.getPendingDeletes(), isEmpty);
    },
  );
  test(
    'pending summary reacts to new writes without reopening the screen',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final local = FcLocalRepository(db);
      final container = ProviderContainer(
        overrides: [
          fcLocalRepositoryProvider.overrideWithValue(local),
          fcLocalPhotoRepositoryProvider.overrideWithValue(
            FcLocalPhotoRepository(db),
          ),
        ],
      );
      final changed = Completer<void>();
      final sub = container.listen(fcPendingSummaryProvider, (_, next) {
        if (next.value?.mutationCount == 1 && !changed.isCompleted) {
          changed.complete();
        }
      });
      addTearDown(() async {
        sub.close();
        container.dispose();
        await db.close();
      });
      expect(
        (await container.read(fcPendingSummaryProvider.future)).mutationCount,
        0,
      );
      await local.enqueueOutboxItem(
        operationType: FcOutboxOperationType.updateLifecycleStage,
        entityId: 'r',
        entityType: 'report',
        payload: {'stage': 'acknowledged'},
      );
      await changed.future.timeout(const Duration(seconds: 3));
    },
  );
  test(
    'saved Manual preference is awaited before default Automatic can send',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final loaded = Completer<FcSyncSettings>();
      final gate = FcSyncGate(
        const FcSyncSettings(),
        FcLocalRepository(db),
        FcLocalPhotoRepository(db),
        readSettings: () => loaded.future,
      );
      var checked = false;
      final pending = gate.checkAutoSync().then((result) {
        checked = true;
        return result;
      });
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(checked, isFalse);
      loaded.complete(const FcSyncSettings(mode: FcSyncMode.manualCommit));
      expect((await pending).allowed, isFalse);
    },
  );
  test(
    'failure notifications keep unsent data without triggering an automatic loop',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final local = FcLocalRepository(db);
      final container = ProviderContainer();
      final manager = Mutations(local)..fail = true;
      final finished = Completer<void>();
      final trigger = FcSyncTrigger(
        syncManager: manager,
        photoSyncManager: Photos(),
        gate: Gate(),
        stateNotifier: container.read(fcSyncStateProvider.notifier),
        onSynced: () {
          if (!finished.isCompleted) finished.complete();
        },
      );
      final sub = local.watchPendingWrites().listen(trigger.observeWrites);
      addTearDown(() async {
        trigger.dispose();
        await sub.cancel();
        container.dispose();
        await db.close();
      });
      await local.enqueueOutboxItem(
        operationType: FcOutboxOperationType.updateLifecycleStage,
        entityId: 'r',
        entityType: 'report',
        payload: {'stage': 'acknowledged'},
      );
      await finished.future.timeout(const Duration(seconds: 3));
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(manager.runs, 1);
      expect(await local.getPendingOutboxItems(), hasLength(1));
      expect(
        container.read(fcSyncStateProvider).phase,
        FcSyncPhase.partialFailure,
      );
    },
  );
  for (final mode in FcSyncMode.values) {
    test(
      'new writes follow $mode without needing to revisit Sync Center',
      () async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        final local = FcLocalRepository(db);
        final container = ProviderContainer();
        final manager = Mutations(local);
        final gate = Gate()..mode = mode;
        final finished = Completer<void>();
        final trigger = FcSyncTrigger(
          syncManager: manager,
          photoSyncManager: Photos(),
          gate: gate,
          stateNotifier: container.read(fcSyncStateProvider.notifier),
          onSynced: () {
            if (!finished.isCompleted) finished.complete();
          },
        );
        final sub = local.watchPendingWrites().listen(trigger.observeWrites);
        addTearDown(() async {
          trigger.dispose();
          await sub.cancel();
          container.dispose();
          await db.close();
        });
        await local.saveReports([
          ReportModel.fromJson({'id': 'r', 'status': 'unresolved'}),
        ]);
        var bypassRequests = 0;
        final client = Dio()
          ..interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) {
                bypassRequests++;
                handler.reject(DioException(requestOptions: options));
              },
            ),
          );
        final reports = FieldCrewReportRepository(
          AutoApi(client),
          AutoCache(),
          local,
          FcLocalPhotoRepository(db),
        );
        await reports.updateLifecycleStage('r', 'acknowledged');
        expect(bypassRequests, 0);
        if (mode == FcSyncMode.automatic) {
          await finished.future.timeout(const Duration(seconds: 3));
          expect(await local.getPendingOutboxItems(), isEmpty);
          expect(manager.runs, 1);
        } else {
          await Future<void>.delayed(const Duration(milliseconds: 250));
          expect(manager.runs, 0);
          expect(await local.getPendingOutboxItems(), hasLength(1));
          await trigger.manualCommit();
          expect(manager.runs, mode == FcSyncMode.manualCommit ? 1 : 0);
        }
      },
    );
  }
  test(
    'edits during sync get one follow-up; identical queue notifications do not loop',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final local = FcLocalRepository(db);
      final container = ProviderContainer();
      final manager = Mutations(local)..hold = Completer<void>();
      final trigger = FcSyncTrigger(
        syncManager: manager,
        photoSyncManager: Photos(),
        gate: Gate(),
        stateNotifier: container.read(fcSyncStateProvider.notifier),
        onSynced: () {},
      );
      addTearDown(() async {
        trigger.dispose();
        container.dispose();
        await db.close();
      });
      final run = trigger.syncNow();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      trigger.observeWrites(['new']);
      trigger.observeWrites(['new']);
      manager.hold!.complete();
      await run;
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(manager.runs, 2);
      trigger.observeWrites(['new']);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(manager.runs, 2);
    },
  );
}
