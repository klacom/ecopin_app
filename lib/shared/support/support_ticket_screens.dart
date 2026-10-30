import 'package:flutter/material.dart';
import 'package:ecopin_app/shared/reports/data/datasources/report_remote_datasource.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/shared/support/support_ticket.dart';
import 'package:ecopin_app/shared/support/support_ticket_api.dart';

class TicketReportOption {
  const TicketReportOption({required this.id, required this.title});
  final String id;
  final String title;
}

Future<List<TicketReportOption>> loadOwnReports() async {
  final reports = await ReportDataSource(ApiClient()).getMyReports();
  return reports.map((r) => TicketReportOption(id: r.id, title: r.title)).toList();
}

String formatTicketDate(DateTime value) {
  final local = value.toLocal();
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
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
          builder: (_) => TicketDetailScreen(api: widget.api, ticket: ticket, justSent: true),
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
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              initialValue: category,
              decoration: const InputDecoration(labelText: 'What do you need?'),
              items: [
                for (final entry in ticketCategories.entries)
                  DropdownMenuItem(value: entry.key, child: Text(entry.value)),
              ],
              onChanged: sending ? null : (value) => setState(() => category = value!),
            ),
            const SizedBox(height: 16),
            if (reports.isNotEmpty) ...[
              DropdownButtonFormField<String?>(
                initialValue: reportId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Related report (optional)'),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('No specific report')),
                  for (final report in reports)
                    DropdownMenuItem<String?>(
                      value: report.id,
                      child: Text(report.title, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: sending ? null : (value) => setState(() => reportId = value),
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
              validator: (value) => (value ?? '').trim().length < ticketDescriptionMin
                  ? 'Add at least $ticketDescriptionMin characters so SWMO can help.'
                  : null,
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            FilledButton(
              onPressed: sending ? null : _send,
              child: Text(sending ? 'Sending…' : 'Send ticket'),
            ),
            const SizedBox(height: 12),
            const Text('For immediate danger, use Official contacts instead of a ticket.'),
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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(ticket.reference)),
    body: RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.justSent)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text('Ticket sent. Keep this reference to follow up. SWMO replies appear here.'),
            ),
          Text(ticket.categoryLabel, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Chip(label: Text(ticket.statusLabel)),
              Text('Opened ${formatTicketDate(ticket.createdAt)}'),
            ],
          ),
          const SizedBox(height: 16),
          Text('Your message', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          SelectableText(ticket.description),
          const SizedBox(height: 24),
          Text('SWMO reply', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          if (ticket.hasReply) ...[
            SelectableText(ticket.response!),
            if (ticket.respondedAt != null)
              Text('Replied ${formatTicketDate(ticket.respondedAt!)}'),
          ] else
            const Text('No reply yet. Pull down to check for a reply.'),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          if (refreshing) const Padding(padding: EdgeInsets.only(top: 16), child: LinearProgressIndicator()),
        ],
      ),
    ),
  );
}
