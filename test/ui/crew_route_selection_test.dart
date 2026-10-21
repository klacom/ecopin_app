import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/features/field_crew/providers/my_route_provider.dart';
import 'package:ecopin_app/features/field_crew/providers/cleanup_tasks_provider.dart';
import 'package:ecopin_app/features/field_crew/providers/field_crew_reports_provider.dart';
import 'package:ecopin_app/features/field_crew/data/models/cleanup_task_model.dart';
import 'package:ecopin_app/features/field_crew/data/models/route_model.dart';
import 'package:ecopin_app/features/field_crew/data/models/waypoint_model.dart';

CleanupTask task(String id, String route, {String status = 'pending'}) =>
    CleanupTask.fromJson({
      'id': id,
      'crew_route_id': route,
      'status': status,
      'created_at': '2026-10-01T00:00:00Z',
    });
void main() {
  test(
    'completed and unavailable historical routes do not hide unfinished assigned routes',
    () async {
      final route = RouteModel(
        id: 'available',
        crewName: 'Alpha',
        waypoints: [
          WaypointModel(
            waypointType: 'task',
            sequenceOrder: 1,
            cleanupTaskId: 'done',
          ),
          WaypointModel(
            waypointType: 'task',
            sequenceOrder: 2,
            cleanupTaskId: 'active',
          ),
        ],
      );
      final container = ProviderContainer(
        overrides: [
          activeRoutesProvider.overrideWith((ref) async => [route]),
          myCleanupTasksProvider.overrideWith(
            (ref) async => [
              task('done', 'old-route', status: 'completed'),
              task('missing', 'not-published'),
              task('active', 'available', status: 'in_progress'),
            ],
          ),
          fieldCrewReportsProvider.overrideWith((ref) async => []),
        ],
      );
      addTearDown(container.dispose);
      final selected = await container.read(myRouteProvider.future);
      expect(selected?.id, 'available');
      expect(selected?.waypoints.map((w) => w.cleanupTaskId), ['active']);
    },
  );
  test(
    'held and locally completed tasks do not select a stale route',
    () async {
      final container = ProviderContainer(
        overrides: [
          activeRoutesProvider.overrideWith(
            (ref) async => [
              RouteModel(id: 'route', crewName: 'Alpha', waypoints: []),
            ],
          ),
          myCleanupTasksProvider.overrideWith(
            (ref) async => [task('held', 'route'), task('complete', 'route')],
          ),
          fieldCrewReportsProvider.overrideWith((ref) async => []),
        ],
      );
      addTearDown(container.dispose);
      container.read(heldTasksProvider.notifier).holdTask('held');
      container
          .read(completedTasksProvider.notifier)
          .addCompletedTask('complete');
      expect(await container.read(myRouteProvider.future), isNull);
    },
  );
  test(
    'route service failures stay errors rather than a missing-route result',
    () async {
      final container = ProviderContainer(
        overrides: [
          activeRoutesProvider.overrideWith(
            (ref) async => throw StateError('service down'),
          ),
        ],
      );
      addTearDown(container.dispose);
      await expectLater(
        container.read(myRouteProvider.future),
        throwsStateError,
      );
    },
  );
}
