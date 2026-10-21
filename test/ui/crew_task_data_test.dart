import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:ecopin_app/core/database/app_database.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/core/services/cache_service.dart';
import 'package:ecopin_app/core/services/location_search_service.dart';
import 'package:ecopin_app/features/field_crew/data/models/cleanup_task_model.dart';
import 'package:ecopin_app/features/field_crew/data/repositories/cleanup_task_repository.dart';
import 'package:ecopin_app/features/field_crew/data/repositories/field_crew_report_repository.dart';
import 'package:ecopin_app/features/field_crew/data/repositories/fc_local_repository.dart';
import 'package:ecopin_app/features/field_crew/data/repositories/fc_local_photo_repository.dart';
import 'package:ecopin_app/features/field_crew/providers/cleanup_tasks_provider.dart';
import 'package:ecopin_app/features/field_crew/providers/field_crew_reports_provider.dart';
import 'package:ecopin_app/features/field_crew/providers/fc_task_detail_notifier.dart';
import 'package:ecopin_app/features/field_crew/presentation/controllers/fc_task_detail_presentation.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';

class DataApi extends Fake implements ApiClient {
  DataApi(this.client);
  final Dio client;
  @override
  Dio get dioClient => client;
}

class DataCache extends Fake implements CacheService {
  @override
  Future<void> cacheReports(List<ReportModel> reports) async {}
  @override
  Future<List<ReportModel>> getCachedReports() async => [];
}

class DataPhotos extends Fake implements FcLocalPhotoRepository {}

class TaskRepo extends Fake implements CleanupTaskRepository {
  TaskRepo(this.task);
  final CleanupTask task;
  var completed = 0;
  bool refreshRequested = false;
  @override
  Future<CleanupTask> fetchTaskById(String id, {bool refresh = false}) async {
    refreshRequested = refresh;
    return task;
  }

  @override
  Future<void> markTaskComplete(String id) async {
    completed++;
  }
}

class ReportsRepo extends Fake implements FieldCrewReportRepository {
  List<ReportModel> reports = [];
  bool evidenceFails = false;
  List<String> requested = [];
  @override
  Future<List<ReportModel>> fetchReportsByIds(List<String> ids) async {
    requested = ids;
    return reports;
  }

  @override
  Future<Map<String, List<dynamic>>> fetchEvidenceByReportIds(
    List<String> ids,
  ) async {
    if (evidenceFails) throw StateError('offline');
    return {for (final id in ids) id: []};
  }
}

class AddressResolver extends Fake implements LocationSearchService {
  @override
  Future<String?> getAddressFromCoordinates(double lat, double lon) async =>
      'San Nicolas, Pasig City';
}

class ManualDetail extends FcTaskDetailNotifier {
  ManualDetail() : super('task');
  @override
  FcTaskDetailState build() => const FcTaskDetailState();
}

void main() {
  test('detail refresh awaits server stage while preserving pending local edits', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final local = FcLocalRepository(db);
    final client = Dio();
    var requests = 0;
    client.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      requests++;
      handler.resolve(Response(requestOptions: options, statusCode: 200,
        data: {'id': 'r', 'status': 'in_progress', 'stage': 'responded'}));
    }));
    await local.saveReports([ReportModel.fromJson({'id': 'r', 'status': 'unresolved'})]);
    final repo = FieldCrewReportRepository(DataApi(client), DataCache(), local, DataPhotos());
    final refreshed = await repo.fetchReportById('r', refresh: true);
    expect(refreshed.lifecycleStage, 'responded');
    expect(refreshed.status, 'in_progress');
    expect(requests, 1);
    await local.applyLocalReportPatch('r', {'stage': 'acknowledged'});
    final pending = await repo.fetchReportById('r', refresh: true);
    expect(pending.lifecycleStage, 'acknowledged');
  });

  test(
    'scope ignores unfiltered API results and preserves queued local report edits',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final local = FcLocalRepository(db);
      final client = Dio(BaseOptions(baseUrl: 'https://synthetic.invalid'));
      addTearDown(() => client.close());
      final requests = <RequestOptions>[];
      client.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) {
            requests.add(o);
            h.resolve(
              Response(
                requestOptions: o,
                statusCode: 200,
                data: [
                  for (final id in ['r1', 'r2', 'unrelated'])
                    {'id': id, 'title': 'Server $id'},
                ],
              ),
            );
          },
        ),
      );
      await local.saveReports([
        ReportModel.fromJson({'id': 'r1', 'title': 'Original'}),
      ]);
      await local.applyLocalReportPatch('r1', {'title': 'Pending local edit'});
      final repo = FieldCrewReportRepository(
        DataApi(client),
        DataCache(),
        local,
        DataPhotos(),
      );
      final reports = await repo.fetchReportsByIds(['r1', 'r2', 'r1']);
      expect(reports.map((r) => r.id), ['r1', 'r2']);
      expect(reports.first.title, 'Pending local edit');
      expect(
        (await local.getCachedReports()).any((r) => r.id == 'unrelated'),
        false,
      );
      expect(requests.single.queryParameters, {'ids': 'r1,r2', 'limit': 100});
    },
  );
  test(
    'task notifier uses canonical links, rejects other-task rows and blocks incomplete completion',
    () async {
      final task = CleanupTask.fromJson({
        'id': 'task',
        'report_ids': ['r1', 'r2'],
        'cluster_id': 'legacy',
        'street_address': 'Pasig',
      });
      final tasks = TaskRepo(task);
      final reports = ReportsRepo()
        ..reports = [
          ReportModel.fromJson({
            'id': 'r1',
            'status': 'resolved',
            'cleanup_task_id': 'task',
          }),
          ReportModel.fromJson({
            'id': 'r2',
            'status': 'resolved',
            'cleanup_task_id': 'other',
          }),
          ReportModel.fromJson({'id': 'unrelated', 'status': 'resolved'}),
        ];
      final container = ProviderContainer(
        overrides: [
          fcTaskDetailNotifierProvider('task').overrideWith(ManualDetail.new),
          cleanupTaskRepositoryProvider.overrideWithValue(tasks),
          fieldCrewReportRepositoryProvider.overrideWithValue(reports),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(
        fcTaskDetailNotifierProvider('task').notifier,
      );
      await notifier.refresh();
      final state = container.read(fcTaskDetailNotifierProvider('task'));
      expect(tasks.refreshRequested, true);
      expect(reports.requested, ['r1', 'r2']);
      expect(state.reports.map((r) => r.id), ['r1']);
      expect(state.errorMessage, contains('1 of 2'));
      await expectLater(notifier.markComplete(), throwsStateError);
      expect(tasks.completed, 0);
    },
  );
  test(
    'address enrichment and failed media have independent truthful states',
    () async {
      final task = CleanupTask.fromJson({
        'id': 'task',
        'report_ids': ['r1'],
        'location': 'POINT(121.075 14.561)',
      });
      final reports = ReportsRepo()
        ..evidenceFails = true
        ..reports = [
          ReportModel.fromJson({'id': 'r1'}),
        ];
      var cachedAddress = '';
      final container = ProviderContainer(
        overrides: [
          fcTaskDetailNotifierProvider('task').overrideWith(ManualDetail.new),
          cleanupTaskRepositoryProvider.overrideWithValue(TaskRepo(task)),
          fieldCrewReportRepositoryProvider.overrideWithValue(reports),
          taskAddressResolverProvider.overrideWithValue(AddressResolver()),
          taskAddressCacheProvider.overrideWithValue((task, address) async {
            cachedAddress = address;
          }),
        ],
      );
      addTearDown(container.dispose);
      await container
          .read(fcTaskDetailNotifierProvider('task').notifier)
          .refresh();
      final state = container.read(fcTaskDetailNotifierProvider('task'));
      expect(state.evidenceError, contains('does not mean no photos'));
      expect(state.resolvedAddress, 'San Nicolas, Pasig City');
      expect(cachedAddress, state.resolvedAddress);
      expect(state.isEvidenceLoading, false);
    },
  );
  test(
    'WKB location becomes coordinates/address and crew metadata survives caching',
    () {
      final task = CleanupTask.fromJson({
        'id': 'task',
        'location': '0101000020e6100000cdcccccccc445e40ac1c5a643b1f2d40',
        'assigned_team': {'name': 'Crew Alpha'},
        'assigned_members': [
          {'id': 'crew', 'full_name': 'Alexandra Rivera'},
        ],
      });
      expect(taskPoint(task)!.latitude, closeTo(14.561, .000001));
      expect(taskPlace(task), contains('Address unavailable'));
      expect(taskPlace(task, resolvedAddress: 'Pasig City'), 'Pasig City');
      final cached = CleanupTask.fromJson(task.toJson());
      expect(cached.assignedTeamName, 'Crew Alpha');
      expect(cached.assignedMembers.single['full_name'], 'Alexandra Rivera');
    },
  );
  test('citizen evidence accepts canonical and legacy media keys', () {
    for (final key in ['url', 'file_url', 'evidence_url', 'secure_url']) {
      expect(
        citizenEvidenceUrl({key: 'https://image.test/photo.jpg'}),
        'https://image.test/photo.jpg',
      );
    }
    expect(citizenEvidenceIsVideo({'resource_type': 'video'}), true);
    expect(citizenEvidenceUrl({}), isNull);
  });
}
