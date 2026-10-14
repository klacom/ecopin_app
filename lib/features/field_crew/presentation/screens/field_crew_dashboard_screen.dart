import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ecopin_app/features/field_crew/providers/cleanup_tasks_provider.dart';
import 'package:ecopin_app/features/field_crew/providers/my_route_provider.dart';
import 'package:ecopin_app/features/field_crew/offline/fc_offline_package_notifier.dart';
import 'package:ecopin_app/routes/app_routes.dart';
import '../controllers/fc_dashboard_presentation.dart';
import '../controllers/fc_sync_ui_providers.dart';
import '../widgets/fc_metrics_header.dart';
import '../widgets/fc_shift_progress_bar.dart';
import '../widgets/fc_current_objective_card.dart';
import '../widgets/fc_task_queue_card.dart';
import '../widgets/fc_sync_status_bar.dart';
import '../widgets/fc_dashboard_route_card.dart';
import '../widgets/fc_offline_ui.dart';

class FieldCrewDashboardScreen extends ConsumerWidget {
  const FieldCrewDashboardScreen({super.key});
  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(myCleanupTasksProvider);
    ref.invalidate(activeRoutesProvider);
    ref.invalidate(myRouteProvider);
    ref.invalidate(fcPendingSummaryProvider);
    ref.invalidate(fcSyncNetworkProvider);
    // Each provider presents its own unavailable/stale state after refresh.
    await Future.wait([
      ref
          .read(myCleanupTasksProvider.future)
          .then<void>((_) {}, onError: (Object _, StackTrace _) {}),
      ref
          .read(myRouteProvider.future)
          .then<void>((_) {}, onError: (Object _, StackTrace _) {}),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignments = ref.watch(myCleanupTasksProvider);
    final route = ref.watch(myRouteProvider);
    final held = ref.watch(heldTasksProvider);
    final localComplete = ref.watch(completedTasksProvider);
    final tasks = assignments.value;
    final active = tasks == null
        ? null
        : orderedCrewTasks(
            tasks,
            route: route.value,
            held: held,
            locallyCompleted: localComplete,
          );
    final current = active?.firstOrNull;
    final localTasks =
        tasks?.where((task) => localComplete.contains(task.id)).toList() ?? [];
    final heldTasks =
        tasks
            ?.where(
              (task) =>
                  held.contains(task.id) &&
                  !localComplete.contains(task.id) &&
                  !{
                    'completed',
                    'cancelled',
                  }.contains(crewTaskKey(task.status)),
            )
            .toList() ??
        [];
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _refresh(ref),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 20,
              children: [
                const FcMetricsHeader(),
                const FcSyncStatusBar(),
                if (assignments.isLoading)
                  const LinearProgressIndicator(
                    semanticsLabel: 'Loading assigned tasks',
                  ),
                if (assignments.hasError)
                  FcOfflineNotice(
                    error: true,
                    message: assignments.hasValue
                        ? 'Assignments could not refresh. The last loaded tasks remain below; check their current instructions before responding.'
                        : 'Assignments could not load. Try again to retrieve your assigned work.',
                    action: TextButton(
                      onPressed: assignments.isLoading
                          ? null
                          : () => _refresh(ref),
                      child: const Text('Retry assignments'),
                    ),
                  ),
                if (current != null) FcCurrentObjectiveCard(task: current),
                if (tasks != null && current == null)
                  FcOfflineCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'No active task to open next',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          tasks.isEmpty
                              ? 'No assignments are available in the loaded records. Refresh when connected to check for updates.'
                              : 'Review recorded completion, held tasks, or the full assignment list below. No new completion is inferred from an empty queue.',
                        ),
                      ],
                    ),
                  ),
                if (current != null ||
                    route.hasValue ||
                    route.hasError ||
                    route.isLoading) ...[
                  if (route.isLoading)
                    const LinearProgressIndicator(
                      semanticsLabel: 'Updating route context',
                    ),
                  if (route.hasError)
                    FcOfflineNotice(
                      error: true,
                      message: route.hasValue
                          ? 'Route context could not refresh. The last loaded plan remains below.'
                          : 'Route context could not load. Task details are still available.',
                      action: TextButton(
                        onPressed: () {
                          ref.invalidate(activeRoutesProvider);
                          ref.invalidate(myRouteProvider);
                        },
                        child: const Text('Retry route context'),
                      ),
                    ),
                  if (!route.isLoading || route.hasValue || route.hasError)
                    FcDashboardRouteCard(
                      route: route.value,
                      currentTask: current,
                    ),
                ],
                if (tasks != null) FcShiftProgressBar(tasks: tasks),
                if (active != null && active.length > 1) ...[
                  Text(
                    'Up next',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    'In-progress tasks come first, then the supplied route order and existing priority order.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  for (final task in active.skip(1).take(3))
                    FcTaskQueueCard(task: task),
                  if (active.length > 4)
                    Text(
                      '${active.length - 4} additional active assignments are available in the full task list.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                ],
                if (localTasks.isNotEmpty) ...[
                  Text(
                    'Recorded complete on this device',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    'These completion receipts were recorded on this device in this session. They may already be synced; review Sync Center for server results.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  for (final task in localTasks.take(3))
                    FcTaskQueueCard(task: task),
                ],
                if (heldTasks.isNotEmpty) ...[
                  Text(
                    'On hold on this device',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    'These assignments are not selected as the next task. Open details to review their instructions.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  for (final task in heldTasks.take(3))
                    FcTaskQueueCard(task: task),
                ],
                TextButton(
                  onPressed: () => context.go(FieldCrewAppRoutes.tasks),
                  child: const Text('View all assignments'),
                ),
                const _PreparationLink(),
                Text(
                  'Loaded assignments may include cached records. Refresh when connected to check for updates.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PreparationLink extends ConsumerWidget {
  const _PreparationLink();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final package = ref.watch(fcOfflinePackageNotifierProvider);
    final gaps = package.steps.any((step) => step.error != null);
    final label = package.isDownloading
        ? 'Preparation is in progress'
        : package.isReady
        ? gaps
              ? 'Offline package has gaps'
              : 'Review offline preparation'
        : 'Prepare assigned work for offline use';
    return OutlinedButton.icon(
      onPressed: () => context.push(FieldCrewAppRoutes.prepareOffline),
      icon: const Icon(Icons.download_for_offline_outlined),
      label: Text(label),
    );
  }
}
