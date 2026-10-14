import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ecopin_app/core/constants/app_constants.dart';
import 'package:ecopin_app/features/admin/data/admin_repository.dart';
import 'package:ecopin_app/features/admin/data/admin_page.dart';
import 'package:ecopin_app/features/admin/data/audit_payload.dart';
import 'package:ecopin_app/features/admin/presentation/widgets/admin_widgets.dart';
import 'package:ecopin_app/routes/app_routes.dart';
import 'package:ecopin_app/shared/notifications/presentation/widgets/notification_badge_action.dart';
import 'package:ecopin_app/shared/widgets/app_button.dart';
import 'package:ecopin_app/shared/widgets/app_state_view.dart';

String _auditActor(Map<String, dynamic> entry) {
  final profile = entry['profiles'];
  return (profile is Map ? profile['full_name'] : null)?.toString() ??
      entry['user_name']?.toString() ??
      entry['user_id']?.toString() ??
      'Actor unavailable';
}

String _auditAction(Map<String, dynamic> entry) =>
    adminLabel(entry['event_type'] ?? entry['action_type']);

class AdminAuditLogsScreen extends ConsumerStatefulWidget {
  const AdminAuditLogsScreen({super.key});
  @override
  ConsumerState<AdminAuditLogsScreen> createState() =>
      _AdminAuditLogsScreenState();
}

class _AdminAuditLogsScreenState extends ConsumerState<AdminAuditLogsScreen> {
  final _search = TextEditingController(), _actor = TextEditingController();
  final _actionInput = TextEditingController();
  final _actionFocus = FocusNode();
  String _action = '', _loadedAction = '', _loadedActor = '', _loadedRange = '';
  DateTimeRange? _range;
  DateTimeRange? _loadedDateRange;
  final _actions = <String>{};
  AdminPage? _data;
  bool _loading = true, _accountRecovery = false;
  int _page = 1, _request = 0;
  String? _error;
  @override
  void initState() {
    super.initState();
    _actionInput.addListener(() {
      if (mounted) setState(() => _action = _actionInput.text.trim());
    });
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    _actor.dispose();
    _actionInput.dispose();
    _actionFocus.dispose();
    super.dispose();
  }

  String get _rangeKey =>
      _range == null ? '' : '${_range!.start}:${_range!.end}';
  bool get _filtersPending =>
      _data != null &&
      (_loadedAction != _action ||
          _loadedActor != _actor.text.trim() ||
          _loadedRange != _rangeKey);
  Future<void> _load({int? page, bool refreshApplied = false}) async {
    final request = ++_request, requestedPage = page ?? _page;
    final useApplied = refreshApplied && _data != null;
    final action = useApplied ? _loadedAction : _action,
        actor = useApplied ? _loadedActor : _actor.text.trim(),
        rangeKey = useApplied ? _loadedRange : _rangeKey;
    final range = useApplied ? _loadedDateRange : _range;
    final start = range == null
        ? ''
        : DateTime(
            range.start.year,
            range.start.month,
            range.start.day,
          ).toUtc().toIso8601String();
    final end = range == null
        ? ''
        : DateTime(
            range.end.year,
            range.end.month,
            range.end.day + 1,
          ).subtract(const Duration(microseconds: 1)).toUtc().toIso8601String();
    setState(() {
      _loading = true;
      _page = requestedPage;
      _error = null;
      _accountRecovery = false;
    });
    try {
      final response = await ref
          .read(adminRepositoryProvider)
          .getAuditLogs(
            page: requestedPage,
            action: action,
            userId: actor,
            startDate: start,
            endDate: end,
          );
      final data = AdminPage.fromResponse(response, 'logs', requestedPage);
      if (!mounted || request != _request) return;
      if (data.records.isEmpty &&
          data.totalPages != null &&
          data.totalPages! > 0 &&
          requestedPage > data.totalPages!) {
        await _load(page: data.totalPages, refreshApplied: refreshApplied);
        return;
      }
      setState(() {
        _data = data;
        _page = data.page;
        _loading = false;
        _loadedAction = action;
        _loadedActor = actor;
        _loadedRange = rangeKey;
        _loadedDateRange = range;
        _actions.addAll(
          data.records
              .map((entry) => entry['action_type'])
              .whereType<String>()
              .where((action) => action.isNotEmpty),
        );
      });
    } catch (error) {
      if (mounted && request == _request) {
        setState(() {
          _loading = false;
          _error = adminErrorMessage(error);
          _accountRecovery = adminRequiresAccountRecovery(error);
        });
      }
    }
  }

  Future<void> _chooseDates() async {
    final dates = await showDateRangePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      initialDateRange: _range,
      helpText: 'Filter recorded dates',
      saveText: 'Use dates',
      confirmText: 'Use dates',
    );
    if (dates != null && mounted) setState(() => _range = dates);
  }

  void _reset() {
    _search.clear();
    _actor.clear();
    _actionInput.clear();
    setState(() {
      _range = null;
      _action = '';
    });
    _load(page: 1);
  }

  void _openEntry(Map<String, dynamic> entry) => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => _AuditEntryScreen(entry: entry)),
  );
  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final entries =
        _data?.records
            .where(
              (entry) =>
                  '${_auditActor(entry)} ${_auditAction(entry)} ${entry['user_id'] ?? ''} ${auditPayloadText(entry)} ${entry['entity_id'] ?? ''}'
                      .toLowerCase()
                      .contains(query),
            )
            .toList() ??
        <Map<String, dynamic>>[];
    final rangeLabel = _range == null
        ? 'Choose date range'
        : '${DateFormat('d MMM y').format(_range!.start)} – ${DateFormat('d MMM y').format(_range!.end)}';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit logs'),
        toolbarHeight:
            MediaQuery.textScalerOf(
                  context,
                ).clamp(maxScaleFactor: 1.3).scale(24) *
                2 +
            16,
        actions: const [NotificationBadgeAction(role: UserRole.admin)],
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(refreshApplied: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Search this page',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      label: 'Search this page',
                      child: TextField(
                        key: const Key('admin-audit-search'),
                        controller: _search,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Details',
                          suffixIcon: _search.text.isEmpty
                              ? const Icon(Icons.search)
                              : IconButton(
                                  tooltip: 'Clear audit search',
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    _search.clear();
                                    setState(() {});
                                  },
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Search this page. Filters below check all entries.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 24),
                    ExpansionTile(
                      title: const Text('Filters'),
                      maintainState: true,
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.symmetric(vertical: 16),
                      onExpansionChanged: (expanded) {
                        if (!expanded) _actionFocus.unfocus();
                      },
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Action code',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            const SizedBox(height: 8),
                            Autocomplete<String>(
                              textEditingController: _actionInput,
                              focusNode: _actionFocus,
                              optionsMaxHeight: 240,
                              optionsBuilder: (value) => _actions
                                  .where(
                                    (action) => action.toLowerCase().contains(
                                      value.text.toLowerCase(),
                                    ),
                                  )
                                  .toList(),
                              onSelected: (_) => _actionFocus.unfocus(),
                              fieldViewBuilder:
                                  (
                                    context,
                                    controller,
                                    focus,
                                    submit,
                                  ) => Semantics(
                                    label: 'Action code',
                                    child: TextField(
                                      key: const Key('admin-audit-action'),
                                      controller: controller,
                                      focusNode: focus,
                                      autocorrect: false,
                                      enableSuggestions: false,
                                      onSubmitted: (_) => submit(),
                                      decoration: const InputDecoration(
                                        hintText: 'All actions',
                                        helperText:
                                            'Choose a known action or enter its exact code. Leave blank for all.',
                                        helperMaxLines: 4,
                                      ),
                                    ),
                                  ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              key: const Key('admin-audit-actor'),
                              controller: _actor,
                              autocorrect: false,
                              enableSuggestions: false,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                labelText: 'Actor account ID',
                                helperText: 'Optional exact account ID',
                                helperMaxLines: 3,
                              ),
                            ),
                            const SizedBox(height: 16),
                            AppButton(
                              text: rangeLabel,
                              icon: Icons.calendar_month_outlined,
                              variant: ButtonVariant.secondary,
                              onPressed: _chooseDates,
                            ),
                            if (_range != null)
                              AppButton(
                                text: 'Clear date range',
                                variant: ButtonVariant.link,
                                onPressed: () => setState(() => _range = null),
                              ),
                            const SizedBox(height: 16),
                            AppButton(
                              text: 'Apply filters',
                              onPressed: _loading
                                  ? null
                                  : () {
                                      FocusManager.instance.primaryFocus
                                          ?.unfocus();
                                      _load(page: 1);
                                    },
                            ),
                            AppButton(
                              text: 'Reset filters',
                              variant: ButtonVariant.link,
                              onPressed:
                                  _loading ||
                                      (_action.isEmpty &&
                                          _actor.text.isEmpty &&
                                          _range == null &&
                                          _search.text.isEmpty)
                                  ? null
                                  : _reset,
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (_filtersPending)
                      const Text(
                        'Updated filters have not loaded. Previous results are shown.',
                      ),
                    if (_loading) ...[
                      const LinearProgressIndicator(
                        semanticsLabel: 'Loading audit entries',
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_error != null) ...[
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                      AppButton(
                        text: _accountRecovery
                            ? 'Open Account'
                            : 'Retry audit logs',
                        variant: ButtonVariant.secondary,
                        onPressed: _accountRecovery
                            ? () => context.go(AdminAppRoutes.profile)
                            : _load,
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_data != null) ...[
                      if (entries.isEmpty)
                        AppStateView(
                          title: _data!.records.isEmpty
                              ? 'No audit entries returned'
                              : 'No matches on this page',
                          message:
                              'Change the page search or server filters to try again.',
                          icon: Icons.history,
                        ),
                      for (final entry in entries)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                _auditAction(entry),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(_auditActor(entry)),
                              const SizedBox(height: 8),
                              Text(
                                adminDate(entry['created_at']),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                auditPayloadText(entry),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 16),
                              AppButton(
                                key: ValueKey(
                                  'admin-audit-view-${entry['id']}',
                                ),
                                text: 'View entry',
                                variant: ButtonVariant.secondary,
                                onPressed: () => _openEntry(entry),
                              ),
                            ],
                          ),
                        ),
                      AdminPageNavigation(
                        data: _data!,
                        visibleCount: entries.length,
                        busy: _loading || _filtersPending,
                        onPage: (page) => _load(page: page),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuditEntryScreen extends StatelessWidget {
  const _AuditEntryScreen({required this.entry});
  final Map<String, dynamic> entry;
  @override
  Widget build(BuildContext context) {
    final profile = entry['profiles'] is Map ? entry['profiles'] as Map : {};
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit entry'),
        toolbarHeight:
            MediaQuery.textScalerOf(
                  context,
                ).clamp(maxScaleFactor: 1.3).scale(24) *
                2 +
            16,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AdminDetailField(label: 'Action', value: _auditAction(entry)),
                  AdminDetailField(
                    label: 'Action code',
                    value:
                        (entry['action_type'] ?? entry['event_type'])
                            ?.toString() ??
                        'Unavailable',
                    technical: true,
                  ),
                  AdminDetailField(
                    label: 'Recorded',
                    value: adminDate(entry['created_at']),
                  ),
                  AdminDetailField(label: 'Actor', value: _auditActor(entry)),
                  AdminDetailField(
                    label: 'Actor email',
                    value: profile['email']?.toString() ?? 'Unavailable',
                  ),
                  AdminDetailField(
                    label: 'Actor ID',
                    value: entry['user_id']?.toString() ?? 'Unavailable',
                    technical: true,
                  ),
                  AdminDetailField(
                    label: 'Entry ID',
                    value: entry['id']?.toString() ?? 'Unavailable',
                    technical: true,
                  ),
                  AdminDetailField(
                    label: 'Target type',
                    value: adminLabel(
                      entry['entity_type'] ?? entry['target_type'],
                    ),
                  ),
                  AdminDetailField(
                    label: 'Target ID',
                    value:
                        entry['entity_id']?.toString() ??
                        entry['report_id']?.toString() ??
                        'Unavailable',
                    technical: true,
                  ),
                  const Text(
                    'Known credential fields are hidden in the displayed and copied payload.',
                  ),
                  const SizedBox(height: 12),
                  AdminDetailField(
                    label: 'Recorded payload',
                    value: auditPayloadText(entry),
                    technical: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
