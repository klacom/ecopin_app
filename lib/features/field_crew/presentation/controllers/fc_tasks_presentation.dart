import 'package:ecopin_app/features/field_crew/data/models/cleanup_task_model.dart';
import 'package:ecopin_app/features/field_crew/data/models/route_model.dart';
import 'fc_dashboard_presentation.dart';

enum CrewJobView { todo, done }

/// Jobs split for the Jobs tab. Server order is not used: to-do work follows
/// the crew's established order, finished work lists the newest first.
class CrewJobSections {
  const CrewJobSections({
    required this.doingNow,
    required this.todo,
    required this.done,
  });
  final List<CleanupTask> doingNow, todo, done;
  int get todoCount => doingNow.length + todo.length;
}

bool crewTaskIsFinished(CleanupTask task) =>
    {'completed', 'closed', 'cancelled'}.contains(crewTaskKey(task.status));

CrewJobSections splitCrewJobs(
  List<CleanupTask> tasks, {
  RouteModel? route,
  Set<String> locallyCompleted = const {},
}) {
  final open = <CleanupTask>[];
  final done = <CleanupTask>[];
  for (final task in tasks) {
    (crewTaskIsFinished(task) || locallyCompleted.contains(task.id)
            ? done
            : open)
        .add(task);
  }
  sortCrewTasks(open, route: route);
  done.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  return CrewJobSections(
    doingNow: open
        .where((task) => crewTaskKey(task.status) == 'in_progress')
        .toList(),
    todo: open
        .where((task) => crewTaskKey(task.status) != 'in_progress')
        .toList(),
    done: done,
  );
}

/// Search matches what the crew can see on a card: title, place and notes.
List<CleanupTask> filterCrewJobs(
  List<CleanupTask> tasks, {
  String query = '',
  bool onlyMine = false,
  String? userId,
}) {
  final needle = query.trim().toLowerCase();
  return tasks.where((task) {
    if (onlyMine &&
        (userId == null || !task.assignedCrewIds.contains(userId))) {
      return false;
    }
    if (needle.isEmpty) return true;
    return [
      task.title,
      task.description,
      crewTaskPlaceLine(task),
    ].any((text) => text.toLowerCase().contains(needle));
  }).toList();
}
