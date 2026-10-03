import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/core/theme/typography.dart';
import 'package:ecopin_app/features/field_crew/providers/cleanup_tasks_provider.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_metrics_header.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_shift_progress_bar.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_current_objective_card.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_task_queue_card.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_shimmer_card.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_sync_status_bar.dart';
import 'package:ecopin_app/features/field_crew/offline/fc_offline_package_notifier.dart';
import 'package:ecopin_app/routes/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:ecopin_app/features/field_crew/providers/my_route_provider.dart';

class FieldCrewDashboardScreen extends ConsumerWidget {
  const FieldCrewDashboardScreen({super.key});
  static final _log = Logger('FieldCrewDashboardScreen');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(myCleanupTasksProvider);
    final routeAsync = ref.watch(myRouteProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.refresh(myCleanupTasksProvider.future);
            ref.invalidate(myRouteProvider);
          },
          color: AppColors.primaryDark,
          backgroundColor: AppColors.surfaceDark,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppColors.spaceLG),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FcSyncStatusBar(),
                const _PrepareOfflineBanner(),
                const FcMetricsHeader(),
                const SizedBox(height: AppColors.spaceXL),

                tasksAsync.when(
                  data: (tasks) {
                    _log.info('Received ${tasks.length} total tasks from provider.');
                    final activeTasks = tasks
                        .where((t) => t.status != 'completed')
                        .toList();
                    _log.info('Filtered to ${activeTasks.length} active tasks (excluding completed).');

                    final route = routeAsync.value;
                    final Map<String, int> taskSequence = {};
                    if (route != null) {
                      for (var wp in route.waypoints) {
                        if (wp.cleanupTaskId != null) {
                          taskSequence[wp.cleanupTaskId!] = wp.sequenceOrder;
                        }
                      }
                      _log.fine('Loaded route sequence for ${taskSequence.length} tasks.');
                    }

                    // Sort: in_progress first. Then by route sequence order. Finally fallback to priority.
                    activeTasks.sort((a, b) {
                      if (a.status == 'in_progress' &&
                          b.status != 'in_progress')
                        return -1;
                      if (a.status != 'in_progress' &&
                          b.status == 'in_progress')
                        return 1;

                      if (taskSequence.isNotEmpty) {
                        final seqA = taskSequence[a.id] ?? 9999;
                        final seqB = taskSequence[b.id] ?? 9999;
                        if (seqA != seqB) return seqA.compareTo(seqB);
                      }

                      final aHigh =
                          a.priority.toLowerCase() == 'high' ||
                          a.priority.toLowerCase() == 'urgent';
                      final bHigh =
                          b.priority.toLowerCase() == 'high' ||
                          b.priority.toLowerCase() == 'urgent';
                      if (aHigh && !bHigh) return -1;
                      if (!aHigh && bHigh) return 1;
                      
                      // Deterministic tie-breaker to ensure online and offline order match exactly
                      return a.createdAt.compareTo(b.createdAt);
                    });

                    if (activeTasks.isEmpty) {
                      _log.info('No active tasks remaining. Showing empty state.');
                      return Column(
                        children: [
                          const FcShiftProgressBar(),
                          const SizedBox(height: AppColors.spaceXL),
                          _buildEmptyState(),
                        ],
                      );
                    }

                    final currentTask = activeTasks.first;
                    final queuedTasks = activeTasks.skip(1).take(3).toList();
                    _log.info('Selected Current Objective: ${currentTask.id} (Priority: ${currentTask.priority}, Status: ${currentTask.status})');
                    _log.info('Selected Up Next Queue: ${queuedTasks.map((t) => t.id).toList()}');

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FcCurrentObjectiveCard(task: currentTask),
                        const SizedBox(height: AppColors.spaceLG),
                        const FcShiftProgressBar(),
                        const SizedBox(height: AppColors.spaceXL),
                        Text(
                          'Up Next',
                          style: AppTypography.h5.copyWith(
                            color: AppColors.textPrimaryDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppColors.spaceMD),
                        if (queuedTasks.isEmpty)
                          Text(
                            'No other tasks in queue.',
                            style: AppTypography.body.copyWith(
                              color: Colors.grey,
                            ),
                          )
                        else
                          ...queuedTasks.map((t) => FcTaskQueueCard(task: t)),
                      ],
                    );
                  },
                  loading: () => const _DashboardSkeleton(),
                  error: (err, stack) => Center(
                    child: Text(
                      'Error loading tasks: $err',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: AppColors.primaryDark.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppColors.spaceMD),
            Text(
              'You\'re all caught up!',
              style: AppTypography.h5.copyWith(
                color: AppColors.textPrimaryDark,
              ),
            ),
            const SizedBox(height: AppColors.spaceSM),
            Text(
              'No active tasks assigned.',
              style: AppTypography.body.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();
  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        FcShimmerCard(height: 250),
        SizedBox(height: AppColors.spaceXL),
        FcShimmerCard(height: 80),
        SizedBox(height: AppColors.spaceMD),
        FcShimmerCard(height: 80),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Offline prep banner — shown on the dashboard before package is prepared
// ─────────────────────────────────────────────────────────────────────────────

class _PrepareOfflineBanner extends ConsumerWidget {
  const _PrepareOfflineBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pkgState = ref.watch(fcOfflinePackageNotifierProvider);

    // Hide if already ready or currently downloading.
    if (pkgState.isReady || pkgState.isDownloading) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => context.push(FieldCrewAppRoutes.prepareOffline),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFCCFF00).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFCCFF00).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.download_for_offline,
                color: Color(0xFFCCFF00),
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Prepare for offline field work',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFFCCFF00),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
