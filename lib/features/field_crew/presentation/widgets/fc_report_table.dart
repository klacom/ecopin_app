import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import '../controllers/fc_task_detail_presentation.dart';
import '../controllers/fc_tasks_presentation.dart';
import 'fc_jobs_view_switch.dart';
import 'fc_report_card.dart';

/// Linked reports for a job, split into “To handle” and “Handled”. Reports to
/// handle list the earliest response deadline first; the deadline itself shows
/// on each card.
class FcReportTable extends StatefulWidget {
  const FcReportTable({
    super.key,
    required this.reports,
    required this.taskId,
    this.onReturn,
  });
  final List<ReportModel> reports;
  final String taskId;
  final Future<void> Function()? onReturn;
  @override
  State<FcReportTable> createState() => _FcReportTableState();
}

class _FcReportTableState extends State<FcReportTable> {
  CrewJobView _view = CrewJobView.todo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final open = reportsToHandle(widget.reports);
    final handled = widget.reports.where(reportIsHandled).toList();
    final visible = _view == CrewJobView.todo ? open : handled;
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FcJobsViewSwitch(
              view: _view,
              todoCount: open.length,
              doneCount: handled.length,
              leftLabel: 'To handle',
              rightLabel: 'Handled',
              noun: 'report',
              onChanged: (view) => setState(() => _view = view),
            ),
          ),
        ),
        if (visible.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                widget.reports.isEmpty
                    ? 'No reports in this view.'
                    : _view == CrewJobView.todo
                    ? 'No reports left to handle.'
                    : 'No reports handled yet.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
        SliverList.separated(
          itemCount: visible.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final report = visible[index];
            return FcReportCard(
              report: report,
              onTap: () async {
                await context.push(
                  '/field-crew/tasks/${Uri.encodeComponent(widget.taskId)}/reports/${Uri.encodeComponent(report.id)}',
                );
                if (context.mounted) await widget.onReturn?.call();
              },
            );
          },
        ),
      ],
    );
  }
}
