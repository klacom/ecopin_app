import 'package:flutter/material.dart';

class MapPrivacyConsentDialog extends StatefulWidget {
  const MapPrivacyConsentDialog({super.key, required this.onSave});
  final Future<void> Function(bool) onSave;
  @override
  State<MapPrivacyConsentDialog> createState() =>
      _MapPrivacyConsentDialogState();
}

class _MapPrivacyConsentDialogState extends State<MapPrivacyConsentDialog> {
  bool _saving = false;
  String? _error;
  Future<void> _save(bool choice) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(choice);
      if (mounted) {
        setState(() => _saving = false);
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'We could not save your preference. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      scrollable: true,
      icon: const Icon(Icons.privacy_tip_outlined),
      title: const Text('Data Privacy Consent'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'To help officers verify and resolve your reports more efficiently, '
            'you may allow authorized personnel to access your profile information '
            'and location (when applicable).\n\n'
            'Your information will only be used for handling your reports and '
            'will not be shared with unauthorized parties.\n\n'
            'Your consent is optional, and you can continue using the app even if you decline.',
          ),
          if (_saving) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(semanticsLabel: 'Saving preference'),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            Semantics(
              liveRegion: true,
              child: Text(
                _error!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => _save(false),
          child: const Text('Disagree'),
        ),
        FilledButton(
          onPressed: _saving ? null : () => _save(true),
          child: const Text('Agree'),
        ),
      ],
    ),
  );
}
