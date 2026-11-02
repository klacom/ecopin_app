import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ecopin_app/features/field_crew/providers/fc_report_photo_slots_provider.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import '../../location/crew_investigation.dart';
import '../../location/crew_investigation_session.dart';
import '../controllers/fc_report_detail_presentation.dart';
import 'fc_job_steps_card.dart';
import 'fc_offline_ui.dart';
import 'fc_photo_upload_section.dart';

/// Time left at this report's pin, or null when it is not being timed.
Duration? crewReportSiteTimeLeft(
  CrewInvestigationSession? session,
  String reportId,
) {
  final gate = session?.gates[reportId];
  if (gate == null) return null;
  final left = CrewInvestigation.requiredDwell - gate.dwell;
  return left.isNegative ? Duration.zero : left;
}

/// The one thing still missing before “Complete report”, or null when the
/// existing rules are met. Shared by the steps card and the pinned bar.
String? reportCompletionBlocker({
  required ReportModel report,
  required FcReportPhotoSlots slots,
  required CrewInvestigationSession? session,
}) {
  if (crewReportStage(report) != CrewReportStage.inProgress) return null;
  return crewReportCompletionBlocker(
    scouting: crewReportIsScouting(report),
    hasBefore: slots.hasBefore,
    hasAfter: slots.hasAfter,
    siteRecorded: session?.canRecord(report.id) == true,
    hasJob: session != null,
    siteTimeLeft: crewReportSiteTimeLeft(session, report.id),
  );
}

/// “Your steps” for one report: site visit, Before photos, acknowledge, After
/// photos, complete. Photos live inside their own steps. The steps restate the
/// existing rules; they do not add any.
class FcReportStepsCard extends StatelessWidget {
  const FcReportStepsCard({
    super.key,
    required this.report,
    required this.slots,
    required this.session,
    required this.onUpload,
    required this.onDelete,
  });
  final ReportModel report;
  final FcReportPhotoSlots slots;

  /// Null when the report was opened outside a job: the site visit and
  /// completion need the job, so the card says so.
  final CrewInvestigationSession? session;
  final Future<void> Function(File file, String type) onUpload;
  final Future<void> Function(FcPhotoSlot slot, String type) onDelete;

  @override
  Widget build(BuildContext context) {
    final live = session;
    if (live == null) return _card(context);
    return ListenableBuilder(
      listenable: live,
      builder: (context, _) => _card(context),
    );
  }

  Widget _card(BuildContext context) {
    final theme = Theme.of(context);
    final stage = crewReportStage(report);
    final scouting = crewReportIsScouting(report);
    final rules = crewReportPhotoRules(report);
    final finished =
        stage == CrewReportStage.completed || stage == CrewReportStage.closed;
    final acknowledged = stage != CrewReportStage.toAcknowledge;
    final siteRecorded = session?.canRecord(report.id) == true;
    final blocker = reportCompletionBlocker(
      report: report,
      slots: slots,
      session: session,
    );
    final quiet = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    var number = 0;
    int next() => ++number;
    final steps = <Widget>[
      FcStepRow(
        number: next(),
        state: finished || siteRecorded ? FcStepState.done : FcStepState.open,
        title: 'Stay at the site for 5 minutes',
        child: session == null
            ? Text(
                'Open this report from its job to record the site visit.',
                style: theme.textTheme.bodySmall,
              )
            : finished
            ? const SizedBox.shrink()
            : FcSiteDetail(
                session: session!,
                done: siteRecorded,
                reportId: report.id,
              ),
      ),
      if (!scouting)
        FcStepRow(
          number: next(),
          state: slots.hasBefore && acknowledged
              ? FcStepState.done
              : FcStepState.open,
          title:
              'Take Before photos · ${slots.before.length} of ${FcPhotoStrip.maxPhotos}',
          child: _photos(
            context,
            'Before you start cleaning.',
            'before',
            slots.before,
            rules.before,
          ),
        ),
      FcStepRow(
        number: next(),
        state: acknowledged ? FcStepState.done : FcStepState.open,
        title: 'Acknowledge the report',
        child: Text(
          acknowledged
              ? 'Acknowledged.'
              : crewReportAcknowledgeHint(
                  scouting: scouting,
                  hasBefore: slots.hasBefore,
                ),
          style: quiet,
        ),
      ),
      if (!scouting)
        FcStepRow(
          number: next(),
          state: !acknowledged
              ? FcStepState.locked
              : slots.hasAfter
              ? FcStepState.done
              : FcStepState.open,
          title:
              'Take After photos · ${slots.after.length} of ${FcPhotoStrip.maxPhotos}',
          child: !acknowledged && slots.after.isEmpty
              ? Text('Opens after you acknowledge.', style: quiet)
              : _photos(
                  context,
                  'After you finish cleaning.',
                  'after',
                  slots.after,
                  rules.after,
                ),
        ),
      FcStepRow(
        number: next(),
        last: true,
        state: finished
            ? FcStepState.done
            : stage == CrewReportStage.inProgress && blocker == null
            ? FcStepState.open
            : FcStepState.locked,
        title: 'Complete the report',
        child: Text(
          finished
              ? 'Completed.'
              : stage == CrewReportStage.inProgress && blocker == null
              ? 'Add a short summary, then save with Complete report below.'
              : 'Opens after the steps above.',
          style: quiet,
        ),
      ),
    ];
    return FcOfflineCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text('Your steps', style: theme.textTheme.titleMedium),
          ),
          const SizedBox(height: 4),
          ...steps,
        ],
      ),
    );
  }

  Widget _photos(
    BuildContext context,
    String hint,
    String type,
    List<FcPhotoSlot> photos,
    bool enabled,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (photos.isNotEmpty || enabled) ...[
          const SizedBox(height: 8),
          FcPhotoStrip(
            type: type,
            slots: photos,
            isAssigned: true,
            isEnabled: enabled,
            onUpload: onUpload,
            onDelete: onDelete,
          ),
        ],
      ],
    );
  }
}
