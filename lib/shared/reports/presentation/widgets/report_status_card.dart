import 'package:ecopin_app/shared/reports/presentation/widgets/report_priority_badge.dart';
import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import 'package:ecopin_app/shared/reports/presentation/response_deadline.dart';
import 'package:ecopin_app/shared/reports/presentation/widgets/report_status_presentation.dart';
import 'package:ecopin_app/shared/reports/presentation/widgets/reports_screen_widgets/status_badge.dart';
import 'package:ecopin_app/shared/reports/presentation/widgets/reports_screen_widgets/validation_badge.dart';
import 'package:ecopin_app/shared/reports/presentation/widgets/response_deadline_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _Stage { done, current, upcoming }

/// The first thing on Report details: the current badge, one plain sentence
/// about what it means, and a four-step tracker (Sent, Checked, Handled,
/// Cleaned). Only states the data supports are claimed; no dates are invented.
class ReportStatusCard extends ConsumerWidget {
  const ReportStatusCard({
    super.key,
    required this.report,
    this.isOwner = true,
  });
  final ReportModel report;
  final bool isOwner;

  static const _completedStatuses = [
    'resolved',
    'waiting_for_feedback',
    'closed',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = theme.extension<AppStatusColors>();
    final now =
        ref.watch(responseDeadlineClockProvider).value ?? DateTime.now();
    final key = reportStatusKey(report.status);
    final validation = report.validationStatus.toLowerCase();
    final rejected = key == 'rejected' || validation == 'rejected';
    final approved = const ['approved', 'validated'].contains(validation);
    final completed = _completedStatuses.contains(key);
    final deadline = rejected || completed
        ? null
        : responseDeadline(report, now);

    final Color tone;
    final IconData icon;
    final String sentence;
    if (rejected) {
      tone = colors?.error ?? scheme.error;
      icon = Icons.block_outlined;
      sentence = 'This report was not accepted. The review note is below.';
    } else if (!approved) {
      tone = scheme.onSurfaceVariant;
      icon = Icons.hourglass_empty;
      sentence = 'Your report is being checked before SWMO handles it.';
    } else if (completed) {
      tone = colors?.success ?? scheme.primary;
      icon = Icons.check_circle_outline;
      sentence = switch (key) {
        'closed' =>
          report.satisfactionRating != null
              ? 'Cleaned up. Thanks for your rating.'
              : 'Cleaned up and closed.',
        'waiting_for_feedback' =>
          isOwner
              ? 'Cleaned up. SWMO is waiting for your feedback.'
              : 'Cleaned up.',
        _ =>
          isOwner
              ? 'Cleaned up. Rate the service to close this report.'
              : 'Cleaned up.',
      };
    } else {
      tone = reportStatusColor(context, report.status);
      icon = key == 'unresolved' || key == 'pending' || key == 'submitted'
          ? Icons.schedule
          : Icons.handyman_outlined;
      final base = switch (key) {
        'in_progress' || 'acknowledged' => 'SWMO is handling this report.',
        'pending_owner_consent' =>
          'SWMO needs the property owner’s consent before crews can enter.',
        _ => 'Your report is with SWMO and waiting to be handled.',
      };
      sentence = base;
    }

    String? targetLine;
    var targetColor = scheme.onSurfaceVariant;
    if (deadline != null) {
      final amount = deadline.timeLabel
          .replaceAll(' overdue', '')
          .replaceAll(' left', '');
      switch (deadline.state) {
        case DeadlineState.overdue:
          targetLine = 'Response is overdue by $amount.';
          targetColor = colors?.error ?? scheme.error;
        case DeadlineState.atRisk:
          targetLine = 'Response target: $amount left.';
          targetColor = colors?.warning ?? scheme.onSurface;
        case DeadlineState.scheduled:
          targetLine = 'Response target: $amount left.';
      }
    }

    final badge = rejected || !approved
        ? Semantics(
            label: 'Report check',
            child: ValidationBadge(status: report.validationStatus),
          )
        : Semantics(
            label: 'Response',
            child: StatusBadge(status: report.status),
          );

    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.dividerTheme.color ?? scheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: tone.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ExcludeSemantics(
                    child: Icon(icon, color: tone, size: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          badge,
                          ReportPriorityBadge(priority: report.citizenPriority),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(sentence, style: theme.textTheme.bodyMedium),
                      if (targetLine != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          targetLine,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: targetColor,
                            fontWeight: deadline?.state == DeadlineState.overdue
                                ? FontWeight.w500
                                : null,
                          ),
                        ),
                        Text(
                          'A response target, not a guaranteed cleanup time.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (!rejected) ...[
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),
              _Tracker(
                stages: _stages(approved: approved, completed: completed),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Sent is always done; the first step not yet done is the current one.
  List<(String, _Stage)> _stages({
    required bool approved,
    required bool completed,
  }) {
    final done = [true, approved, completed, completed];
    const names = ['Sent', 'Checked', 'Handled', 'Cleaned'];
    final firstOpen = done.indexOf(false);
    return [
      for (var i = 0; i < 4; i++)
        (
          names[i],
          done[i]
              ? _Stage.done
              : i == firstOpen
              ? _Stage.current
              : _Stage.upcoming,
        ),
    ];
  }
}

class _Tracker extends StatelessWidget {
  const _Tracker({required this.stages});
  final List<(String, _Stage)> stages;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final done = theme.extension<AppStatusColors>()?.success ?? scheme.primary;
    final track = scheme.onSurface.withValues(alpha: .14);
    final summary = [
      for (final (name, stage) in stages)
        '$name, ${switch (stage) {
          _Stage.done => 'done',
          _Stage.current => 'current step',
          _Stage.upcoming => 'not yet',
        }}',
    ].join('. ');
    return Semantics(
      label: 'Progress. $summary',
      excludeSemantics: true,
      child: Row(
        children: [
          for (var i = 0; i < stages.length; i++)
            Expanded(
              child: Column(
                children: [
                  SizedBox(
                    height: 16,
                    child: Row(
                      children: [
                        Expanded(
                          child: i == 0
                              ? const SizedBox()
                              : Container(
                                  height: 2,
                                  color: stages[i].$2 == _Stage.upcoming
                                      ? track
                                      : done,
                                ),
                        ),
                        _Dot(stage: stages[i].$2, done: done, track: track),
                        Expanded(
                          child: i == stages.length - 1
                              ? const SizedBox()
                              : Container(
                                  height: 2,
                                  color: stages[i + 1].$2 == _Stage.upcoming
                                      ? track
                                      : done,
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    stages[i].$1,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: stages[i].$2 == _Stage.current
                          ? scheme.primary
                          : stages[i].$2 == _Stage.done
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant,
                      fontWeight: stages[i].$2 == _Stage.current
                          ? FontWeight.w500
                          : null,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.stage, required this.done, required this.track});
  final _Stage stage;
  final Color done, track;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return switch (stage) {
      _Stage.done => Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(color: done, shape: BoxShape.circle),
        child: const Icon(Icons.check, size: 11, color: Colors.white),
      ),
      _Stage.current => Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: scheme.surface,
          shape: BoxShape.circle,
          border: Border.all(color: scheme.primary, width: 3),
        ),
      ),
      _Stage.upcoming => Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(color: track, shape: BoxShape.circle),
      ),
    };
  }
}
