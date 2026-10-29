import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class OfficialContacts {
  static const swmoPhone = '(02) 8643-1111';
  static const swmoTel = 'tel:+63286431111';
  static const extension = '1392';
  static const email = 'swmo@pasigcity.gov.ph';
  static const emergencyPhone = '(02) 8643-0000';
  static const emergencyTel = 'tel:+63286430000';
  static const directory =
      'https://pasigcity.gov.ph/about-pasig-city/directory';
  static const emergencySource = 'https://pasigcity.gov.ph/';
}

class OfficialContactsButton extends StatelessWidget {
  const OfficialContactsButton({super.key});
  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Official contacts',
    icon: const Icon(Icons.phone_outlined),
    onPressed: () => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const OfficialContactsScreen()),
    ),
  );
}

class OfficialContactsScreen extends StatelessWidget {
  const OfficialContactsScreen({super.key, this.openLink});
  final Future<bool> Function(Uri)? openLink;

  Future<void> _open(BuildContext context, String target) async {
    try {
      final uri = Uri.parse(target);
      final opened = await (openLink != null
          ? openLink!(uri)
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
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
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
          const Text('Pasig Solid Waste Management Office (SWMO)'),
          const SelectableText(
            '${OfficialContacts.swmoPhone} local ${OfficialContacts.extension}',
          ),
          const Text(
            'Call the City Hall trunkline, then ask for SWMO, local 1392. The button dials the trunkline only.',
          ),
          FilledButton.icon(
            onPressed: () => _open(context, OfficialContacts.swmoTel),
            icon: const Icon(Icons.call_outlined),
            label: const Text('Call SWMO trunkline'),
          ),
          const SelectableText(OfficialContacts.email),
          OutlinedButton.icon(
            onPressed: () => _open(
              context,
              'mailto:${OfficialContacts.email}?subject=Barangay%20cleanup%20coordination',
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
          const Text(
            'Your name, official role and barangay or organizing office; exact location and landmark; event date/time, cleanup needed and hazards; callback number and report ID, if available.',
          ),
        ]),
        _card(context, [
          Text(
            'Immediate danger or emergency?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Text(
            'For immediate threats to people or public safety, contact the Pasig City Emergency Hotline rather than waiting for an EcoPin review.',
          ),
          const SelectableText(OfficialContacts.emergencyPhone),
          OutlinedButton(
            onPressed: () => _open(context, OfficialContacts.emergencyTel),
            child: const Text('Call Pasig emergency hotline'),
          ),
        ]),
        const Text(
          'Public office contacts · Directory checked 29 October 2026. Device dialer/email availability varies.',
        ),
        TextButton(
          onPressed: () => _open(context, OfficialContacts.directory),
          child: const Text('Official city directory'),
        ),
        TextButton(
          onPressed: () => _open(context, OfficialContacts.emergencySource),
          child: const Text('Official emergency hotline listing'),
        ),
      ],
    ),
  );
}
