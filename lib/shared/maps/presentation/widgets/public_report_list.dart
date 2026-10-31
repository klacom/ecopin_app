import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/shared/reports/presentation/response_deadline.dart';
import 'package:ecopin_app/shared/reports/presentation/widgets/report_row.dart';
import 'package:ecopin_app/shared/reports/presentation/widgets/report_status_presentation.dart';
import 'package:ecopin_app/shared/reports/presentation/widgets/response_deadline_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import 'package:ecopin_app/shared/reports/providers/public_report_map_provider.dart';

class PublicReportList extends ConsumerStatefulWidget {
  const PublicReportList({super.key, required this.onOpen});
  final ValueChanged<ReportModel> onOpen;

  @override
  ConsumerState<PublicReportList> createState() => _PublicReportListState();
}

class _PublicReportListState extends ConsumerState<PublicReportList> {
  List<ReportModel> _reports = [];
  bool _loading = false, _hasMore = false, _failed = false;
  int _offset = 0;
  bool _retryRefresh = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool refresh = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _failed = false;
      _retryRefresh = refresh;
    });
    try {
      final offset = refresh ? 0 : _offset;
      final page = await ref
          .read(publicReportMapDataSourceProvider)
          .getFeedPage(offset: offset);
      if (!mounted) return;
      setState(() {
        final previous = refresh ? <ReportModel>[] : _reports;
        final byId = {for (final report in previous) report.id: report};
        for (final report in page.reports) {
          byId[report.id] = report;
        }
        _reports = byId.values.toList();
        _offset = offset + page.reports.length;
        _hasMore = page.hasMore;
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now =
        ref.watch(responseDeadlineClockProvider).value ?? DateTime.now();
    final entries = groupReportsByRecency<ReportModel>(
      _reports,
      (report) => report.createdAt,
      now,
    );
    return RefreshIndicator(
      onRefresh: () => _load(refresh: true),
      child: ListView.builder(
        key: const PageStorageKey('citizen-public-report-list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          4,
          8,
          4,
          24 + MediaQuery.paddingOf(context).bottom,
        ),
        itemCount: entries.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
              child: Text(
                'All areas, newest first',
                style: theme.textTheme.bodySmall,
              ),
            );
          }
          if (index == entries.length + 1) {
            return Column(
              children: [
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(
                      semanticsLabel: 'Loading public reports',
                    ),
                  ),
                if (_failed) ...[
                  const Text(
                    'Public reports could not refresh. Please try again.',
                    textAlign: TextAlign.center,
                  ),
                  TextButton(
                    onPressed: () => _load(refresh: _retryRefresh),
                    child: const Text('Try again'),
                  ),
                ],
                if (!_loading && !_failed && _reports.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No public reports available yet.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (!_loading && !_failed && _hasMore)
                  OutlinedButton(
                    onPressed: _load,
                    child: const Text('Load more reports'),
                  ),
              ],
            );
          }
          final entry = entries[index - 1];
          if (entry is String) {
            return ReportGroupHeader(label: entry, first: index == 1);
          }
          final report = entry as ReportModel;
          return _publicRow(context, report, now);
        },
      ),
    );
  }

  Widget _publicRow(BuildContext context, ReportModel report, DateTime now) {
    final theme = Theme.of(context);
    final statusColor = reportStatusColor(context, report.status);
    final deadline = responseDeadline(report, now);
    final statusColors = theme.extension<AppStatusColors>();
    final lineColor = switch (deadline?.state) {
      DeadlineState.overdue => statusColors?.error ?? theme.colorScheme.error,
      DeadlineState.atRisk =>
        statusColors?.warning ?? theme.colorScheme.onSurface,
      _ => statusColor,
    };
    final date = DateFormat.MMMd().format(report.createdAt.toLocal());
    final status = reportStatusLabel(report.status);
    final description = report.description?.trim() ?? '';
    final concern = (report.issueType ?? 'Environmental concern').replaceAll(
      '_',
      ' ',
    );
    return ReportRow(
      key: ValueKey(report.id),
      title: report.title,
      icon: reportConcernIcon(report.issueType),
      tone: statusColor,
      pip: lineColor,
      lines: [
        ReportRowLine(
          deadline == null
              ? '$status, reported $date'
              : '$status, ${deadline.timeLabel}',
          color: lineColor,
          emphasis: deadline != null,
        ),
        if (description.isNotEmpty) ReportRowLine(description, maxLines: 1),
      ],
      semanticLabel: [
        report.title,
        status,
        if (deadline != null) '${deadline.label}, ${deadline.timeLabel}',
        '$concern concern',
        'Reported $date',
        if (report.locationPrecision == 'approximate')
          'Approximate public location',
      ].join('. '),
      onTap: () => widget.onOpen(report),
    );
  }
}
