import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import 'package:ecopin_app/shared/reports/presentation/response_deadline.dart';
import 'package:ecopin_app/shared/reports/presentation/widgets/response_deadline_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FcTaskDeadlineIndicator extends ConsumerWidget {
  const FcTaskDeadlineIndicator({
    super.key,
    required this.reports,
    this.inline = false,
  });
  final List<ReportModel> reports;

  /// One written line for a job card instead of the full indicator.
  final bool inline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now =
        ref.watch(responseDeadlineClockProvider).value ?? DateTime.now();
    final active =
        reports
            .where((report) => responseDeadline(report, now) != null)
            .toList()
          ..sort((a, b) => a.deadlineAt!.compareTo(b.deadlineAt!));
    if (active.isEmpty) return const SizedBox.shrink();
    if (inline) {
      final first = responseDeadline(active.first, now)!;
      final theme = Theme.of(context);
      final colors = theme.extension<AppStatusColors>();
      final color = switch (first.state) {
        DeadlineState.scheduled => theme.colorScheme.onSurfaceVariant,
        DeadlineState.atRisk => colors?.warning ?? theme.colorScheme.onSurface,
        DeadlineState.overdue => colors?.error ?? theme.colorScheme.error,
      };
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Icon(Icons.alarm_outlined, size: 18, color: color),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '${first.label} · ${first.timeLabel}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }
    final atRisk = active
        .where(
          (report) =>
              responseDeadline(report, now)!.state == DeadlineState.atRisk,
        )
        .length;
    final overdue = active
        .where(
          (report) =>
              responseDeadline(report, now)!.state == DeadlineState.overdue,
        )
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Earliest linked report deadline',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        ResponseDeadlineIndicator(report: active.first),
        if (atRisk + overdue > 0)
          Text(
            '$atRisk approaching · $overdue overdue',
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }
}
