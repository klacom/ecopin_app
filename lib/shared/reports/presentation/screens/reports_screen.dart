import 'package:ecopin_app/shared/reports/presentation/widgets/response_deadline_indicator.dart';
import 'dart:math' as math;
import 'package:ecopin_app/core/constants/app_constants.dart';
import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import 'package:ecopin_app/shared/reports/presentation/widgets/reports_screen_widgets/status_badge.dart';
import 'package:ecopin_app/shared/reports/presentation/widgets/reports_screen_widgets/validation_badge.dart';
import 'package:ecopin_app/shared/reports/providers/report_provider.dart';
import 'package:ecopin_app/routes/app_routes.dart';
import 'package:ecopin_app/shared/screens/no_internet_screen.dart';
import 'package:ecopin_app/shared/widgets/app_state_view.dart';
import 'package:ecopin_app/shared/widgets/private_media_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});
  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  final _search = TextEditingController();
  String _query = '';
  String _selectedFilter = 'All';
  int _displayLimit = 20;
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  // Preserve the existing 24-hour visibility rule for rejected reports.
  bool _isReportVisible(ReportModel report) =>
      report.validationStatus.toLowerCase() != 'rejected' ||
      report.rejectedAt == null ||
      DateTime.now().difference(report.rejectedAt!).inHours < 24;
  void _resetFilters() {
    _search.clear();
    setState(() {
      _query = '';
      _selectedFilter = 'All';
      _displayLimit = 20;
    });
  }

  Future<void> _refresh() async {
    ref.invalidate(myReportsProvider);
    try {
      await ref.read(myReportsProvider.future);
    } catch (_) {
      /* The provider exposes the failure below. */
    }
  }

  Future<void> _showFilters() async {
    FocusScope.of(context).unfocus();
    var draft = _selectedFilter;
    final selected = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, updateSheet) => ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * .8,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Filter reports',
                        style: Theme.of(sheetContext).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close filters',
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Report status'),
                RadioGroup<String>(
                  groupValue: draft,
                  onChanged: (value) {
                    if (value != null) updateSheet(() => draft = value);
                  },
                  child: Column(
                    children: [
                      for (final filter in reportFilters)
                        RadioListTile<String>(
                          value: filter,
                          title: Text(reportStatusLabels[filter] ?? filter),
                          contentPadding: EdgeInsets.zero,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.pop(sheetContext, draft),
                  child: const Text('Apply filters'),
                ),
                TextButton(
                  onPressed: () => updateSheet(() => draft = 'All'),
                  child: const Text('Reset status'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (mounted && selected != null) {
      setState(() {
        _selectedFilter = selected;
        _displayLimit = 20;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(myReportsProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reports'),
        actions: [
          IconButton(
            tooltip: 'Filter reports',
            onPressed: _showFilters,
            icon: Badge(
              isLabelVisible: _selectedFilter != 'All',
              label: const Text('1'),
              child: const Icon(Icons.filter_list),
            ),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: TextField(
                controller: _search,
                textInputAction: TextInputAction.search,
                onChanged: (value) => setState(() {
                  _query = value.toLowerCase().trim();
                  _displayLimit = 20;
                }),
                decoration: InputDecoration(
                  labelText: 'Search my reports',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _search.clear();
                            setState(() {
                              _query = '';
                              _displayLimit = 20;
                            });
                          },
                        ),
                ),
              ),
            ),
            if (reportsAsync.isLoading && reportsAsync.hasValue)
              const LinearProgressIndicator(
                semanticsLabel: 'Refreshing your reports',
              ),
            if (reportsAsync.hasError && reportsAsync.hasValue)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Reports could not refresh. Previous results are still shown.',
                    ),
                    TextButton(
                      onPressed: () => ref.invalidate(myReportsProvider),
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: reportsAsync.when(
                skipError: true,
                data: (reports) {
                  final filtered = reports.where(_isReportVisible).where((
                    report,
                  ) {
                    final stateMatches =
                        _selectedFilter == 'All' ||
                        (_selectedFilter == 'rejected'
                            ? report.validationStatus.toLowerCase() ==
                                  'rejected'
                            : report.status.toLowerCase() == _selectedFilter);
                    final text =
                        '${report.title} ${report.description ?? ''} ${report.issueType ?? ''}'
                            .toLowerCase();
                    return stateMatches &&
                        (_query.isEmpty ||
                            _query.split(RegExp(r'\s+')).every(text.contains));
                  }).toList();
                  final visible = math.min(_displayLimit, filtered.length);
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        16,
                        4,
                        16,
                        16 + MediaQuery.paddingOf(context).bottom,
                      ),
                      itemCount: filtered.isEmpty
                          ? 1
                          : visible + 1 + (visible < filtered.length ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (filtered.isEmpty) {
                          return AppStateView(
                            title: _query.isNotEmpty || _selectedFilter != 'All'
                                ? 'No matching reports'
                                : 'No reports yet',
                            message:
                                _query.isNotEmpty || _selectedFilter != 'All'
                                ? 'Try another search or clear your filters.'
                                : 'Start from the map to choose a location and report a concern.',
                            icon: Icons.description_outlined,
                            actionLabel:
                                _query.isNotEmpty || _selectedFilter != 'All'
                                ? 'Clear filters'
                                : 'Open the map',
                            onAction:
                                _query.isNotEmpty || _selectedFilter != 'All'
                                ? _resetFilters
                                : () => context.go(ProtectedAppRoutes.maps),
                          );
                        }
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Semantics(
                              liveRegion: true,
                              child: Text(
                                'Showing $visible of ${filtered.length} matching reports',
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          );
                        }
                        if (index > visible) {
                          return TextButton(
                            onPressed: () =>
                                setState(() => _displayLimit += 20),
                            child: const Text('Show more reports'),
                          );
                        }
                        return _ReportListItem(report: filtered[index - 1]);
                      },
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    semanticsLabel: 'Loading your reports',
                  ),
                ),
                error: (error, stack) => NoInternetScreen(
                  onRetry: () => ref.invalidate(myReportsProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportListItem extends StatelessWidget {
  const _ReportListItem({required this.report});
  final ReportModel report;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final photo = report.beforePhotoUrl ?? report.afterPhotoUrl;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: theme.dividerTheme.color ?? theme.colorScheme.outlineVariant,
        ),
      ),
      child: InkWell(
        onTap: () => context.push('${ProtectedAppRoutes.reports}/${report.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (photo != null) ...[
                    Semantics(
                      image: true,
                      label: 'Cleanup evidence photo',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: PrivateMediaImage(
                          photo,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) =>
                              const SizedBox(
                                width: 64,
                                height: 64,
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  semanticLabel: 'Photo unavailable',
                                ),
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(report.title, style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        Text(
                          '${report.issueType?.replaceAll('_', ' ') ?? 'Environmental concern'} · ${DateFormat('MMM d, yyyy').format(report.createdAt.toLocal())}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, size: 20),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('Response:', style: theme.textTheme.bodySmall),
                  StatusBadge(status: report.status),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('Review:', style: theme.textTheme.bodySmall),
                  ValidationBadge(status: report.validationStatus),
                ],
              ),
              ResponseDeadlineIndicator(report: report),
              if (report.validationStatus.toLowerCase() == 'rejected' &&
                  report.rejectionReason != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Review note: ${report.rejectionReason}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.extension<AppStatusColors>()?.error,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
