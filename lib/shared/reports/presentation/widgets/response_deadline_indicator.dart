import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import 'package:ecopin_app/shared/reports/presentation/response_deadline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final responseDeadlineClockProvider = StreamProvider.autoDispose<DateTime>((
  ref,
) async* {
  yield DateTime.now();
  yield* Stream.periodic(const Duration(seconds: 30), (_) => DateTime.now());
});

class ResponseDeadlineIndicator extends ConsumerWidget {
  const ResponseDeadlineIndicator({
    super.key,
    required this.report,
    this.details = false,
  });
  final ReportModel report;
  final bool details;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now =
        ref.watch(responseDeadlineClockProvider).value ?? DateTime.now();
    final deadline = responseDeadline(report, now);
    if (deadline == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final colors = theme.extension<AppStatusColors>();
    final color = switch (deadline.state) {
      DeadlineState.scheduled => theme.colorScheme.onSurfaceVariant,
      DeadlineState.atRisk => colors?.warning ?? theme.colorScheme.onSurface,
      DeadlineState.overdue => colors?.error ?? theme.colorScheme.error,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .08),
          border: Border.all(color: color.withValues(alpha: .35)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  deadline.state == DeadlineState.scheduled
                      ? Icons.schedule
                      : Icons.warning_amber_rounded,
                  size: 18,
                  color: color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${deadline.label} · ${deadline.timeLabel}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (details) ...[
              const SizedBox(height: 8),
              Text(
                'Target response: ${DateFormat.yMMMd().add_jm().format(deadline.deadlineAt.toLocal())}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Target time for response; cleanup completion may take longer.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
