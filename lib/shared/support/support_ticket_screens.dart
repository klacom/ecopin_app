import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/shared/widgets/app_button.dart';
import 'package:ecopin_app/shared/reports/data/datasources/report_remote_datasource.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/shared/support/support_ticket.dart';
import 'package:ecopin_app/shared/support/support_ticket_api.dart';
import 'official_contacts_screen.dart';
import 'support_section.dart';

class TicketReportOption {
  const TicketReportOption({required this.id, required this.title});
  final String id;
  final String title;
}

Future<List<TicketReportOption>> loadOwnReports() async {
  final reports = await ReportDataSource(ApiClient()).getMyReports();
  return reports
      .map((r) => TicketReportOption(id: r.id, title: r.title))
      .toList();
}

String formatTicketDate(DateTime value) {
  final local = value.toLocal();
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  return '${months[local.month - 1]} ${local.day}, ${local.year} $hour:$minute ${local.hour < 12 ? 'AM' : 'PM'}';
}

class NewTicketScreen extends StatefulWidget {
  const NewTicketScreen({super.key, required this.api, this.loadReports});
  final SupportTicketApi api;
  final Future<List<TicketReportOption>> Function()? loadReports;
  @override
  State<NewTicketScreen> createState() => _NewTicketScreenState();
}

class _NewTicketScreenState extends State<NewTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  String category = 'status_inquiry';
  String? reportId;
  List<TicketReportOption> reports = const [];
  bool sending = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _loadReports() async {
    try {
      final loaded = await (widget.loadReports ?? loadOwnReports)();
      if (mounted) setState(() => reports = loaded);
    } catch (_) {
      // Linking a report is optional; the ticket can still be sent without it.
    }
  }

  Future<void> _send() async {
    if (sending || !_formKey.currentState!.validate()) return;
    setState(() {
      sending = true;
      error = null;
    });
    try {
      final ticket = await widget.api.create(
        category: category,
        description: _description.text.trim(),
        reportId: reportId,
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement<SupportTicket, SupportTicket>(
        MaterialPageRoute(
          builder: (_) => TicketDetailScreen(
            api: widget.api,
            ticket: ticket,
            justSent: true,
          ),
        ),
        result: ticket,
      );
    } on SupportTicketException catch (e) {
      if (mounted) {
        setState(() {
          error = e.message;
          sending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('New ticket')),
    body: SafeArea(
      top: false,
      child: Form(
        key: _formKey,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          children: [
            Text(
              'Ask SWMO about a report or your account.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              initialValue: category,
              isExpanded: true,
              itemHeight: null,
              decoration: const InputDecoration(labelText: 'What do you need?'),
              items: [
                for (final entry in ticketCategories.entries)
                  DropdownMenuItem(value: entry.key, child: Text(entry.value)),
              ],
              onChanged: sending
                  ? null
                  : (value) => setState(() => category = value!),
            ),
            const SizedBox(height: 16),
            if (reports.isNotEmpty) ...[
              DropdownButtonFormField<String?>(
                initialValue: reportId,
                isExpanded: true,
                itemHeight: null,
                decoration: const InputDecoration(
                  labelText: 'Related report (optional)',
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('No specific report'),
                  ),
                  for (final report in reports)
                    DropdownMenuItem<String?>(
                      value: report.id,
                      child: Text(report.title),
                    ),
                ],
                onChanged: sending
                    ? null
                    : (value) => setState(() => reportId = value),
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _description,
              enabled: !sending,
              minLines: 5,
              maxLines: 10,
              maxLength: ticketDescriptionMax,
              decoration: const InputDecoration(
                labelText: 'Describe your question or concern',
                alignLabelWithHint: true,
              ),
              validator: (value) =>
                  (value ?? '').trim().length < ticketDescriptionMin
                  ? 'Add at least $ticketDescriptionMin characters so SWMO can help.'
                  : null,
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
            AppButton(
              text: 'Send ticket',
              isLoading: sending,
              onPressed: _send,
            ),
            const SizedBox(height: 12),
            const Text(
              'For immediate danger, use Official contacts instead of a ticket.',
            ),
            TextButton(
              onPressed: sending
                  ? null
                  : () => Navigator.of(context, rootNavigator: true).push<void>(
                      MaterialPageRoute(
                        builder: (_) => const OfficialContactsScreen(),
                      ),
                    ),
              child: const Text('Official contacts'),
            ),
          ],
        ),
      ),
    ),
  );
}

class TicketDetailScreen extends StatefulWidget {
  const TicketDetailScreen({
    super.key,
    required this.api,
    required this.ticket,
    this.justSent = false,
  });
  final SupportTicketApi api;
  final SupportTicket ticket;
  final bool justSent;
  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  late SupportTicket ticket = widget.ticket;
  bool refreshing = false;
  String? error;

  Future<void> _refresh() async {
    if (refreshing) return;
    setState(() {
      refreshing = true;
      error = null;
    });
    try {
      final fresh = await widget.api.get(ticket.reference);
      if (mounted) setState(() => ticket = fresh);
    } on SupportTicketException catch (e) {
      if (mounted) setState(() => error = e.message);
    } finally {
      if (mounted) setState(() => refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final small = theme.textTheme.bodySmall!.copyWith(
      color: dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
    );
    final link = dark ? AppColors.linkDark : AppColors.primary;
    return Scaffold(
      appBar: AppBar(
        title: Text(ticket.reference),
        actions: [
          IconButton(
            tooltip: 'Refresh ticket',
            onPressed: refreshing ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            children: [
              if (widget.justSent)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Semantics(
                    liveRegion: true,
                    child: const Text(
                      'Ticket sent. Keep this reference to follow up. SWMO replies appear here.',
                    ),
                  ),
                ),
              Semantics(
                header: true,
                child: Text(
                  ticket.categoryLabel,
                  style: theme.textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: 12),
              Text(ticket.statusLabel, style: small.copyWith(color: link)),
              const SizedBox(height: 8),
              Text(
                'Opened ${formatTicketDate(ticket.createdAt)}',
                style: small,
              ),
              const SizedBox(height: 24),
              SupportSection(
                title: 'Your message',
                children: [SelectableText(ticket.description)],
              ),
              const SizedBox(height: 24),
              SupportSection(
                title: 'SWMO reply',
                quiet: true,
                children: [
                  if (ticket.hasReply) ...[
                    SelectableText(ticket.response!),
                    if (ticket.respondedAt != null)
                      Text(
                        'Replied ${formatTicketDate(ticket.respondedAt!)}',
                        style: small,
                      ),
                  ] else
                    Text(
                      'No reply yet. Pull down or use Refresh ticket to check for a reply.',
                      style: small,
                    ),
                ],
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      error!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                ),
              if (refreshing)
                Semantics(
                  liveRegion: true,
                  label: 'Refreshing ticket',
                  child: const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: LinearProgressIndicator(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
