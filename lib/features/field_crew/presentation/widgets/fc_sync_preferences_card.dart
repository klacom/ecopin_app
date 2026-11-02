import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_settings.dart';

/// How the phone sends work: one choice of three, then which networks it may
/// use. It lives in the send screen's “How your work is sent” row. Offline
/// preparation is a separate download the crew starts on purpose.
class FcSyncPreferences extends ConsumerStatefulWidget {
  const FcSyncPreferences({super.key, this.locked = false});
  final bool locked;
  @override
  ConsumerState<FcSyncPreferences> createState() => _FcSyncPreferencesState();
}

class _FcSyncPreferencesState extends ConsumerState<FcSyncPreferences> {
  bool _saving = false, _failed = false;
  String? _message;
  Future<void> _change(Future<void> Function() save) async {
    if (_saving || widget.locked) return;
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      await save();
      if (mounted) {
        setState(() {
          _message = 'Saved.';
          _failed = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _message =
              'Could not save this. Your last choice is still in use. Try again.';
          _failed = true;
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(fcSyncSettingsProvider);
    final notifier = ref.read(fcSyncSettingsProvider.notifier);
    final disabled = widget.locked || _saving;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'When should this phone send your work?',
          style: theme.textTheme.bodyMedium,
        ),
        if (_saving) ...[
          const SizedBox(height: 8),
          const LinearProgressIndicator(semanticsLabel: 'Saving your choice'),
        ],
        RadioGroup<FcSyncMode>(
          groupValue: settings.mode,
          onChanged: (mode) {
            if (!disabled && mode != null) {
              _change(() => notifier.setMode(mode));
            }
          },
          child: Column(
            children: FcSyncMode.values
                .map(
                  (mode) => RadioListTile<FcSyncMode>(
                    value: mode,
                    activeColor: theme.brightness == Brightness.dark
                        ? AppColors.linkDark
                        : AppColors.primaryLight,
                    enabled: !disabled,
                    contentPadding: EdgeInsets.zero,
                    title: Text(mode.title),
                    subtitle: Text(mode.description),
                  ),
                )
                .toList(),
          ),
        ),
        const Divider(height: 24),
        Text('Send using', style: theme.textTheme.bodyMedium),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Wi-Fi'),
          value: settings.syncOverWifi,
          onChanged: disabled
              ? null
              : (value) => _change(() => notifier.setSyncOverWifi(value)),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Mobile data'),
          subtitle: const Text(
            'Photos can use a lot of data. You are asked first when you tap Send now.',
          ),
          value: settings.syncOverMobileData,
          onChanged: disabled
              ? null
              : (value) => _change(() => notifier.setSyncOverMobileData(value)),
        ),
        if (_message != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Semantics(
              liveRegion: true,
              child: Text(
                _message!,
                style: _failed
                    ? theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      )
                    : theme.textTheme.bodyMedium,
              ),
            ),
          ),
      ],
    );
  }
}
