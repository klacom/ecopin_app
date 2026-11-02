import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ecopin_app/features/field_crew/presentation/controllers/fc_dashboard_presentation.dart';
import 'package:ecopin_app/features/field_crew/presentation/controllers/fc_reports_presentation.dart';
import 'package:ecopin_app/features/field_crew/presentation/controllers/fc_tasks_presentation.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_jobs_view_switch.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_offline_ui.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_report_card.dart';
import 'package:ecopin_app/features/field_crew/presentation/widgets/fc_report_type_sheet.dart';
import 'package:ecopin_app/features/field_crew/providers/cleanup_tasks_provider.dart';
import 'package:ecopin_app/features/field_crew/providers/field_crew_reports_provider.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import 'package:ecopin_app/shared/reports/presentation/widgets/response_deadline_indicator.dart';
import 'package:ecopin_app/shared/widgets/app_button.dart';
import 'package:ecopin_app/shared/widgets/app_state_view.dart';

/// Reports tab: every report in the crew's jobs, split into To handle and
/// Handled, in the same shape as the Jobs tab.
class FieldCrewReportsScreen extends ConsumerStatefulWidget {
  const FieldCrewReportsScreen({super.key});

  @override
  ConsumerState<FieldCrewReportsScreen> createState() =>
      _FieldCrewReportsScreenState();
}

class _FieldCrewReportsScreenState
    extends ConsumerState<FieldCrewReportsScreen> {
  /// Search only appears once the list is long enough to need it.
  static const _searchFrom = 6;
  final _search = TextEditingController();
  CrewJobView _view = CrewJobView.todo;
  String _query = '';
  CrewDeadlineFilter _deadline = CrewDeadlineFilter.all;
  String? _type;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(fieldCrewReportsProvider);
    ref.invalidate(allCleanupTasksProvider);
    await ref
        .read(assignedReportsProvider.future)
        .then<void>((_) {}, onError: (Object _, StackTrace _) {});
  }

  void _clearFilters() {
    _search.clear();
    setState(() {
      _query = '';
      _deadline = CrewDeadlineFilter.all;
      _type = null;
    });
  }

  Future<void> _pickType(List<String> types) async {
    final picked = await showFcReportTypeSheet(
      context,
      types: types,
      selected: _type,
    );
    if (picked == null || !mounted) return;
    setState(() => _type = picked == fcAllReportTypes ? null : picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final async = ref.watch(assignedReportsProvider);
    final data = async.value;
    final now =
        ref.watch(responseDeadlineClockProvider).value ?? DateTime.now();

    Widget body;
    if (data == null && async.isLoading) {
      body = const Align(
        alignment: Alignment.topCenter,
        child: LinearProgressIndicator(semanticsLabel: 'Loading your reports'),
      );
    } else if (data == null) {
      body = AppStateView(
        icon: Icons.cloud_off_outlined,
        title: 'Reports could not load',
        message:
            'Check your signal and try again. Reports saved on this phone show here when they are available.',
        actionLabel: 'Reload reports',
        onAction: _refresh,
      );
    } else {
      final all = data.reports;
      final types = crewReportTypes(all);
      final lists = splitCrewReports(
        all,
        query: _query,
        deadline: _deadline,
        type: _type,
        now: now,
      );
      // The counts on the switch ignore the deadline choice, which only
      // narrows To handle, so Handled is never shown as smaller than it is.
      final toHandleCount = splitCrewReports(
        all,
        query: _query,
        type: _type,
        now: now,
      ).toHandle.length;
      final filtersActive =
          _query.trim().isNotEmpty ||
          _deadline != CrewDeadlineFilter.all ||
          _type != null;
      final todo = _view == CrewJobView.todo;

      void open(ReportModel report) => context.push(
        '/field-crew/reports/${report.id}',
        extra: data.reportTaskMap[report.id],
      );

      Widget empty(String title, String message, {bool clear = false}) =>
          FcOfflineCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                Text(message),
                if (clear) ...[
                  const SizedBox(height: 16),
                  AppButton(
                    text: 'Clear search and filters',
                    variant: ButtonVariant.secondary,
                    onPressed: _clearFilters,
                  ),
                ],
              ],
            ),
          );

      final items = <Widget>[
        FcJobsViewSwitch(
          view: _view,
          todoCount: toHandleCount,
          doneCount: lists.handled.length,
          leftLabel: 'To handle',
          rightLabel: 'Handled',
          noun: 'report',
          onChanged: (view) => setState(() => _view = view),
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                'Pull down to refresh',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: async.isLoading ? null : _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
        if (async.isLoading)
          const LinearProgressIndicator(
            semanticsLabel: 'Updating your reports',
          ),
        if (async.hasError)
          FcOfflineNotice(
            error: true,
            message:
                'Your reports could not refresh. The last saved reports are shown below. Check each report before you act.',
            action: TextButton(
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: async.isLoading ? null : _refresh,
              child: const Text('Reload reports'),
            ),
          ),
        if (all.length > _searchFrom || _query.isNotEmpty)
          TextField(
            controller: _search,
            textInputAction: TextInputAction.search,
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              labelText: 'Search reports',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _search.clear();
                        setState(() => _query = '');
                      },
                    ),
            ),
          ),
        if (todo && (toHandleCount > 0 || _deadline != CrewDeadlineFilter.all))
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final choice in CrewDeadlineFilter.values)
                ChoiceChip(
                  label: Text(choice.label),
                  selected: _deadline == choice,
                  showCheckmark: true,
                  side: BorderSide(
                    color: _deadline == choice
                        ? fcAccent(context)
                        : theme.dividerTheme.color ?? theme.dividerColor,
                  ),
                  selectedColor: fcAccent(context).withValues(alpha: .16),
                  checkmarkColor: fcAccent(context),
                  labelStyle: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: _deadline == choice
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                  onSelected: (_) => setState(() => _deadline = choice),
                ),
            ],
          ),
        if (types.length > 1)
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: () => _pickType(types),
              icon: const Icon(Icons.expand_more),
              iconAlignment: IconAlignment.end,
              label: Text(
                'Type: ${_type == null ? 'All' : crewTaskLabel(_type!)}',
              ),
            ),
          ),
      ];

      final shown = todo ? lists.toHandle : lists.handled;
      if (shown.isEmpty) {
        items.add(
          all.isEmpty
              ? empty(
                  'No reports in your jobs',
                  'Reload when you have signal to check for new reports.',
                )
              : filtersActive
              ? empty(
                  'No reports match',
                  'Nothing in ${todo ? 'To handle' : 'Handled'} matches your search or filter.',
                  clear: true,
                )
              : todo
              ? empty(
                  'No reports left to handle',
                  'Reports you have finished are under Handled.',
                )
              : empty(
                  'No reports handled yet',
                  'Reports that are resolved, completed or closed appear here.',
                ),
        );
      } else {
        items.addAll(
          shown.map(
            (report) => FcReportCard(report: report, onTap: () => open(report)),
          ),
        );
      }
      body = ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, index) => items[index],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: RefreshIndicator(onRefresh: _refresh, child: body),
    );
  }
}
