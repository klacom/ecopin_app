import 'package:flutter/material.dart';
import 'package:ecopin_app/shared/support/official_contacts_screen.dart';
import 'package:ecopin_app/shared/support/support_ticket.dart';
import 'package:ecopin_app/shared/support/support_ticket_api.dart';
import 'package:ecopin_app/shared/support/support_ticket_screens.dart';

const _faqs = <({String question, String answer})>[
  (
    question: 'Why is my new report not on the public map yet?',
    answer:
        'Reports are checked by an automated step and by desk staff before they are published. Once confirmed as a valid concern in Pasig, the pin becomes visible to the public.',
  ),
  (
    question: 'The pin landed on the wrong street. Can I fix it?',
    answer:
        'While the report is still pending review, open a Location correction ticket from the My tickets tab and link it to your report. You can also withdraw the report and submit it again with the pin on the exact landmark.',
  ),
  (
    question: 'What do the report statuses mean?',
    answer:
        'Unresolved: the report is verified and waiting for dispatch. In progress: an SWMO field crew is assigned and responding. Resolved: the crew submitted cleanup photos. Closed: final sign-off is complete.',
  ),
  (
    question: 'What photos help my report get verified fastest?',
    answer:
        'Take clear, well-lit photos that show the problem and a recognizable landmark or street corner. Avoid taking photos while moving so the location stays accurate.',
  ),
  (
    question: 'The waste is inside a private property. What happens?',
    answer:
        'City crews can only clean public roads, waterways and public easements. For waste on private property, SWMO coordinates with the barangay and the property owner.',
  ),
  (
    question: 'How do I follow up on a report?',
    answer:
        'Open a Status inquiry ticket from the My tickets tab. You get a ticket reference, and the SWMO reply shows up on that ticket.',
  ),
];

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key, this.api, this.loadReports});

  final SupportTicketApi? api;
  final Future<List<TicketReportOption>> Function()? loadReports;

  @override
  Widget build(BuildContext context) {
    final client = api ?? SupportTicketApi();
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Help & support'),
          actions: const [OfficialContactsButton()],
          bottom: const TabBar(tabs: [Tab(text: 'Help'), Tab(text: 'My tickets')]),
        ),
        body: TabBarView(
          children: [
            const _FaqTab(),
            MyTicketsTab(api: client, loadReports: loadReports),
          ],
        ),
      ),
    );
  }
}

class _FaqTab extends StatefulWidget {
  const _FaqTab();
  @override
  State<_FaqTab> createState() => _FaqTabState();
}

class _FaqTabState extends State<_FaqTab> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final terms = query.trim().toLowerCase();
    final matches = _faqs
        .where((faq) =>
            terms.isEmpty ||
            faq.question.toLowerCase().contains(terms) ||
            faq.answer.toLowerCase().contains(terms))
        .toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          decoration: const InputDecoration(
            labelText: 'Search help',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) => setState(() => query = value),
        ),
        const SizedBox(height: 8),
        if (matches.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'No matching answers. Open a ticket from the My tickets tab and SWMO will reply there.',
            ),
          ),
        for (final faq in matches)
          ExpansionTile(
            title: Text(faq.question),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [Text(faq.answer)],
          ),
        const SizedBox(height: 16),
        const Text(
          'For immediate danger, such as live fallen wires or severe flooding, use Official contacts at the top of this screen instead of waiting for a report review.',
        ),
      ],
    );
  }
}

class MyTicketsTab extends StatefulWidget {
  const MyTicketsTab({super.key, required this.api, this.loadReports});
  final SupportTicketApi api;
  final Future<List<TicketReportOption>> Function()? loadReports;
  @override
  State<MyTicketsTab> createState() => _MyTicketsTabState();
}

class _MyTicketsTabState extends State<MyTicketsTab> {
  final tickets = <SupportTicket>[];
  Map<String, String>? nextCursor;
  bool loading = true;
  bool loadingMore = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final page = await widget.api.list();
      if (!mounted) return;
      setState(() {
        tickets
          ..clear()
          ..addAll(page.tickets);
        nextCursor = page.nextCursor;
      });
    } on SupportTicketException catch (e) {
      if (mounted) setState(() => error = e.message);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _more() async {
    if (loadingMore || nextCursor == null) return;
    setState(() => loadingMore = true);
    try {
      final page = await widget.api.list(cursor: nextCursor);
      if (!mounted) return;
      setState(() {
        tickets.addAll(page.tickets);
        nextCursor = page.nextCursor;
      });
    } on SupportTicketException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => loadingMore = false);
    }
  }

  Future<void> _create() async {
    final created = await Navigator.of(context).push<SupportTicket>(
      MaterialPageRoute(
        builder: (_) => NewTicketScreen(api: widget.api, loadReports: widget.loadReports),
      ),
    );
    if (created != null) await _load();
  }

  Future<void> _open(SupportTicket ticket) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => TicketDetailScreen(api: widget.api, ticket: ticket)),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (loading && tickets.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          FilledButton.icon(
            onPressed: _create,
            icon: const Icon(Icons.add),
            label: const Text('New ticket'),
          ),
          const SizedBox(height: 16),
          if (error != null) ...[
            Text(error!),
            TextButton(onPressed: _load, child: const Text('Try again')),
          ] else if (tickets.isEmpty)
            const Text(
              'You have no tickets yet. Open one to ask SWMO about a report. Only you can see your tickets and the replies.',
            ),
          for (final ticket in tickets)
            Card(
              child: ListTile(
                onTap: () => _open(ticket),
                title: Text('${ticket.reference} · ${ticket.categoryLabel}'),
                subtitle: Text(
                  ticket.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Chip(label: Text(ticket.statusLabel)),
              ),
            ),
          if (nextCursor != null)
            TextButton(
              onPressed: loadingMore ? null : _more,
              child: Text(loadingMore ? 'Loading…' : 'Load older tickets'),
            ),
        ],
      ),
    );
  }
}
