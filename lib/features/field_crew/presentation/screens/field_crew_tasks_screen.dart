import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ecopin_app/features/field_crew/data/models/cleanup_task_model.dart';
import 'package:ecopin_app/features/field_crew/presentation/controllers/fc_task_detail_presentation.dart';
import 'package:ecopin_app/features/field_crew/presentation/controllers/fc_tasks_presentation.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_jobs_view_switch.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_offline_ui.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_task_deadline_indicator.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_task_queue_card.dart';
import 'package:ecopin_app/features/field_crew/providers/cleanup_tasks_provider.dart';
import 'package:ecopin_app/features/field_crew/providers/field_crew_reports_provider.dart';
import 'package:ecopin_app/features/field_crew/providers/my_route_provider.dart';
import 'package:ecopin_app/shared/widgets/app_button.dart';
import 'package:ecopin_app/shared/widgets/app_state_view.dart';

/// Jobs tab: every squad job, split into To do and Done, in the crew's
/// established order of work.
class FieldCrewTasksScreen extends ConsumerStatefulWidget {
  const FieldCrewTasksScreen({super.key});

  @override
  ConsumerState<FieldCrewTasksScreen> createState() =>
      _FieldCrewTasksScreenState();
}

class _FieldCrewTasksScreenState extends ConsumerState<FieldCrewTasksScreen> {
  /// Search only appears once the list is long enough to need it.
  static const _searchFrom = 6;
  final _search = TextEditingController();
  CrewJobView _view = CrewJobView.todo;
  String _query = '';
  bool _onlyMine = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(allCleanupTasksProvider);
    ref.invalidate(myRouteProvider);
    ref.invalidate(cleanupTasksSyncedAtProvider);
    await Future.wait([
      ref
          .read(allCleanupTasksProvider.future)
          .then<void>((_) {}, onError: (Object _, StackTrace _) {}),
      ref
          .read(myRouteProvider.future)
          .then<void>((_) {}, onError: (Object _, StackTrace _) {}),
    ]);
  }

  void _clearFilters() {
    _search.clear();
    setState(() {
      _query = '';
      _onlyMine = false;
    });
  }

  String _updatedText(DateTime? at) {
    if (at == null) return 'Not updated yet';
    final local = at.toLocal();
    final now = DateTime.now();
    final today =
        local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    return 'Updated ${(today ? DateFormat.jm() : DateFormat.MMMd().add_jm()).format(local)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tasksAsync = ref.watch(allCleanupTasksProvider);
    final tasks = tasksAsync.value;
    final route = ref.watch(myRouteProvider).value;
    final held = ref.watch(heldTasksProvider);
    final localDone = ref.watch(completedTasksProvider);
    final knownReports = ref.watch(fieldCrewReportsProvider).value;
    final syncedAt = ref.watch(cleanupTasksSyncedAtProvider).value;
    final userId = ref.watch(fcCurrentUserIdProvider);

    Widget body;
    if (tasks == null && tasksAsync.isLoading) {
      body = const Align(
        alignment: Alignment.topCenter,
        child: LinearProgressIndicator(semanticsLabel: 'Loading your jobs'),
      );
    } else if (tasks == null) {
      body = AppStateView(
        icon: Icons.cloud_off_outlined,
        title: 'Jobs could not load',
        message:
            'Check your signal and try again. Jobs saved on this phone show here when they are available.',
        actionLabel: 'Reload jobs',
        onAction: _refresh,
      );
    } else {
      final filtered = filterCrewJobs(
        tasks,
        query: _query,
        onlyMine: _onlyMine,
        userId: userId,
      );
      final sections = splitCrewJobs(
        filtered,
        route: route,
        locallyCompleted: localDone,
      );
      final filtersActive = _query.trim().isNotEmpty || _onlyMine;
      Widget? deadline(CleanupTask task) {
        if (crewTaskIsFinished(task) || localDone.contains(task.id)) {
          return null;
        }
        final ids = taskReportIds(task);
        final reports = knownReports ?? task.reports ?? [];
        return FcTaskDeadlineIndicator(
          inline: true,
          reports: reports
              .where(
                (r) =>
                    ids.contains(r.id) &&
                    (r.cleanupTaskId == null || r.cleanupTaskId == task.id),
              )
              .toList(),
        );
      }

      final items = <Widget>[
        FcJobsViewSwitch(
          view: _view,
          todoCount: sections.todoCount,
          doneCount: sections.done.length,
          onChanged: (view) => setState(() => _view = view),
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                _updatedText(syncedAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: tasksAsync.isLoading ? null : _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
        if (tasksAsync.isLoading)
          const LinearProgressIndicator(semanticsLabel: 'Updating your jobs'),
        if (tasksAsync.hasError)
          FcOfflineNotice(
            error: true,
            message:
                'Your jobs could not refresh. The last saved jobs are shown below. Check each job before you act.',
            action: TextButton(
              onPressed: tasksAsync.isLoading ? null : _refresh,
              child: const Text('Reload jobs'),
            ),
          ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Only my jobs'),
          subtitle: Text(
            userId == null
                ? 'Sign in again to filter by your jobs.'
                : 'Hide jobs that are only for teammates.',
          ),
          value: _onlyMine,
          onChanged: userId == null
              ? null
              : (value) => setState(() => _onlyMine = value),
        ),
        if (tasks.length > _searchFrom || _query.isNotEmpty)
          TextField(
            controller: _search,
            textInputAction: TextInputAction.search,
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              labelText: 'Search jobs',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _search.clear();
                        setState(() => _query = '');
                      },
                    ),
            ),
          ),
      ];

      Widget empty(String title, String message, {bool clear = false}) =>
          FcOfflineCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                Text(message),
                if (clear) ...[
                  const SizedBox(height: 16),
                  AppButton(
                    text: 'Clear search and filters',
                    variant: ButtonVariant.secondary,
                    onPressed: _clearFilters,
                  ),
                ],
              ],
            ),
          );

      Widget heading(String text) => Semantics(
        header: true,
        child: Text(text, style: theme.textTheme.titleMedium),
      );

      if (_view == CrewJobView.todo) {
        if (sections.todoCount == 0) {
          items.add(
            tasks.isEmpty
                ? empty(
                    'No jobs saved on this phone',
                    'Reload when you have signal to check for new jobs.',
                  )
                : filtersActive
                ? empty(
                    'No jobs match',
                    'Nothing in To do matches your search or filter.',
                    clear: true,
                  )
                : empty(
                    'No jobs left to do in this list',
                    'This is the list saved on this phone. Reload to check for new jobs. Finished jobs are under Done.',
                  ),
          );
        } else {
          var number = 0;
          Widget card(CleanupTask task, {bool emphasized = false}) =>
              FcTaskQueueCard(
                task: task,
                position: ++number,
                emphasized: emphasized,
                deviceNote: held.contains(task.id)
                    ? 'On hold on this phone'
                    : null,
                footer: deadline(task),
              );
          if (sections.doingNow.isNotEmpty) {
            items.add(heading('Doing now'));
            items.addAll(
              sections.doingNow.map((task) => card(task, emphasized: true)),
            );
          }
          if (sections.todo.isNotEmpty) {
            items.add(heading('To do'));
            items.addAll(sections.todo.map(card));
          }
        }
      } else if (sections.done.isEmpty) {
        items.add(
          filtersActive
              ? empty(
                  'No jobs match',
                  'Nothing in Done matches your search or filter.',
                  clear: true,
                )
              : empty(
                  'No finished jobs in this list',
                  'Jobs that are completed or cancelled appear here.',
                ),
        );
      } else {
        items.addAll(
          sections.done.map(
            (task) => FcTaskQueueCard(
              task: task,
              done: true,
              deviceNote:
                  localDone.contains(task.id) && !crewTaskIsFinished(task)
                  ? 'Marked done on this phone'
                  : null,
            ),
          ),
        );
      }
      body = ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, index) => items[index],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Jobs')),
      body: RefreshIndicator(onRefresh: _refresh, child: body),
    );
  }
}
