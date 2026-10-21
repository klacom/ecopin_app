import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:ecopin_app/core/database/app_database.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/features/field_crew/data/models/cleanup_task_model.dart';
import 'package:ecopin_app/features/field_crew/data/repositories/fc_local_repository.dart';
import 'package:ecopin_app/features/field_crew/offline/fc_offline_package.dart';
import 'package:ecopin_app/features/field_crew/offline/fc_offline_package_service.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import 'package:flutter_test/flutter_test.dart';

class SyntheticOfflineApi extends Fake implements ApiClient {
  SyntheticOfflineApi(this.client);
  final Dio client;
  @override
  Dio get dioClient => client;
}

class SyntheticOfflineStore extends Fake implements FcLocalRepository {
  final savedReports = <ReportModel>[];
  @override
  Future<void> saveTasks(List<CleanupTask> tasks) async {}
  @override
  Future<void> saveReports(List<ReportModel> reports) async =>
      savedReports.addAll(reports);
  @override
  Future<void> saveEvidences(
    String id,
    List<Map<String, dynamic>> values,
  ) async {}
  @override
  Future<void> saveNotes(String id, List<Map<String, dynamic>> values) async {}
  @override
  Future<void> recordSyncAt(String collectionKey, [DateTime? syncedAt]) async {}
}

Future<FcOfflinePackageState> runPackage(FcOfflinePackageService service) =>
    service.download(
      onStepProgress: (_, {completed = false, inProgress = false, error}) {},
      onCountUpdate: ({tasks, reports, evidence, notes}) {},
    );

void main() {
  test(
    'preparation keeps pending local task/report edits and exposes cache write failures',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final local = FcLocalRepository(db);
      final report = ReportModel.fromJson({
        'id': 'report',
        'title': 'Original',
      });
      final task = CleanupTask.fromJson({'id': 'task', 'title': 'Original'});
      await local.saveReports([report]);
      await local.saveTasks([task]);
      await local.applyLocalReportPatch('report', {'title': 'Pending report'});
      await local.applyLocalTaskPatch('task', {'title': 'Pending task'});
      await local.saveReports([report]);
      await local.saveTasks([task]);
      expect(
        (await local.getCachedReportById('report'))!.title,
        'Pending report',
      );
      expect((await local.getCachedTaskById('task'))!.title, 'Pending task');
      await db.close();
      await expectLater(local.saveTasks([task]), throwsStateError);
    },
  );
  for (final rateLimited in [false, true]) {
    test(
      'only linked reports download in bounded batches; rateLimited=$rateLimited',
      () async {
        final client = Dio(BaseOptions(baseUrl: 'https://synthetic.invalid'));
        addTearDown(() => client.close());
        final requests = <RequestOptions>[];
        final ids = List.generate(10, (i) => 'report-$i');
        client.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              requests.add(options);
              if (rateLimited && options.path.contains('batch-evidence')) {
                handler.reject(
                  DioException(
                    requestOptions: options,
                    response: Response(
                      requestOptions: options,
                      statusCode: 429,
                      headers: Headers.fromMap({
                        'retry-after': ['120'],
                      }),
                    ),
                  ),
                );
                return;
              }
              final Object data = options.path.contains('cleanup-tasks')
                  ? [
                      {
                        'id': 'task',
                        'title': 'Assigned cleanup',
                        'report_ids': ids,
                      },
                    ]
                  : options.path.contains('batch-evidence')
                  ? {for (final id in ids) id: []}
                  : options.path == '/api/reports'
                  ? [
                      for (final id in [...ids, 'unrelated'])
                        {'id': id, 'title': id},
                    ]
                  : options.path.contains('active')
                  ? {'routes': []}
                  : [];
              handler.resolve(
                Response(requestOptions: options, data: data, statusCode: 200),
              );
            },
          ),
        );
        final store = SyntheticOfflineStore();
        final service = FcOfflinePackageService(
          SyntheticOfflineApi(client),
          store,
        );
        final result = await runPackage(service);
        expect(result.reportCount, 10);
        expect(store.savedReports.any((r) => r.id == 'unrelated'), false);
        expect(
          requests.where((r) => r.path.contains('batch-evidence')),
          hasLength(1),
        );
        expect(requests.any((r) => r.path.endsWith('/evidence')), false);
        expect(result.taskTitles, ['Assigned cleanup']);
        expect(result.reportTitles, ids);
        if (rateLimited) {
          expect(requests, hasLength(3));
          expect(
            result.steps
                .firstWhere((s) => s.label == FcOfflineStepLabel.evidence)
                .error,
            contains('Rate limited'),
          );
          expect(
            result.steps
                .firstWhere((s) => s.label == FcOfflineStepLabel.notes)
                .completed,
            false,
          );
          await expectLater(runPackage(service), throwsStateError);
          await service.estimateBytes();
          expect(requests, hasLength(3));
        } else {
          expect(requests, hasLength(14));
          expect(
            result.steps.every((s) => s.completed && s.error == null),
            true,
          );
        }
      },
    );
  }
  test(
    'a failed assigned group and missing linked record remain visible while useful records cache',
    () async {
      final client = Dio(BaseOptions(baseUrl: 'https://synthetic.invalid'));
      addTearDown(() => client.close());
      client.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path.contains('/cluster/failed-group')) {
              handler.reject(
                DioException(
                  requestOptions: options,
                  type: DioExceptionType.connectionError,
                ),
              );
              return;
            }
            final Object data = options.path.contains('cleanup-tasks')
                ? [
                    {'id': 'assigned-1', 'cluster_id': 'failed-group'},
                    {'id': 'assigned-2', 'cluster_id': 'available-group'},
                    {
                      'id': 'assigned-3',
                      'report_ids': ['missing-report'],
                    },
                  ]
                : options.path.contains('/cluster/available-group')
                ? [
                    {
                      'id': 'available-report',
                      'cluster_id': 'available-group',
                      'title': 'Synthetic report',
                      'created_at': '2026-10-14T00:00:00Z',
                    },
                  ]
                : options.path.contains('batch-evidence')
                ? {'available-report': []}
                : options.path.contains('active')
                ? {'routes': []}
                : [];
            handler.resolve(
              Response(requestOptions: options, data: data, statusCode: 200),
            );
          },
        ),
      );
      final store = SyntheticOfflineStore();
      final service = FcOfflinePackageService(
        SyntheticOfflineApi(client),
        store,
      );
      final steps = <String, FcDownloadStep>{};
      final result = await service.download(
        onStepProgress:
            (label, {completed = false, inProgress = false, error}) {
              steps[label] = FcDownloadStep(
                label: label,
                completed: completed,
                inProgress: inProgress,
                error: error,
              );
            },
        onCountUpdate: ({tasks, reports, evidence, notes}) {},
      );
      expect(
        store.savedReports.map((report) => report.id),
        contains('available-report'),
      );
      expect(result.reportCount, 1);
      final reportStep = steps[FcOfflineStepLabel.reports]!;
      expect(reportStep.error, contains('1 assigned report group'));
      expect(reportStep.error, contains('1 linked report'));
      expect(reportStep.error, isNot(contains('synthetic.invalid')));
    },
  );
}
