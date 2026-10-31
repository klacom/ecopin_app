import '../widgets/fc_investigation_card.dart';
import '../widgets/cleanup_notes_dialog.dart';
import 'package:flutter/material.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_task_deadline_indicator.dart';
import '../controllers/fc_task_detail_presentation.dart';
import '../widgets/fc_offline_ui.dart';
import '../widgets/fc_pending_sync_badge.dart';
import 'package:ecopin_app/shared/widgets/app_state_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/core/theme/typography.dart';
import 'package:ecopin_app/features/field_crew/providers/fc_task_detail_notifier.dart';
import 'package:ecopin_app/features/field_crew/providers/cleanup_tasks_provider.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_report_table.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_photo_gallery_card.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_task_sidebar_card.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_mark_complete_button.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_shimmer_card.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_conflict_summary.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_trigger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FieldCrewTaskDetailScreen extends ConsumerWidget {
  final String taskId;

  const FieldCrewTaskDetailScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(fcSyncStateProvider, (previous, next) {
      if (next.lastSyncAt != null && previous?.lastSyncAt != next.lastSyncAt) {
        ref.read(fcTaskDetailNotifierProvider(taskId).notifier).refresh();
      }
    });
    final state = ref.watch(fcTaskDetailNotifierProvider(taskId));
    final notifier = ref.read(fcTaskDetailNotifierProvider(taskId).notifier);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : Colors.black87;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Task Details',
          style: AppTypography.h5.copyWith(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [if (state.task != null) FcPendingSyncBadge(entityId: taskId)],
      ),
      body: _buildBody(context, ref, state, notifier),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    FcTaskDetailState state,
    FcTaskDetailNotifier notifier,
  ) {
    if (state.isLoading && state.task == null) {
      return const _TaskDetailSkeleton();
    }

    if (state.errorMessage != null && state.task == null) {
      return AppStateView(
        title: 'Could not load task',
        message:
            'It may not be available offline yet. Check your connection and try again.',
        icon: Icons.cloud_off,
        actionLabel: 'Retry',
        onAction: notifier.refresh,
      );
    }

    final task = state.task!;
    final reports = state.reports;
    final expected = taskReportIds(task).length;
    final handled = reports.where(reportIsHandled).length;
    final actor = Supabase.instance.client.auth.currentUser?.id;
    final isAssigned = actor != null && task.assignedCrewIds.contains(actor);
    final canAct =
        isAssigned &&
        !{'completed', 'cancelled'}.contains(task.status.toLowerCase());
    final investigation = ref.watch(fcActiveInvestigationProvider(taskId));
    return RefreshIndicator(
      onRefresh: notifier.refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (state.isLoading)
                    const LinearProgressIndicator(
                      semanticsLabel: 'Refreshing task',
                    ),
                  const FcConflictSummary(),
                  FcTaskSidebarCard(task: task, address: state.resolvedAddress),
                  if (canAct) ...[
                    const SizedBox(height: 16),
                    FcInvestigationCard(session: investigation),
                  ],
                  if (!{
                    'completed',
                    'closed',
                    'cancelled',
                  }.contains(task.status.toLowerCase()))
                    FcTaskDeadlineIndicator(reports: reports),
                  const SizedBox(height: 20),
                  if (state.errorMessage != null) ...[
                    FcOfflineNotice(
                      error: true,
                      message: state.errorMessage!,
                      action: TextButton(
                        onPressed: state.isLoading ? null : notifier.refresh,
                        child: const Text('Refresh task'),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (expected > 0)
                    FcOfflineCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Report progress',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$handled of $expected linked reports handled',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: handled / expected,
                            semanticsLabel:
                                '$handled of $expected linked reports handled',
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Progress covers only reports linked to this task.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  if (expected > 0) const SizedBox(height: 20),
                  FcPhotoGalleryCard(
                    reports: reports,
                    evidenceByReport: state.evidenceByReport,
                    isLoading: state.isEvidenceLoading,
                    error: state.evidenceError,
                    onRetry: () => notifier.refreshEvidence(),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Reports in this task ($expected)',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    expected == 0
                        ? 'This is a standalone task with no linked reports.'
                        : 'Open a report for its location, evidence and available actions.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: FcReportTable(
              reports: reports,
              taskId: taskId,
              onReturn: notifier.refresh,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverToBoxAdapter(
              child: ListenableBuilder(
                listenable: investigation,
                builder: (context, _) => FcMarkCompleteButton(
                  investigationComplete: investigation.canCompleteTask,
                  task: task,
                  reports: reports,
                  isRefreshing: state.isLoading || reports.length != expected,
                  onComplete: () async {
                    final notes = await showCleanupNotesDialog(
                      context,
                      title: 'Complete task',
                      description:
                          'Summarize the work done. Photos and the on-site investigation are checked again during sync.',
                    );
                    if (notes == null) return;
                    await notifier.markComplete(notes: notes);
                    if (!context.mounted) return;
                    ref
                        .read(completedTasksProvider.notifier)
                        .addCompletedTask(taskId);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Task completion saved on this device for sync.',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}

class _TaskDetailSkeleton extends StatelessWidget {
  const _TaskDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(AppColors.spaceLG),
          sliver: SliverToBoxAdapter(
            child: Column(
              children: const [
                FcShimmerCard(height: 200),
                SizedBox(height: AppColors.spaceLG),
                FcShimmerCard(height: 100),
                SizedBox(height: AppColors.spaceLG),
                FcShimmerCard(height: 60),
                SizedBox(height: AppColors.spaceXL),
                FcShimmerCard(height: 300),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Small chip in the AppBar indicating pending sync.
/// Small AppBar chip showing sync status.
