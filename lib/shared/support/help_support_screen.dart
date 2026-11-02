import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/shared/widgets/app_button.dart';
import 'package:ecopin_app/shared/widgets/sliding_switch.dart';
import 'package:ecopin_app/shared/support/official_contacts_screen.dart';
import 'package:ecopin_app/shared/support/support_ticket.dart';
import 'package:ecopin_app/shared/support/support_ticket_api.dart';
import 'package:ecopin_app/shared/support/support_ticket_screens.dart';
import 'support_section.dart';

const _faqs = <({String question, String answer})>[
  (
    question: 'Why is my new report not on the public map yet?',
    answer:
        'Reports are checked by an automated step and by desk staff before they are published. Once confirmed as a valid concern in Pasig, the pin becomes visible to the public.',
  ),
  (
    question: 'The pin landed on the wrong street. Can I fix it?',
    answer:
        'While the report is still pending review, open a Location correction ticket from My tickets and link it to your report.',
  ),
  (
    question: 'What do the report statuses mean?',
    answer:
        'Follow response progress in Reports. The report’s review decision and its response status are shown separately.',
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

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key, this.api, this.loadReports});

  final SupportTicketApi? api;
  final Future<List<TicketReportOption>> Function()? loadReports;

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen>
    with SingleTickerProviderStateMixin {
  late final client = widget.api ?? SupportTicketApi();
  late final tabs = TabController(length: 2, vsync: this);
  int ticketsRevision = 0;

  @override
  void dispose() {
    tabs.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final created = await Navigator.of(context).push<SupportTicket>(
      MaterialPageRoute(
        builder: (_) =>
            NewTicketScreen(api: client, loadReports: widget.loadReports),
      ),
    );
    if (mounted && created != null) {
      setState(() => ticketsRevision++);
      tabs.animateTo(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: MediaQuery.textScalerOf(context).scale(20) > 26
            ? 112
            : 64,
        title: const Text(
          'Help & support',
          maxLines: 2,
          textAlign: TextAlign.center,
        ),
        actions: const [OfficialContactsButton()],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: AnimatedBuilder(
                animation: tabs,
                builder: (context, _) => SlidingSwitch(
                  options: const [
                    SlidingSwitchOption(label: 'Help'),
                    SlidingSwitchOption(label: 'My tickets'),
                  ],
                  selectedIndex: tabs.index,
                  onChanged: tabs.animateTo,
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: tabs,
                children: [
                  _FaqTab(onCreate: _create),
                  MyTicketsTab(
                    key: ValueKey(ticketsRevision),
                    api: client,
                    onCreate: _create,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqTab extends StatefulWidget {
  const _FaqTab({required this.onCreate});
  final VoidCallback onCreate;
  @override
  State<_FaqTab> createState() => _FaqTabState();
}

class _FaqTabState extends State<_FaqTab> with AutomaticKeepAliveClientMixin {
  String query = '';
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final secondary = theme.brightness == Brightness.dark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final small = theme.textTheme.bodySmall!.copyWith(color: secondary);
    final terms = query.trim().toLowerCase();
    final matches = _faqs
        .where(
          (faq) =>
              terms.isEmpty ||
              faq.question.toLowerCase().contains(terms) ||
              faq.answer.toLowerCase().contains(terms),
        )
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Semantics(
          header: true,
          child: Text('How can we help?', style: theme.textTheme.headlineSmall),
        ),
        const SizedBox(height: 12),
        Text(
          'Find answers about reports, locations and using EcoPin.',
          style: small,
        ),
        const SizedBox(height: 24),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Search help',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) => setState(() => query = value),
        ),
        const SizedBox(height: 24),
        Semantics(
          header: true,
          child: Text('Common questions', style: theme.textTheme.titleMedium),
        ),
        const SizedBox(height: 8),
        if (matches.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Semantics(
              liveRegion: true,
              child: Text(
                'No matching answers. Open a ticket and SWMO can reply there.',
                style: small,
              ),
            ),
          ),
        for (final faq in matches) ...[
          ExpansionTile(
            key: PageStorageKey(faq.question),
            tilePadding: EdgeInsets.zero,
            title: Text(
              faq.question,
              style: theme.textTheme.bodyMedium!.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            shape: const Border(),
            collapsedShape: const Border(),
            childrenPadding: const EdgeInsets.only(bottom: 16),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [Text(faq.answer, style: small)],
          ),
          const Divider(),
        ],
        const SizedBox(height: 24),
        SupportSection(
          title: 'Still need help?',
          quiet: true,
          children: [
            Text(
              'Ask SWMO about a report or your account. You can follow the reply in My tickets.',
              style: small,
            ),
            AppButton(
              text: 'New ticket',
              icon: Icons.add,
              onPressed: widget.onCreate,
            ),
          ],
        ),
        const SizedBox(height: 24),
        const _ContactSection(),
      ],
    );
  }
}

class _ContactSection extends StatelessWidget {
  const _ContactSection();

  @override
  Widget build(BuildContext context) => SupportSection(
    title: 'Need to contact an office?',
    icon: Icons.phone_outlined,
    quiet: true,
    children: [
      const Text(
        'For cleanup coordination or immediate danger, use the published SWMO and emergency contacts.',
      ),
      AppButton(
        text: 'Official contacts',
        icon: Icons.arrow_forward,
        variant: ButtonVariant.link,
        onPressed: () => Navigator.of(context, rootNavigator: true).push<void>(
          MaterialPageRoute(builder: (_) => const OfficialContactsScreen()),
        ),
      ),
    ],
  );
}

class MyTicketsTab extends StatefulWidget {
  const MyTicketsTab({super.key, required this.api, required this.onCreate});
  final SupportTicketApi api;
  final VoidCallback onCreate;
  @override
  State<MyTicketsTab> createState() => _MyTicketsTabState();
}

class _MyTicketsTabState extends State<MyTicketsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
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
    if (loadingMore) return;
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
    if (loading || loadingMore || nextCursor == null) return;
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => loadingMore = false);
    }
  }

  Future<void> _open(SupportTicket ticket) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => TicketDetailScreen(api: widget.api, ticket: ticket),
      ),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final small = theme.textTheme.bodySmall!.copyWith(
      color: dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
    );
    final link = dark ? AppColors.linkDark : AppColors.primary;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Semantics(
            header: true,
            child: Text(
              'Your conversations',
              style: theme.textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: 12),
          Text('Follow your questions and SWMO’s replies.', style: small),
          const SizedBox(height: 24),
          AppButton(
            text: 'New ticket',
            icon: Icons.add,
            onPressed: widget.onCreate,
          ),
          const SizedBox(height: 24),
          if (loading)
            Semantics(
              liveRegion: true,
              label: 'Loading your tickets',
              child: const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: LinearProgressIndicator(),
              ),
            ),
          if (error != null) ...[
            Semantics(liveRegion: true, child: Text(error!, style: small)),
            if (tickets.isNotEmpty)
              Text('Showing previously loaded tickets.', style: small),
            AppButton(
              text: 'Try again',
              variant: ButtonVariant.link,
              onPressed: loading ? null : _load,
            ),
          ] else if (!loading && tickets.isEmpty)
            SupportSection(
              title: 'No tickets yet',
              quiet: true,
              icon: Icons.forum_outlined,
              children: [
                Text(
                  'Ask SWMO a question about a report or your account. Your ticket and replies will appear here.',
                  style: small,
                ),
              ],
            ),
          for (final ticket in tickets)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppColors.radiusCard),
                  side: BorderSide(
                    color: dark
                        ? AppColors.dividerDark
                        : AppColors.dividerLight,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppColors.radiusCard),
                  onTap: () => _open(ticket),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            Text(ticket.reference, style: small),
                            Text(
                              ticket.statusLabel,
                              style: small.copyWith(color: link),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          ticket.categoryLabel,
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          ticket.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: small,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          ticket.hasReply ? 'Reply available' : 'No reply yet',
                          style: small.copyWith(color: link),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (nextCursor != null)
            AppButton(
              text: 'Load older tickets',
              isLoading: loadingMore,
              variant: ButtonVariant.link,
              onPressed: loading ? null : _more,
            ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: Icon(Icons.lock_outline, size: 18, color: small.color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your tickets are not shown on the public map.',
                  style: small,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _ContactSection(),
        ],
      ),
    );
  }
}
