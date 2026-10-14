import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_settings.dart';
import 'fc_offline_ui.dart';

class FcSyncPreferencesCard extends ConsumerStatefulWidget {
  const FcSyncPreferencesCard({super.key, this.locked = false});
  final bool locked;
  @override
  ConsumerState<FcSyncPreferencesCard> createState() =>
      _FcSyncPreferencesCardState();
}

class _FcSyncPreferencesCardState extends ConsumerState<FcSyncPreferencesCard> {
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
          _message = 'Sync preferences updated.';
          _failed = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _message =
              'Sync preferences could not save. Your previous setting remains. Please try again.';
          _failed = true;
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(fcSyncSettingsProvider);
    final notifier = ref.read(fcSyncSettingsProvider.notifier);
    final disabled = widget.locked || _saving;
    return FcOfflineCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Sync preferences',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'These network choices apply to queued work. Offline preparation is a separate download you start explicitly.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (_saving) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(
              semanticsLabel: 'Saving sync preferences',
            ),
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
                      activeColor:
                          Theme.of(context).brightness == Brightness.dark
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
          const Divider(height: 32),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Sync over Wi-Fi'),
            value: settings.syncOverWifi,
            onChanged: disabled
                ? null
                : (value) => _change(() => notifier.setSyncOverWifi(value)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Sync over mobile data'),
            subtitle: const Text(
              'Photos may use significant data. Manual commits ask for confirmation when mobile data is allowed.',
            ),
            value: settings.syncOverMobileData,
            onChanged: disabled
                ? null
                : (value) =>
                      _change(() => notifier.setSyncOverMobileData(value)),
          ),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  _message!,
                  style: _failed
                      ? Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        )
                      : Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
