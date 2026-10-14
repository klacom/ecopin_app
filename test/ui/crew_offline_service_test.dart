import 'package:dio/dio.dart';
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

void main() {
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
                    {
                      'id': 'assigned-1',
                      'cluster_id': 'failed-group',
                      'report_ids': ['missing-report'],
                    },
                    {'id': 'assigned-2', 'cluster_id': 'available-group'},
                  ]
                : options.path.contains('/cluster/available-group')
                ? [
                    {
                      'id': 'available-report',
                      'title': 'Synthetic report',
                      'created_at': '2026-10-14T00:00:00Z',
                    },
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
