import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ecopin_app/features/field_crew/providers/cleanup_tasks_provider.dart';
import 'package:ecopin_app/features/field_crew/providers/fc_task_detail_notifier.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_trigger.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import 'package:ecopin_app/shared/widgets/app_state_view.dart';
import 'package:ecopin_app/features/field_crew/location/crew_investigation_session.dart';
import '../controllers/fc_task_detail_presentation.dart';
import '../widgets/cleanup_notes_dialog.dart';
import '../widgets/fc_citizen_photos_section.dart';
import '../widgets/fc_complete_job_bar.dart';
import '../widgets/fc_conflict_summary.dart';
import '../widgets/fc_job_header_card.dart';
import '../widgets/fc_job_steps_card.dart';
import '../widgets/fc_offline_ui.dart';
import '../widgets/fc_pending_sync_badge.dart';
import '../widgets/fc_report_table.dart';

/// Job details: who and where, the steps still to do, the linked reports, and a
/// pinned Complete job action. Report-level work stays in report details.
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
    final task = state.task;
    final actor = ref.watch(fcCurrentUserIdProvider);
    final isAssigned =
        task != null && actor != null && task.assignedCrewIds.contains(actor);
    final status = task?.status.toLowerCase() ?? '';
    final finished = {'completed', 'closed', 'cancelled'}.contains(status);
    final canAct = isAssigned && !{'completed', 'cancelled'}.contains(status);
    final investigation = task == null
        ? null
        : ref.watch(fcActiveInvestigationProvider(taskId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job details'),
        actions: [if (task != null) FcPendingSyncBadge(entityId: taskId)],
      ),
      body: _body(context, ref, state, notifier, investigation, isAssigned),
      bottomNavigationBar: task == null || investigation == null || !isAssigned
          ? null
          : ListenableBuilder(
              listenable: investigation,
              builder: (context, _) {
                final expected = taskReportIds(task).length;
                return FcCompleteJobBar(
                  finishedLabel: finished
                      ? switch (status) {
                          'cancelled' => 'Job cancelled',
                          'closed' => 'Job closed',
                          _ => 'Job completed',
                        }
                      : null,
                  blocker: !canAct
                      ? null
                      : jobCompletionBlocker(
                          session: investigation,
                          reports: state.reports,
                          expected: expected,
                          refreshing: state.isLoading,
                        ),
                  onComplete: () async {
                    final notes = await showCleanupNotesDialog(
                      context,
                      title: 'Complete job',
                      description:
                          'Summarize the work done. Photos and the on-site visit are checked again when the job is sent.',
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
                          'Job marked done on this phone. It will send when you have signal.',
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    FcTaskDetailState state,
    FcTaskDetailNotifier notifier,
    CrewInvestigationSession? investigation,
    bool isAssigned,
  ) {
    if (state.isLoading && state.task == null) {
      return const Align(
        alignment: Alignment.topCenter,
        child: LinearProgressIndicator(semanticsLabel: 'Loading the job'),
      );
    }
    if (state.errorMessage != null && state.task == null) {
      return AppStateView(
        title: 'Job could not load',
        message:
            'It may not be saved on this phone yet. Check your signal and try again.',
        icon: Icons.cloud_off,
        actionLabel: 'Reload job',
        onAction: notifier.refresh,
      );
    }
    final theme = Theme.of(context);
    final task = state.task!;
    final reports = state.reports;
    final expected = taskReportIds(task).length;
    final status = task.status.toLowerCase();
    final finished = {'completed', 'closed', 'cancelled'}.contains(status);
    final canAct = isAssigned && !{'completed', 'cancelled'}.contains(status);
    Future<void> openReport(ReportModel report) async {
      await context.push(
        '/field-crew/tasks/${Uri.encodeComponent(taskId)}/reports/${Uri.encodeComponent(report.id)}',
      );
      if (context.mounted) await notifier.refresh();
    }

    final top = <Widget>[
      if (state.isLoading)
        const LinearProgressIndicator(semanticsLabel: 'Refreshing the job'),
      const FcConflictSummary(),
      if (state.errorMessage != null)
        FcOfflineNotice(
          error: true,
          message: state.errorMessage!,
          action: TextButton(
            onPressed: state.isLoading ? null : notifier.refresh,
            child: const Text('Refresh job'),
          ),
        ),
      if (!isAssigned)
        FcOfflineNotice(
          message: task.assignedCrewIds.isEmpty
              ? 'View only. No crew is assigned to this job.'
              : 'View only. This job is assigned to other crew members.',
        ),
      FcJobHeaderCard(
        task: task,
        reports: reports,
        address: state.resolvedAddress,
        showDeadline: !finished,
      ),
      if (canAct && investigation != null)
        FcJobStepsCard(
          session: investigation,
          reports: reports,
          expected: expected,
          refreshing: state.isLoading,
          onOpenReport: openReport,
        ),
      Semantics(
        header: true,
        child: Text(
          'Reports in this job ($expected)',
          style: theme.textTheme.titleMedium,
        ),
      ),
      if (expected == 0)
        Text(
          'This job has no linked reports.',
          style: theme.textTheme.bodyMedium,
        ),
    ];
    return RefreshIndicator(
      onRefresh: notifier.refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            sliver: SliverList.separated(
              itemCount: top.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, index) => top[index],
            ),
          ),
          if (expected > 0)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: FcReportTable(
                reports: reports,
                taskId: taskId,
                onReturn: notifier.refresh,
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            sliver: SliverToBoxAdapter(
              child: FcCitizenPhotosSection(
                reports: reports,
                evidenceByReport: state.evidenceByReport,
                isLoading: state.isEvidenceLoading,
                error: state.evidenceError,
                onRetry: notifier.refreshEvidence,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
