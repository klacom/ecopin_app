import '../../sync/fc_sync_settings.dart';
import '../../providers/fc_investigation_provider.dart';
import '../widgets/fc_investigation_card.dart';
import '../widgets/cleanup_notes_dialog.dart';
import 'package:flutter/material.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_task_deadline_indicator.dart';
import '../controllers/fc_task_detail_presentation.dart';
import '../widgets/fc_offline_ui.dart';
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
import 'package:ecopin_app/features/field_crew/providers/fc_local_repository_provider.dart';
import 'package:ecopin_app/features/field_crew/data/models/cleanup_task_model.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_conflict_summary.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_trigger.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
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
        actions: [if (state.task != null) _PendingSyncBadge(taskId: taskId)],
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Could not load task.',
                style: AppTypography.h5.copyWith(
                  color: AppColors.textPrimaryDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                state.errorMessage!,
                style: AppTypography.caption.copyWith(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: notifier.refresh,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
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
              onOutcome: canAct
                  ? (report, outcome) =>
                        _queueReportOutcome(context, ref, task, report, outcome)
                  : null,
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

  Future<void> _queueReportOutcome(
    BuildContext context,
    WidgetRef ref,
    CleanupTask task,
    ReportModel report,
    String outcome,
  ) async {
    final actor = Supabase.instance.client.auth.currentUser?.id;
    if (actor == null) return;
    final investigation = ref.read(fcInvestigationProvider(taskId));
    final localPhoto = ref.read(fcLocalPhotoRepositoryProvider);
    final reportPhoto = await localPhoto.getActivePhoto(
      report.id,
      'report',
      'after',
    );
    final beforePhoto = outcome == 'cleaned'
        ? await localPhoto.getActivePhoto(report.id, 'report', 'before')
        : null;
    final hasBefore =
        beforePhoto != null ||
        report.beforePhotos.isNotEmpty ||
        report.beforePhotoUrl?.trim().isNotEmpty == true;
    final issueType = report.issueType?.toLowerCase() ?? '';
    final isScouting =
        issueType == 'scouting' || issueType == 'acknowledge_only';
    final evidence = <String>[
      if (reportPhoto != null)
        'local-photo:${reportPhoto.localPhotoId}'
      else if (report.afterPhotos.isNotEmpty)
        for (final p in report.afterPhotos)
          if ((p['url'] as String?)?.trim().isNotEmpty == true)
            p['url'] as String
          else if (report.afterPhotoUrl?.trim().isNotEmpty == true)
            report.afterPhotoUrl!,
    ];
    if (!context.mounted) return;
    if (!isScouting &&
        (evidence.isEmpty || (outcome == 'cleaned' && !hasBefore))) {
      final open = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(
            outcome == 'already_resolved'
                ? 'Photograph the clear site'
                : 'Document your cleanup',
          ),
          content: SingleChildScrollView(
            child: Text(
              outcome == 'already_resolved'
                  ? 'Open this report and capture one current photo in After Photos showing that the site is already clear. No Before photo is required. Do not upload the same photo twice. Then return here and select Already clear on arrival. This records an observation, not cleanup credit.'
                  : 'Open this report. Capture a Before photo before starting work, then an After photo of the cleaned site. Return here and select Cleaned here. If the site was already clear when you arrived, use Already clear on arrival instead.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Open report'),
            ),
          ],
        ),
      );
      if (open == true && context.mounted) {
        await context.push(
          '/field-crew/tasks/${Uri.encodeComponent(task.id)}/reports/${Uri.encodeComponent(report.id)}',
        );
        if (context.mounted) {
          await ref
              .read(fcTaskDetailNotifierProvider(taskId).notifier)
              .refresh();
        }
      }
      return;
    }
    final notes = await showCleanupNotesDialog(
      context,
      title: outcome == 'already_resolved'
          ? 'Site already clear?'
          : 'Confirm physical cleanup',
      description: outcome == 'already_resolved'
          ? 'Describe the site on arrival. This records an observation, not cleanup credit.'
          : 'Describe the cleanup performed. Before and After photos are required; the server records when this proof is accepted.',
    );
    if (notes == null || !context.mounted) return;
    try {
      final receipt = investigation.receipt(report.id);
      if (receipt['crew_id'] != actor) {
        throw StateError(
          'Account changed. Reopen the task before recording an outcome.',
        );
      }
      await ref
          .read(fcLocalRepositoryProvider)
          .enqueueReportOutcome(
            task: task,
            report: report,
            crewId: actor,
            outcome: outcome,
            observedAt: DateTime.now(),
            evidenceRefs: evidence,
            notes: notes,
            investigation: receipt,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Outcome saved offline. It will sync with its assignment receipt.',
            ),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
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
class _PendingSyncBadge extends ConsumerWidget {
  final String taskId;
  const _PendingSyncBadge({required this.taskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(fcSyncStateProvider);
    ref.watch(fcPendingWritesProvider);
    final automatic = ref.watch(fcSyncSettingsProvider).autoSyncEnabled;
    final localRepo = ref.watch(fcLocalRepositoryProvider);

    return FutureBuilder<bool>(
      key: ValueKey(syncState.lastSyncAt),
      future: _hasPending(localRepo, ref, taskId),
      builder: (context, snap) {
        if (snap.data != true) return const SizedBox.shrink();
        return _SyncChip(phase: syncState.phase, automatic: automatic);
      },
    );
  }

  Future<bool> _hasPending(
    dynamic localRepo,
    WidgetRef ref,
    String taskId,
  ) async {
    final items = await localRepo.getPendingOutboxItems();
    if (items.any((i) => i.entityId == taskId)) return true;
    final photos = ref.read(fcLocalPhotoRepositoryProvider);
    final uploads = await photos.getPendingUploads();
    final deletes = await photos.getPendingDeletes();
    return [...uploads, ...deletes].any((p) => p.entityId == taskId);
  }
}

/// Small AppBar chip showing sync status.
class _SyncChip extends StatelessWidget {
  final FcSyncPhase phase;
  final bool automatic;
  const _SyncChip({required this.phase, required this.automatic});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (phase) {
      FcSyncPhase.syncing => ('Syncing…', AppColors.primaryDark),
      FcSyncPhase.error => ('Sync Error', AppColors.error),
      FcSyncPhase.partialFailure => ('Sync attention', AppColors.error),
      _ => (automatic ? 'Sync queued' : 'Pending Sync', AppColors.warning),
    };
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Chip(
        label: Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.white),
        ),
        backgroundColor: color,
        padding: EdgeInsets.zero,
        labelPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: -4),
      ),
    );
  }
}
