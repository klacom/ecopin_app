import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'official_contact_settings.dart';

class OfficialContactsButton extends StatelessWidget {
  const OfficialContactsButton({super.key, this.loadCms});
  final Future<Map<String, dynamic>> Function()? loadCms;
  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Official contacts',
    icon: const Icon(Icons.phone_outlined),
    onPressed: () => Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => OfficialContactsScreen(loadCms: loadCms),
      ),
    ),
  );
}

class OfficialContactsScreen extends StatefulWidget {
  const OfficialContactsScreen({super.key, this.openLink, this.loadCms});
  final Future<bool> Function(Uri)? openLink;
  final Future<Map<String, dynamic>> Function()? loadCms;
  @override
  State<OfficialContactsScreen> createState() => _OfficialContactsScreenState();
}

class _OfficialContactsScreenState extends State<OfficialContactsScreen> {
  OfficialContactSettings contacts = const OfficialContactSettings();
  bool loading = true;
  bool failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      failed = false;
    });
    try {
      final data = widget.loadCms != null
          ? await widget.loadCms!()
          : Map<String, dynamic>.from(
              (await ApiClient().dioClient.get('/api/contact/settings')).data
                  as Map,
            );
      if (mounted) {
        setState(() {
          contacts = OfficialContactSettings(data);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          failed = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> _open(BuildContext context, String target) async {
    try {
      final uri = Uri.parse(target);
      final opened = await (widget.openLink != null
          ? widget.openLink!(uri)
          : launchUrl(uri, mode: LaunchMode.externalApplication));
      if (opened) return;
    } catch (_) {
      // Keep the published contact visible when the device cannot open a handler.
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not open this contact. Use the number or address shown.',
          ),
        ),
      );
    }
  }

  Widget _card(BuildContext context, List<Widget> children) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children
            .map(
              (child) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: child,
              ),
            )
            .toList(),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Official contacts')),
    body: SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (loading) const Text('Loading published office contacts…'),
          if (failed) ...[
            const Text(
              'Current contacts could not load. Showing bundled office contacts; confirm with the city directory.',
            ),
            TextButton(onPressed: _load, child: const Text('Retry contacts')),
          ],
          Text(
            'Contact SWMO directly',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'For barangay leaders and official event organizers coordinating critical cleanup, community events or liga activities.',
            ),
          ),
          _card(context, [
            Text(
              'Cleanup & event coordination',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(contacts.office),
            SelectableText(
              '${contacts.phone}${contacts.extension.isEmpty ? '' : ' local ${contacts.extension}'}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              'Call the office trunkline${contacts.extension.isEmpty ? '' : ', then ask for SWMO, local ${contacts.extension}'}. The button dials the trunkline only.',
            ),
            FilledButton.icon(
              onPressed: () =>
                  _open(context, OfficialContactSettings.dial(contacts.phone)!),
              icon: const Icon(Icons.call_outlined),
              label: const Text('Call SWMO trunkline'),
            ),
            if (contacts.email.isNotEmpty) SelectableText(contacts.email),
            if (contacts.email.isNotEmpty)
              OutlinedButton.icon(
                onPressed: () => _open(
                  context,
                  'mailto:${contacts.email}?subject=Barangay%20cleanup%20coordination',
                ),
                icon: const Icon(Icons.mail_outline),
                label: const Text('Email SWMO'),
              ),
            const Text(
              'No EcoPin report or trust score is needed to call. SWMO confirms crew availability, response and schedule. Opening a call or email does not submit a report or dispatch a crew.',
            ),
          ]),
          _card(context, [
            Text(
              'Have these details ready',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Text('• Your name, official role and barangay or office'),
            const Text('• Exact location and nearby landmark'),
            const Text('• Event schedule, cleanup needed and hazards'),
            const Text('• Callback number and report ID, if available'),
          ]),
          _card(context, [
            Text(
              'Immediate danger or emergency?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Text(
              'For immediate threats to people or public safety, contact the Pasig City Emergency Hotline rather than waiting for an EcoPin review.',
            ),
            SelectableText(
              contacts.emergency,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            OutlinedButton(
              onPressed: () => _open(
                context,
                OfficialContactSettings.dial(contacts.emergency)!,
              ),
              child: const Text('Call Pasig emergency hotline'),
            ),
          ]),
          Text(
            'Public office contacts · ${contacts.verified.isEmpty ? 'Verification date not provided.' : 'Last verified ${contacts.verified}.'} Device dialer/email availability varies.',
          ),
          TextButton(
            onPressed: () => _open(context, contacts.directory),
            child: const Text('Official city directory'),
          ),
          TextButton(
            onPressed: () => _open(context, contacts.emergencySource),
            child: const Text('Official emergency hotline listing'),
          ),
        ],
      ),
    ),
  );
}
