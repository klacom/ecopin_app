import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ecopin_app/features/field_crew/providers/cleanup_tasks_provider.dart';
import 'package:ecopin_app/features/field_crew/providers/my_route_provider.dart';
import 'package:ecopin_app/features/field_crew/offline/fc_offline_package_notifier.dart';
import 'package:ecopin_app/routes/app_routes.dart';
import 'package:ecopin_app/core/constants/app_constants.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/shared/notifications/presentation/widgets/notification_badge_action.dart';
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 16,
              children: [
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: FcGreetingHeader()),
                    SizedBox(width: 8),
                    NotificationBadgeAction(role: UserRole.fieldCrew),
                  ],
                ),
                const FcSyncStatusBar(),
                if (assignments.isLoading)
                  const LinearProgressIndicator(
                    semanticsLabel: 'Loading your jobs',
                  ),
                if (assignments.hasError)
                  FcOfflineNotice(
                    error: true,
                    message: assignments.hasValue
                        ? 'Your jobs could not refresh. The last saved jobs are shown below. Check each job before you act.'
                        : 'Your jobs could not load. Try again to get your jobs.',
                    action: TextButton(
                      onPressed: assignments.isLoading
                          ? null
                          : () => _refresh(ref),
                      child: const Text('Reload jobs'),
                    ),
                  ),
                if (current != null) FcCurrentObjectiveCard(task: current),
                if (tasks != null && current == null)
                  FcOfflineCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'No job to open next',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          tasks.isEmpty
                              ? 'No jobs are saved on this phone. Reload when you have signal to check for new jobs.'
                              : 'Your other jobs are done, on hold, or marked done on this phone. Check “Saved on this phone” or the Jobs tab.',
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
                      semanticsLabel: 'Updating your route',
                    ),
                  if (route.hasError)
                    FcOfflineNotice(
                      error: true,
                      message: route.hasValue
                          ? 'Your route could not refresh. The last saved route is shown below.'
                          : 'Your route could not load. Your jobs are still available.',
                      action: TextButton(
                        onPressed: () {
                          ref.invalidate(activeRoutesProvider);
                          ref.invalidate(myRouteProvider);
                        },
                        child: const Text('Reload route'),
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
                  Semantics(
                    header: true,
                    child: Text(
                      'Up next',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  for (final (index, task) in active.skip(1).take(2).indexed)
                    FcTaskQueueCard(task: task, position: index + 2),
                  if (active.length > 3)
                    _SeeAllJobsRow(extra: active.length - 3),
                ],
                if (tasks != null) const FcMetricsHeader(),
                if (localTasks.isNotEmpty || heldTasks.isNotEmpty)
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(bottom: 8),
                    title: const Text('Saved on this phone'),
                    subtitle: Text(
                      '${localTasks.length} marked done · ${heldTasks.length} on hold',
                    ),
                    children: [
                      if (localTasks.isNotEmpty) ...[
                        const Text('Marked done on this phone'),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'These are saved on this phone. Open the sending details to see what reached the server.',
                          ),
                        ),
                        for (final task in localTasks.take(3))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: FcTaskQueueCard(task: task),
                          ),
                      ],
                      if (heldTasks.isNotEmpty) ...[
                        const Text('On hold on this phone'),
                        for (final task in heldTasks.take(3))
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: FcTaskQueueCard(task: task),
                          ),
                      ],
                    ],
                  ),
                const _PreparationLink(),
                Column(
                  children: [
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                      onPressed: assignments.isLoading
                          ? null
                          : () => _refresh(ref),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh jobs'),
                    ),
                    Text(
                      'Without signal, this screen may show saved copies.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SeeAllJobsRow extends StatelessWidget {
  const _SeeAllJobsRow({required this.extra});
  final int extra;
  @override
  Widget build(BuildContext context) => TextButton(
    style: TextButton.styleFrom(
      minimumSize: const Size(48, 56),
      alignment: Alignment.centerLeft,
    ),
    onPressed: () => context.go(FieldCrewAppRoutes.tasks),
    child: Row(
      children: [
        Expanded(
          child: Text(
            '$extra more ${extra == 1 ? 'job' : 'jobs'} · See all jobs',
          ),
        ),
        const Icon(Icons.chevron_right),
      ],
    ),
  );
}

class _PreparationLink extends ConsumerWidget {
  const _PreparationLink();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final package = ref.watch(fcOfflinePackageNotifierProvider);
    final gaps = package.steps.any((step) => step.error != null);
    final (title, action) = package.isDownloading
        ? ('Downloading your jobs', 'See progress')
        : package.isReady
        ? gaps
              ? ('Download is missing some information', 'Review download')
              : ('Your jobs are on this phone', 'Review download')
        : ('Working where signal is weak?', 'Download jobs to this phone');
    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        side: BorderSide(color: theme.dividerTheme.color ?? theme.dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        minVerticalPadding: 12,
        leading: Icon(
          gaps && package.isReady
              ? Icons.warning_amber_rounded
              : Icons.download_for_offline_outlined,
          size: 28,
        ),
        title: Text(title),
        subtitle: Text(action),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(FieldCrewAppRoutes.prepareOffline),
      ),
    );
  }
}
