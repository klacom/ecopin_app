import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/features/field_crew/offline/fc_offline_package.dart';
import 'package:ecopin_app/features/field_crew/offline/fc_offline_package_notifier.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_settings.dart';
import 'package:ecopin_app/shared/widgets/app_button.dart';
import '../widgets/fc_offline_ui.dart';
import '../widgets/fc_offline_package_details.dart';

class FieldCrewPrepareOfflineScreen extends ConsumerStatefulWidget {
  const FieldCrewPrepareOfflineScreen({super.key});
  @override
  ConsumerState<FieldCrewPrepareOfflineScreen> createState() =>
      _FieldCrewPrepareOfflineScreenState();
}

class _FieldCrewPrepareOfflineScreenState
    extends ConsumerState<FieldCrewPrepareOfflineScreen> {
  bool _savingMode = false;
  String? _modeError;
  Future<void> _pauseSync() async {
    if (_savingMode) return;
    setState(() {
      _savingMode = true;
      _modeError = null;
    });
    try {
      await ref
          .read(fcSyncSettingsProvider.notifier)
          .setMode(FcSyncMode.offlineOnly);
    } catch (_) {
      if (mounted) {
        setState(
          () => _modeError =
              'Sync mode could not save. Your previous preference remains. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _savingMode = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final package = ref.watch(fcOfflinePackageNotifierProvider);
    final settings = ref.watch(fcSyncSettingsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Prepare offline')),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 20,
            children: [
              FcOfflineCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Take assigned work into the field',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Prepare your assigned tasks, linked reports, evidence metadata, notes, and available route records while connected.',
                    ),
                    const SizedBox(height: 12),
                    Text(
                    'This downloads record information. Full-size evidence photos, reference lists, and map tiles may still need a connection. Review each preparation step before leaving.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Preparation starts a separate download when you choose it, including in Offline Only sync mode. Network preferences for queued uploads do not limit this download.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              FcOfflinePackageDetails(state: package),
              if (package.errorMessage != null)
                FcOfflineNotice(error: true, message: package.errorMessage!),
              AppButton(
                text: package.isReady
                    ? 'Update offline package'
                    : package.phase == FcOfflinePackagePhase.failed
                    ? 'Try preparation again'
                    : 'Prepare assigned work',
                isLoading: package.isDownloading,
                onPressed: package.isDownloading || _savingMode
                    ? null
                    : () => ref
                          .read(fcOfflinePackageNotifierProvider.notifier)
                          .prepare(),
              ),
              Text(
                'Updating preparation refreshes cached records. It does not commit queued changes or confirm that reports are complete.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (package.isReady)
                FcOfflineCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Queued sync preference',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        settings.mode == FcSyncMode.offlineOnly
                            ? 'Offline Only is enabled. Queued work stays on this device until you change mode and sync on an allowed connection.'
                            : 'You can pause queued syncing for field work. Offline Only pauses sync, not the device connection or explicit preparation downloads.',
                      ),
                      if (settings.mode != FcSyncMode.offlineOnly) ...[
                        const SizedBox(height: 16),
                        AppButton(
                          text: 'Enable Offline Only',
                          variant: ButtonVariant.secondary,
                          isLoading: _savingMode,
                          onPressed: package.isDownloading || _savingMode
                              ? null
                              : _pauseSync,
                        ),
                      ],
                      if (_modeError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Semantics(
                            liveRegion: true,
                            child: Text(
                              _modeError!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
