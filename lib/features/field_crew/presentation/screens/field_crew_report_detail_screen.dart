import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ecopin_app/features/field_crew/data/models/cleanup_task_model.dart';
import 'package:ecopin_app/features/field_crew/providers/cleanup_task_detail_provider.dart';
import 'package:ecopin_app/features/field_crew/providers/cleanup_tasks_provider.dart';
import 'package:ecopin_app/features/field_crew/providers/fc_report_detail_notifier.dart';
import 'package:ecopin_app/features/field_crew/providers/fc_report_photo_slots_provider.dart';
import 'package:ecopin_app/features/field_crew/providers/field_crew_reports_provider.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_trigger.dart';
import 'package:ecopin_app/routes/app_routes.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import 'package:ecopin_app/shared/widgets/app_state_view.dart';
import '../../location/crew_investigation_session.dart';
import '../../providers/fc_investigation_provider.dart';
import '../../providers/fc_task_detail_notifier.dart';
import '../controllers/fc_report_detail_presentation.dart';
import '../controllers/fc_task_detail_presentation.dart';
import '../widgets/cleanup_notes_dialog.dart';
import '../widgets/crew_urgency_form.dart';
import '../widgets/fc_activity_log.dart';
import '../widgets/fc_conflict_summary.dart';
import '../widgets/fc_lgu_notes_section.dart';
import '../widgets/fc_offline_ui.dart';
import '../widgets/fc_pending_sync_badge.dart';
import '../widgets/fc_photo_upload_section.dart';
import '../widgets/fc_report_action_bar.dart';
import '../widgets/fc_report_header_card.dart';
import '../widgets/fc_report_info_section.dart';
import '../widgets/fc_report_steps_card.dart';

/// Report details: where it is, the steps for this report (site visit, photos,
/// acknowledge, complete) and a pinned action for the next one.
class FieldCrewReportDetailScreen extends ConsumerWidget {
  final String reportId;
  final String? taskId;

  const FieldCrewReportDetailScreen({
    super.key,
    required this.reportId,
    this.taskId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(fcSyncStateProvider, (previous, next) {
      if (next.lastSyncAt != null && previous?.lastSyncAt != next.lastSyncAt) {
        ref.read(fcReportDetailNotifierProvider(reportId).notifier).refresh();
      }
    });
    final state = ref.watch(fcReportDetailNotifierProvider(reportId));
    final notifier = ref.read(
      fcReportDetailNotifierProvider(reportId).notifier,
    );
    final report = state.report;
    final taskAsync = taskId != null
        ? ref.watch(cleanupTaskDetailProvider(taskId!))
        : null;
    final task = taskAsync?.value;
    final userId = ref.watch(fcCurrentUserIdProvider);
    final isAssigned = task != null
        ? userId != null && task.assignedCrewIds.contains(userId)
        : userId != null;
    final session = taskId != null && isAssigned
        ? ref.watch(fcActiveInvestigationProvider(taskId!))
        : null;
    final slots = report == null
        ? const FcReportPhotoSlots()
        : ref.watch(fcReportPhotoSlotsProvider(reportId)).value ??
              FcReportPhotoSlots.fromReport(report);

    Future<void> upload(File file, String type) async {
      await ref
          .read(fieldCrewReportRepositoryProvider)
          .uploadReportPhoto(reportId, file, type);
      await notifier.refresh();
      ref.invalidate(fcReportPhotoSlotsProvider(reportId));
    }

    Future<void> delete(FcPhotoSlot slot, String type) async {
      await ref
          .read(fieldCrewReportRepositoryProvider)
          .deleteReportPhoto(
            reportId,
            type,
            photoId: slot.remoteId ?? slot.localPhotoId,
          );
      await notifier.refresh();
      ref.invalidate(fcReportPhotoSlotsProvider(reportId));
    }

    void say(String message) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    }

    Future<void> change(String newStatus) async {
      if (report == null) return;
      final lower = newStatus.toLowerCase();
      String? notes;
      if (const {'resolved', 'completed', 'closed'}.contains(lower)) {
        try {
          if (taskId == null) {
            throw StateError(
              'Open this report from its job before completing it.',
            );
          }
          ref.read(fcInvestigationProvider(taskId!)).requireIncident(reportId);
        } catch (error) {
          say(error is StateError ? error.message : 'Could not complete.');
          return;
        }
      }
      if (lower == 'resolved') {
        if (!crewReportIsScouting(report) &&
            (!slots.hasBefore || !slots.hasAfter)) {
          say('Before and After photos are needed before completing.');
          return;
        }
        if (!context.mounted) return;
        notes = await showCleanupNotesDialog(
          context,
          title: 'Complete report',
          description:
              'Describe the work done. Before and After photos and notes are checked when the report is sent.',
        );
        if (notes == null || !context.mounted) return;
      }
      if (newStatus == 'acknowledged') {
        await notifier.updateLifecycleStage('acknowledged');
      } else {
        await notifier.updateStatus(newStatus, notes: notes);
      }
      say('Saved on this phone. It will send when you have signal.');
    }

    final stage = report == null ? null : crewReportStage(report);
    final next = reportsToHandle(
      task?.reports ?? const <ReportModel>[],
    ).where((r) => r.id != reportId).firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report details'),
        actions: [if (report != null) FcPendingSyncBadge(entityId: reportId)],
      ),
      body: _body(
        context,
        ref,
        state: state,
        notifier: notifier,
        task: task,
        isAssigned: isAssigned,
        userId: userId,
        session: session,
        slots: slots,
        upload: upload,
        delete: delete,
      ),
      bottomNavigationBar: report == null || !isAssigned || stage == null
          ? null
          : ListenableBuilder(
              listenable: session ?? Listenable.merge(const []),
              builder: (context, _) => FcReportActionBar(
                stage: stage,
                hint: crewReportAcknowledgeHint(
                  scouting: crewReportIsScouting(report),
                  hasBefore: slots.hasBefore,
                ),
                blocker: reportCompletionBlocker(
                  report: report,
                  slots: slots,
                  session: session,
                ),
                onStatusChange: change,
                onOpenNext: taskId != null && next != null
                    ? () => context.pushReplacement(
                        '/field-crew/tasks/${Uri.encodeComponent(taskId!)}/reports/${Uri.encodeComponent(next.id)}',
                      )
                    : null,
                onBackToJob: taskId != null ? context.pop : null,
              ),
            ),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref, {
    required FcReportDetailState state,
    required FcReportDetailNotifier notifier,
    required CleanupTask? task,
    required bool isAssigned,
    required String? userId,
    required CrewInvestigationSession? session,
    required FcReportPhotoSlots slots,
    required Future<void> Function(File, String) upload,
    required Future<void> Function(FcPhotoSlot, String) delete,
  }) {
    if (state.isLoading && state.report == null) {
      return const Align(
        alignment: Alignment.topCenter,
        child: LinearProgressIndicator(semanticsLabel: 'Loading the report'),
      );
    }
    if (state.errorMessage != null && state.report == null) {
      return AppStateView(
        title: 'Report could not load',
        message:
            'It may not be saved on this phone yet. Check your signal and try again.',
        icon: Icons.cloud_off,
        actionLabel: 'Reload report',
        onAction: notifier.refresh,
      );
    }
    final report = state.report!;
    final rules = crewReportPhotoRules(report);
    final items = <Widget>[
      if (state.isLoading)
        const LinearProgressIndicator(semanticsLabel: 'Refreshing the report'),
      const FcConflictSummary(),
      if (state.errorMessage != null)
        FcOfflineNotice(
          error: true,
          message: state.errorMessage!,
          action: TextButton(
            onPressed: state.isLoading ? null : notifier.refresh,
            child: const Text('Refresh report'),
          ),
        ),
      if (taskId != null && task != null && !isAssigned)
        const FcOfflineNotice(
          message: 'View only. This job is assigned to other crew members.',
        ),
      FcReportHeaderCard(
        report: report,
        jobTitle: task?.title,
        onOpenJob: taskId != null ? context.pop : null,
        onShowOnMap: () => context.push(
          '${FieldCrewAppRoutes.map}?lat=${report.location.latitude}&lng=${report.location.longitude}',
        ),
      ),
      if (isAssigned)
        FcReportStepsCard(
          report: report,
          slots: slots,
          session: session,
          onUpload: upload,
          onDelete: delete,
        )
      else if (slots.before.isNotEmpty || slots.after.isNotEmpty)
        _ReadOnlyPhotos(slots: slots, rules: rules),
      if (isAssigned &&
          report.citizenPriority == 'urgent' &&
          task != null &&
          userId != null)
        CrewUrgencyForm(
          key: ValueKey(
            '$reportId:${task.id}:${task.assignmentGeneration}:${report.reportClaimGeneration}',
          ),
          canSubmit:
              report.cleanupTaskId == task.id &&
              const [
                'created',
                'pending',
                'assigned',
                'en_route',
                'in_progress',
                'partially_completed',
              ].contains(task.status) &&
              task.routeStatus == 'ready',
          onSave: (result, conditions) => notifier.addUrgencyObservation(
            taskId: task.id,
            observerId: userId,
            assignmentGeneration: task.assignmentGeneration,
            reportClaimGeneration: report.reportClaimGeneration,
            result: result,
            conditions: conditions,
          ),
        ),
      FcReportInfoSection(report: report),
      FcCitizenEvidenceSection(
        evidencePhotos: state.evidence,
        evidenceError: state.evidenceError,
      ),
      FcLguNotesSection(
        isAssigned: isAssigned,
        onSubmit: (note) async => notifier.addNote(note),
      ),
      FcActivityLog(responses: state.notes, currentUserId: userId),
    ];
    return RefreshIndicator(
      onRefresh: () async {
        await notifier.refresh();
        ref.invalidate(fcReportPhotoSlotsProvider(reportId));
      },
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, index) => items[index],
      ),
    );
  }
}

/// Photos for someone who is not assigned: viewable, never editable.
class _ReadOnlyPhotos extends StatelessWidget {
  const _ReadOnlyPhotos({required this.slots, required this.rules});
  final FcReportPhotoSlots slots;
  final ({bool before, bool after}) rules;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget group(String title, String type, List<FcPhotoSlot> photos) {
      if (photos.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title · ${photos.length} of ${FcPhotoStrip.maxPhotos}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          FcPhotoStrip(
            type: type,
            slots: photos,
            isAssigned: false,
            isEnabled: false,
            onUpload: (_, _) async {},
            onDelete: (_, _) async {},
          ),
        ],
      );
    }

    return FcOfflineCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text('Photos', style: theme.textTheme.titleMedium),
          ),
          const SizedBox(height: 12),
          group('Before photos', 'before', slots.before),
          if (slots.before.isNotEmpty && slots.after.isNotEmpty)
            const SizedBox(height: 16),
          group('After photos', 'after', slots.after),
        ],
      ),
    );
  }
}
