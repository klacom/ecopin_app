import 'package:ecopin_app/features/field_crew/data/models/cleanup_task_model.dart';
import 'package:ecopin_app/features/field_crew/data/models/route_model.dart';
import 'package:ecopin_app/features/field_crew/data/models/waypoint_model.dart';
import 'package:ecopin_app/features/field_crew/presentation/controllers/fc_dashboard_presentation.dart';
import 'package:flutter_test/flutter_test.dart';

CleanupTask dashboardTask(
  String id, {
  String status = 'pending',
  String priority = 'normal',
  String? address,
  String location = 'Pasig City',
  String? created,
}) => CleanupTask.fromJson({
  'id': id,
  'title': 'Assigned cleanup $id',
  'status': status,
  'priority': priority,
  'street_address': address,
  'location': location,
  'created_at': created ?? '2026-10-14T00:00:00Z',
});
RouteModel dashboardRoute(List<WaypointModel> waypoints) => RouteModel(
  id: 'assigned-route',
  crewName: 'SWMO crew',
  waypoints: waypoints,
);

void main() {
  test(
    'current task keeps established ordering and separates terminal, held, and locally completed work',
    () {
      final tasks = [
        dashboardTask('later'),
        dashboardTask('urgent', priority: 'urgent'),
        dashboardTask('active', status: 'in_progress'),
        dashboardTask('earlier'),
        dashboardTask('done', status: 'completed'),
        dashboardTask('cancelled', status: 'cancelled'),
        dashboardTask('held'),
        dashboardTask('local-completion'),
      ];
      final order = orderedCrewTasks(
        tasks,
        route: dashboardRoute([
          WaypointModel(
            waypointType: 'task',
            cleanupTaskId: 'later',
            sequenceOrder: 3,
          ),
          WaypointModel(
            waypointType: 'task',
            cleanupTaskId: 'earlier',
            sequenceOrder: 1,
          ),
        ]),
        held: {'held'},
        locallyCompleted: {'local-completion'},
      );
      expect(order.map((task) => task.id), [
        'active',
        'earlier',
        'later',
        'urgent',
      ]);
      expect(tasks.first.id, 'later');
      expect(tasks, hasLength(8));
    },
  );
  test(
    'fallback order retains urgent/high grouping followed by creation time',
    () {
      final tasks = [
        dashboardTask('normal', created: '2026-01-01'),
        dashboardTask('urgent-new', priority: 'urgent', created: '2026-10-14'),
        dashboardTask('high-old', priority: 'high', created: '2026-10-01'),
      ];
      expect(orderedCrewTasks(tasks).map((task) => task.id), [
        'high-old',
        'urgent-new',
        'normal',
      ]);
    },
  );
  test(
    'location favors a full supplied address and formats valid coordinates without raw geometry',
    () {
      expect(
        crewTaskLocation(
          dashboardTask(
            'address',
            address: '  Caruncho Avenue, San Nicolas, Pasig  ',
            location: 'POINT(121.08 14.58)',
          ),
        ),
        'Caruncho Avenue, San Nicolas, Pasig',
      );
      expect(
        crewTaskLocation(
          dashboardTask('point', location: 'POINT(121.08 14.58)'),
        ),
        '14.5800, 121.0800',
      );
      expect(
        crewTaskLocation(dashboardTask('invalid', location: 'POINT(NaN 999)')),
        'Location unavailable',
      );
      expect(
        crewTaskLocation(dashboardTask('empty', location: '')),
        'Location unavailable',
      );
      expect(crewTaskLabel('in_progress'), 'In progress');
      expect(
        crewTaskPath('task/with spaces'),
        '/field-crew/tasks/task%2Fwith%20spaces',
      );
    },
  );
}
