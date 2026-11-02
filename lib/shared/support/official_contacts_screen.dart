import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ecopin_app/core/services/api_service.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/core/theme/app_theme.dart';
import 'package:ecopin_app/shared/widgets/app_button.dart';
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

  Widget _card(
    BuildContext context,
    List<Widget> children, {
    bool quiet = false,
  }) => Card(
    margin: EdgeInsets.zero,
    color: quiet ? _quietColor(context) : null,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppColors.radiusCard),
      side: quiet
          ? BorderSide.none
          : BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.dividerDark
                  : AppColors.dividerLight,
            ),
    ),
    child: Padding(
      padding: const EdgeInsets.all(AppColors.spaceMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            children[i],
          ],
        ],
      ),
    ),
  );

  Color _quietColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? AppColors.quietSurfaceDark
      : AppColors.quietSurfaceLight;

  Widget _heading(BuildContext context, String text) => Semantics(
    header: true,
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondary = theme.brightness == Brightness.dark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final small = theme.textTheme.bodySmall!.copyWith(color: secondary);
    final emergencyColor =
        theme.extension<AppStatusColors>()?.error ?? theme.colorScheme.error;
    return Scaffold(
      appBar: AppBar(title: const Text('Official contacts')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
          children: [
            if (loading)
              Semantics(
                liveRegion: true,
                child: const Text('Loading published office contacts…'),
              ),
            if (failed) ...[
              const Text(
                'Current contacts could not load. Showing bundled office contacts; confirm with the city directory.',
              ),
              TextButton(onPressed: _load, child: const Text('Retry contacts')),
            ],
            const SizedBox(height: 8),
            Semantics(
              header: true,
              child: Text(
                'Reach the right office',
                style: theme.textTheme.headlineSmall,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'For barangay leaders and organizers coordinating cleanups, community events and liga activities with SWMO.',
                style: small,
              ),
            ),
            _card(context, [
              Row(
                children: [
                  ExcludeSemantics(
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _quietColor(context),
                        borderRadius: BorderRadius.circular(
                          AppColors.radiusInput,
                        ),
                      ),
                      child: Icon(
                        Icons.business_outlined,
                        color: theme.brightness == Brightness.dark
                            ? AppColors.linkDark
                            : AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _heading(context, 'SWMO'),
                        Text('Pasig City', style: small),
                      ],
                    ),
                  ),
                ],
              ),
              Text(contacts.office),
              SelectableText(contacts.phone, style: theme.textTheme.titleLarge),
              SelectableText(
                contacts.extension.isEmpty
                    ? 'Ask for SWMO once connected.'
                    : 'Ask for SWMO, local ${contacts.extension}.',
                style: small,
              ),
              AppButton(
                onPressed: () => _open(
                  context,
                  OfficialContactSettings.dial(contacts.phone)!,
                ),
                icon: Icons.call_outlined,
                text: 'Call SWMO trunkline',
              ),
              Text('Dials the trunkline only.', style: small),
              if (contacts.email.isNotEmpty) const Divider(),
              if (contacts.email.isNotEmpty) SelectableText(contacts.email),
              if (contacts.email.isNotEmpty)
                AppButton(
                  variant: ButtonVariant.secondary,
                  onPressed: () => _open(
                    context,
                    'mailto:${contacts.email}?subject=Barangay%20cleanup%20coordination',
                  ),
                  icon: Icons.mail_outline,
                  text: 'Email SWMO',
                ),
            ]),
            const SizedBox(height: 24),
            Text(
              'No EcoPin report or trust score is needed to call. Calling or emailing does not submit a report or dispatch a crew. SWMO confirms crew availability, response and schedule.',
              style: small,
            ),
            const SizedBox(height: 24),
            _card(context, [
              Row(
                children: [
                  ExcludeSemantics(
                    child: Icon(Icons.shield_outlined, color: emergencyColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _heading(context, 'Immediate danger?')),
                ],
              ),
              Text(
                'For threats to people or public safety, call Pasig emergency services. Do not wait for an EcoPin review.',
                style: small,
              ),
              SelectableText(
                contacts.emergency,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    foregroundColor: emergencyColor,
                    side: BorderSide(color: emergencyColor),
                  ),
                  onPressed: () => _open(
                    context,
                    OfficialContactSettings.dial(contacts.emergency)!,
                  ),
                  child: const Text(
                    'Call Pasig emergency hotline',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ], quiet: true),
            const SizedBox(height: 24),
            const Divider(),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 16),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              shape: const Border(),
              collapsedShape: const Border(),
              title: Text(
                'Have these details ready',
                style: theme.textTheme.titleSmall,
              ),
              children: [
                for (final detail in [
                  'Your name, official role and barangay or office',
                  'Exact location and nearby landmark',
                  'Event schedule, cleanup needed and hazards',
                  'Callback number and report ID, if available',
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text('• $detail', style: small),
                  ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Public office contacts · ${contacts.verified.isEmpty ? 'Verification date not provided.' : 'Last verified ${contacts.verified}.'} Device dialer/email availability varies.',
              style: small,
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
}
