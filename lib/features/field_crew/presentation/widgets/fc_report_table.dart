import 'package:ecopin_app/shared/reports/presentation/widgets/response_deadline_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/shared/reports/presentation/response_deadline.dart';
import 'package:go_router/go_router.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import '../controllers/fc_dashboard_presentation.dart';
import '../controllers/fc_task_detail_presentation.dart';

class FcReportTable extends ConsumerStatefulWidget {
  const FcReportTable({
    super.key,
    required this.reports,
    required this.taskId,
    this.onOutcome,
    this.onReturn,
  });
  final List<ReportModel> reports;
  final String taskId;
  final Future<void> Function()? onReturn;
  final void Function(ReportModel, String)? onOutcome;
  @override
  ConsumerState<FcReportTable> createState() => _FcReportTableState();
}

class _FcReportTableState extends ConsumerState<FcReportTable> {
  String _filter = 'All';
  @override
  Widget build(BuildContext context) {
    final now =
        ref.watch(responseDeadlineClockProvider).value ?? DateTime.now();
    bool matches(ReportModel report, String filter) => switch (filter) {
      'Open' => !reportIsHandled(report),
      'Handled' => reportIsHandled(report),
      'At risk' => responseDeadline(report, now)?.state == DeadlineState.atRisk,
      'Overdue' =>
        responseDeadline(report, now)?.state == DeadlineState.overdue,
      _ => true,
    };
    final visible = widget.reports
        .where((report) => matches(report, _filter))
        .toList();
    final text = Theme.of(context).textTheme;
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final label in [
                  'All',
                  'Open',
                  'Handled',
                  'At risk',
                  'Overdue',
                ])
                  FilterChip(
                    selected: _filter == label,
                    onSelected: (_) => setState(() => _filter = label),
                    label: Text(
                      '$label (${widget.reports.where((report) => matches(report, label)).length})',
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (visible.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('No reports in this view.'),
            ),
          ),
        SliverList.builder(
          itemCount: visible.length,
          itemBuilder: (context, index) {
            final report = visible[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                margin: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () async {
                    await context.push(
                      '/field-crew/tasks/${Uri.encodeComponent(widget.taskId)}/reports/${Uri.encodeComponent(report.id)}',
                    );
                    if (context.mounted) await widget.onReturn?.call();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                report.title,
                                style: text.titleMedium,
                              ),
                            ),
                            if (widget.onOutcome != null &&
                                !reportIsHandled(report))
                              PopupMenuButton<String>(
                                tooltip: 'Actions for ${report.title}',
                                onSelected: (value) =>
                                    widget.onOutcome!(report, value),
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'already_resolved',
                                    child: Text('Already clear on arrival'),
                                  ),
                                ],
                              )
                            else
                              const Icon(Icons.chevron_right),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 6,
                          children: [
                            Text(
                              crewTaskLabel(report.status),
                              style: text.labelMedium,
                            ),
                            Text(
                              report.issueType ?? 'General concern',
                              style: text.bodySmall,
                            ),
                            Text(
                              crewTaskLabel(report.validationStatus),
                              style: text.bodySmall,
                            ),
                          ],
                        ),
                        ResponseDeadlineIndicator(report: report),
                        if (report.description?.trim().isNotEmpty == true) ...[
                          const SizedBox(height: 8),
                          Text(
                            report.description!,
                            style: text.bodyMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 12),
                        Text(
                          'Open report',
                          style: text.labelLarge?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
