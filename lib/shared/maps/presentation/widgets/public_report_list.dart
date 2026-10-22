import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import 'package:ecopin_app/shared/reports/providers/public_report_map_provider.dart';
import 'package:ecopin_app/shared/reports/presentation/widgets/reports_screen_widgets/status_badge.dart';

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
    return RefreshIndicator(
      onRefresh: () => _load(refresh: true),
      child: ListView.builder(
        key: const PageStorageKey('citizen-public-report-list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          24 + MediaQuery.paddingOf(context).bottom,
        ),
        itemCount: _reports.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Public reports', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    'All areas · Newest first',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            );
          }
          if (index == _reports.length + 1) {
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
          final report = _reports[index - 1];
          final date = MaterialLocalizations.of(
            context,
          ).formatMediumDate(report.createdAt.toLocal());
          return Card(
            key: ValueKey(report.id),
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                color:
                    theme.dividerTheme.color ??
                    theme.colorScheme.outlineVariant,
              ),
            ),
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => widget.onOpen(report),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            report.title,
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        StatusBadge(status: report.status),
                        Text(
                          (report.issueType ?? 'Environmental concern')
                              .replaceAll('_', ' '),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    if (report.description?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 12),
                      Text(
                        report.description!,
                        maxLines: 2,
                        style: theme.textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text('Reported $date', style: theme.textTheme.bodySmall),
                    if (report.locationPrecision == 'approximate')
                      Text(
                        'Approximate public location',
                        style: theme.textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
