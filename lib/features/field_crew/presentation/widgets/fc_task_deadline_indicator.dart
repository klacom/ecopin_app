import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import 'package:ecopin_app/shared/reports/presentation/response_deadline.dart';
import 'package:ecopin_app/shared/reports/presentation/widgets/response_deadline_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FcTaskDeadlineIndicator extends ConsumerWidget {
  const FcTaskDeadlineIndicator({super.key, required this.reports});
  final List<ReportModel> reports;

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
