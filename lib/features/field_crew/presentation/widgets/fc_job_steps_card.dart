import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import 'package:ecopin_app/shared/widgets/app_button.dart';
import '../../location/crew_investigation.dart';
import '../../location/crew_investigation_session.dart';
import '../controllers/fc_task_detail_presentation.dart';
import 'fc_offline_ui.dart';

/// Time left at the pin when exactly one incident is being timed; otherwise
/// null, and the copy asks for the visit at every incident instead.
Duration? crewSiteTimeLeft(CrewInvestigationSession session) {
  if (session.targets.length != 1) return null;
  final gate = session.gates[session.targets.first.id];
  if (gate == null) return null;
  final left = CrewInvestigation.requiredDwell - gate.dwell;
  return left.isNegative ? Duration.zero : left;
}

/// The existing completion rules, phrased as the one thing still missing.
/// Null means “Complete job” is available.
String? jobCompletionBlocker({
  required CrewInvestigationSession session,
  required List<ReportModel> reports,
  required int expected,
  required bool refreshing,
}) => crewCompletionBlocker(
  investigationComplete: session.canCompleteTask,
  refreshing: refreshing || reports.length > expected,
  missing: expected > reports.length ? expected - reports.length : 0,
  unhandled: reports.where((r) => !reportIsHandled(r)).length,
  siteTimeLeft: crewSiteTimeLeft(session),
);

/// State of one step: still to do, finished, or waiting on earlier steps.
enum FcStepState { open, done, locked }

/// “Your steps”: stay on site, handle each report, complete the job. Steps come
/// from the real investigation gate and report states, not from a separate flow.
class FcJobStepsCard extends StatelessWidget {
  const FcJobStepsCard({
    super.key,
    required this.session,
    required this.reports,
    required this.expected,
    required this.refreshing,
    required this.onOpenReport,
  });
  final CrewInvestigationSession session;
  final List<ReportModel> reports;
  final int expected;
  final bool refreshing;
  final ValueChanged<ReportModel> onOpenReport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final blocker = jobCompletionBlocker(
          session: session,
          reports: reports,
          expected: expected,
          refreshing: refreshing,
        );
        final missing = expected > reports.length
            ? expected - reports.length
            : 0;
        final unhandled = reports.where((r) => !reportIsHandled(r)).length;
        final handled = reports.length - unhandled;
        final siteDone = session.canCompleteTask;
        final reportsDone = expected > 0 && missing == 0 && unhandled == 0;
        final next = nextReportToHandle(reports);
        final steps = <Widget>[
          FcStepRow(
            state: siteDone ? FcStepState.done : FcStepState.open,
            number: 1,
            title: 'Stay at the site for 5 minutes',
            child: FcSiteDetail(session: session, done: siteDone),
          ),
          if (expected > 0)
            FcStepRow(
              state: reportsDone ? FcStepState.done : FcStepState.open,
              number: 2,
              title: 'Handle each report',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$handled of $expected done',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (missing > 0)
                    Text(
                      '$missing linked ${missing == 1 ? 'report' : 'reports'} could not be loaded. Refresh the job.',
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          FcStepRow(
            state: blocker == null ? FcStepState.open : FcStepState.locked,
            number: expected > 0 ? 3 : 2,
            title: 'Complete the job',
            last: true,
            child: Text(
              blocker == null
                  ? 'Add a short summary, then save with Complete job below.'
                  : 'Opens after the steps above.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
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
              if (next != null) ...[
                const SizedBox(height: 12),
                AppButton(
                  text: 'Open next report',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () => onOpenReport(next),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class FcStepRow extends StatelessWidget {
  const FcStepRow({
    super.key,
    required this.state,
    required this.number,
    required this.title,
    required this.child,
    this.last = false,
  });
  final FcStepState state;
  final int number;
  final String title;
  final Widget child;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = theme.extension<AppStatusColors>();
    final (Color tone, Widget mark, String word) = switch (state) {
      FcStepState.done => (
        status?.success ?? theme.colorScheme.onSurface,
        const Icon(Icons.check, size: 18),
        'done',
      ),
      FcStepState.locked => (
        theme.colorScheme.onSurfaceVariant,
        const Icon(Icons.lock_outline, size: 16),
        'locked',
      ),
      FcStepState.open => (
        fcAccent(context),
        Text(
          '$number',
          style: theme.textTheme.bodySmall?.copyWith(
            color: fcAccent(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        'to do',
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(
                bottom: BorderSide(
                  color: theme.dividerTheme.color ?? theme.dividerColor,
                ),
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            label: 'Step $number, $word',
            excludeSemantics: true,
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tone.withValues(alpha: .12),
                shape: BoxShape.circle,
              ),
              child: IconTheme(
                data: IconThemeData(color: tone),
                child: mark,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Step 1 detail, from the same gates the completion rule uses. GPS comes from
/// this phone; the copy never calls it proof of presence.
class FcSiteDetail extends StatelessWidget {
  const FcSiteDetail({
    super.key,
    required this.session,
    required this.done,
    this.reportId,
  });
  final CrewInvestigationSession session;
  final bool done;

  /// Limits the detail to one incident (report details); null lists them all.
  final String? reportId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quiet = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    if (done) {
      return Text('Site visit recorded on this phone.', style: quiet);
    }
    final targets = session.targets
        .where((t) => reportId == null || t.id == reportId)
        .toList();
    final many = targets.length > 1;
    final rows = <Widget>[];
    if (many) {
      final recorded = targets
          .where((t) => session.gates[t.id]?.complete == true)
          .length;
      rows.add(
        Text(
          '$recorded of ${targets.length} incidents recorded',
          style: theme.textTheme.bodySmall,
        ),
      );
    }
    double? accuracy;
    for (final target in targets) {
      final gate = session.gates[target.id];
      accuracy ??= gate?.accuracyMetres;
      if (gate == null) {
        rows.add(
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              many
                  ? '${target.label}: no pin. Refresh the job or ask your officer to correct it.'
                  : 'No pin for this incident. Refresh the job or ask your officer to correct it.',
              style: theme.textTheme.bodySmall,
            ),
          ),
        );
        continue;
      }
      final headline = gate.complete
          ? 'Site visit recorded on this phone.'
          : gate.inside
          ? 'You are at the site. Do not leave.'
          : gate.distanceMetres != null
          ? 'Go to the pin. ${gate.distanceMetres!.toStringAsFixed(0)} m away.'
          : gate.message;
      // Several incidents: one short line each, and a timer only for the one
      // being timed. One incident: its full timer.
      final timed = !gate.complete && (!many || gate.inside);
      rows.add(
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (many)
                Text(
                  target.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              Text(
                many && gate.inside && !gate.complete
                    ? '$headline ${crewClock(gate.dwell)} of ${crewClock(CrewInvestigation.requiredDwell)}'
                    : headline,
                style: theme.textTheme.bodySmall,
              ),
              if (timed && !many) ...[
                const SizedBox(height: 8),
                _DwellBar(gate: gate, label: target.label),
                const SizedBox(height: 4),
                Text(
                  '${crewClock(gate.dwell)} of ${crewClock(CrewInvestigation.requiredDwell)}',
                  style: quiet,
                ),
              ] else if (timed) ...[
                const SizedBox(height: 8),
                _DwellBar(gate: gate, label: target.label),
              ],
            ],
          ),
        ),
      );
    }
    if (accuracy != null) {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'GPS accuracy ±${accuracy.toStringAsFixed(1)} m. Keep EcoPin open.',
            style: quiet,
          ),
        ),
      );
    }
    if (targets.isEmpty) {
      rows.add(
        Text(
          'Waiting for the job to load. Refresh if this stays.',
          style: theme.textTheme.bodySmall,
        ),
      );
    }
    if (session.error != null) {
      rows.addAll([
        const SizedBox(height: 8),
        Text(session.error!, style: theme.textTheme.bodySmall),
        TextButton.icon(
          onPressed: session.retry,
          icon: const Icon(Icons.my_location),
          label: const Text('Retry precise location'),
        ),
        Wrap(
          children: [
            TextButton(
              onPressed: Geolocator.openLocationSettings,
              child: const Text('GPS settings'),
            ),
            TextButton(
              onPressed: Geolocator.openAppSettings,
              child: const Text('Permission settings'),
            ),
          ],
        ),
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }
}

class _DwellBar extends StatelessWidget {
  const _DwellBar({required this.gate, required this.label});
  final CrewInvestigation gate;
  final String label;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(999),
    child: LinearProgressIndicator(
      value:
          (gate.dwell.inMilliseconds /
                  CrewInvestigation.requiredDwell.inMilliseconds)
              .clamp(0.0, 1.0),
      minHeight: 8,
      color: fcAccent(context),
      backgroundColor: fcAccent(context).withValues(alpha: .2),
      semanticsLabel: 'Time at $label',
    ),
  );
}
