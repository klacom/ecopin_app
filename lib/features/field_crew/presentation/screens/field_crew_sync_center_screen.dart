import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_gate.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_settings.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_trigger.dart';
import 'package:ecopin_app/features/field_crew/providers/fc_local_repository_provider.dart';
import 'package:ecopin_app/shared/widgets/app_button.dart';
import '../controllers/fc_sync_ui_providers.dart';
import '../widgets/fc_offline_ui.dart';
import '../widgets/fc_sync_status_card.dart';
import '../widgets/fc_sync_preferences_card.dart';
import '../widgets/fc_conflict_summary.dart';

class FieldCrewSyncCenterScreen extends ConsumerStatefulWidget {
  const FieldCrewSyncCenterScreen({super.key});
  @override
  ConsumerState<FieldCrewSyncCenterScreen> createState() =>
      _FieldCrewSyncCenterScreenState();
}

class _FieldCrewSyncCenterScreenState
    extends ConsumerState<FieldCrewSyncCenterScreen> {
  bool _committing = false, _resetting = false, _failed = false;
  String? _message;

  Future<void> _refresh() async {
    ref.invalidate(fcSyncNetworkProvider);
    try {
      ref.invalidate(fcPendingSummaryProvider);
      await ref.read(fcPendingSummaryProvider.future);
    } catch (_) {
      /* The provider displays its error and retry action. */
    }
  }

  Future<void> _commit() async {
    if (_committing ||
        _resetting ||
        ref.read(fcSyncStateProvider).phase == FcSyncPhase.syncing) {
      return;
    }
    setState(() {
      _committing = true;
      _message = null;
    });
    try {
      final gate = ref.read(fcSyncGateProvider);
      final trigger = ref.read(fcSyncTriggerProvider);
      final decision = await gate.checkManualCommit();
      if (!mounted) return;
      if (!decision.allowed) {
        setState(() {
          _message =
              decision.reason ?? 'Sync is not allowed on this connection.';
          _failed = true;
        });
        return;
      }
      if (decision.requiresConfirmation) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            scrollable: true,
            title: const Text('Use mobile data?'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'This commit will upload queued changes and photos using mobile data. Data charges may apply.',
                ),
                if (ref.read(fcPendingSummaryProvider).value
                    case final summary?) ...[
                  const SizedBox(height: 12),
                  Text(
                    '${summary.mutationCount} changes, ${summary.photoCount} photo uploads, and ${summary.pendingDeleteCount} photo removals.',
                  ),
                  if (summary.estimatedBytes > 0)
                    Text(
                      'Estimated photo upload size: ${summary.formattedSize}.',
                    ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Use mobile data'),
              ),
            ],
          ),
        );
        if (confirmed != true || !mounted) return;
      }
      final result = await trigger.manualCommit();
      if (!mounted) return;
      if (result == null) {
        setState(() {
          _message =
              'The sync did not start. Check the current connection, preferences, and sync status.';
          _failed = true;
        });
      }
      await _refresh();
    } catch (_) {
      if (mounted) {
        setState(() {
          _message =
              'Sync could not start. Queued work remains on this device. Please try again.';
          _failed = true;
        });
      }
    } finally {
      if (mounted) setState(() => _committing = false);
    }
  }

  Future<void> _resetPhotoRetries() async {
    if (_resetting ||
        _committing ||
        ref.read(fcSyncStateProvider).phase == FcSyncPhase.syncing) {
      return;
    }
    setState(() {
      _resetting = true;
      _message = null;
    });
    try {
      await ref.read(fcLocalPhotoRepositoryProvider).resetFailedPhotoRetries();
      if (!mounted) return;
      setState(() {
        _message =
            'Photo retries reset. The photos remain queued until a sync runs on an allowed connection.';
        _failed = false;
      });
      await _refresh();
    } catch (_) {
      if (mounted) {
        setState(() {
          _message =
              'Photo retries could not reset. No upload has been confirmed. Please try again.';
          _failed = true;
        });
      }
    } finally {
      if (mounted) setState(() => _resetting = false);
    }
  }

  Future<void> _resetChangeRetries() async {
    setState(() => _resetting = true);
    try {
      await ref.read(fcLocalRepositoryProvider).resetTransportRetries();
      await _refresh();
      if (mounted) {
        setState(() {
          _message =
              'Connection failure retries reset. Choose Commit changes to try again. Rejected updates remain unchanged.';
          _failed = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _message =
              'Retries could not reset. Your queued changes remain on this device.';
          _failed = true;
        });
      }
    } finally {
      if (mounted) setState(() => _resetting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(fcSyncStateProvider);
    final settings = ref.watch(fcSyncSettingsProvider);
    final network = ref.watch(fcSyncNetworkProvider);
    final pending = ref.watch(fcPendingSummaryProvider);
    final failures = ref.watch(fcQueuedFailuresProvider);
    final summary = pending.value;
    final busy =
        state.phase == FcSyncPhase.syncing || _committing || _resetting;
    ref.listen<FcSyncState>(fcSyncStateProvider, (previous, next) {
      if (previous?.phase == FcSyncPhase.syncing &&
          next.phase != FcSyncPhase.syncing) {
        ref.invalidate(fcPendingSummaryProvider);
      }
    });
    final connection = network.isLoading
        ? 'Checking connection…'
        : network.hasError
        ? 'Connection could not be checked'
        : switch (network.value) {
            FcNetworkType.wifi => 'Wi-Fi',
            FcNetworkType.mobile => 'Mobile data',
            _ => 'No Wi-Fi or mobile connection detected',
          };
    final allowed =
        !network.isLoading &&
        !network.hasError &&
        switch (network.value) {
          FcNetworkType.wifi => settings.syncOverWifi,
          FcNetworkType.mobile => settings.syncOverMobileData,
          _ => false,
        };
    return Scaffold(
      appBar: AppBar(title: const Text('Sync Center')),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 20,
              children: [
                Text(
                  'Manage the work saved on this device and review what the server has received.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (pending.isLoading)
                  const LinearProgressIndicator(
                    semanticsLabel: 'Loading queued work',
                  ),
                if (pending.hasError)
                  FcOfflineNotice(
                    error: true,
                    message: pending.hasValue
                        ? 'Queue counts could not refresh. The last loaded counts remain below.'
                        : 'Queue counts could not load. Try again before committing work.',
                    action: TextButton(
                      onPressed: busy ? null : _refresh,
                      child: const Text('Retry queue counts'),
                    ),
                  ),
                if (network.hasError)
                  FcOfflineNotice(
                    error: true,
                    message: 'The connection could not be checked.',
                    action: TextButton(
                      onPressed: () => ref.invalidate(fcSyncNetworkProvider),
                      child: const Text('Check connection again'),
                    ),
                  ),
                FcSyncStatusCard(
                  state: state,
                  summary: summary,
                  connection: connection,
                  policy: fcSyncPolicy(
                    settings,
                    network.hasError ? null : network.value,
                  ),
                ),
                if (state.phase == FcSyncPhase.error)
                  FcOfflineNotice(
                    error: true,
                    message:
                        state.errorMessage ??
                        'The latest sync could not finish. Your queued work remains on this device.',
                  ),
                if (state.phase == FcSyncPhase.partialFailure)
                  const FcOfflineNotice(
                    message:
                        'Review the item failure reasons and response updates below. Any unsent work remains on this device.',
                  ),
                if (failures.hasError)
                  FcOfflineNotice(
                    message: 'Failure details could not load.',
                    action: TextButton(
                      onPressed: () => ref.invalidate(fcQueuedFailuresProvider),
                      child: const Text('Reload failure details'),
                    ),
                  ),
                for (final failure
                    in failures.value ?? const <FcQueuedFailure>[])
                  FcOfflineNotice(
                    error: true,
                    message:
                        '${failure.label}\nReport/task: ${failure.entityId}\n${failure.reason}\n${failure.attemptLabel}${failure.retriesPaused ? '\nAutomatic retries paused. Review the reason before resetting retries.' : ''}',
                  ),
                if ((failures.value ?? const <FcQueuedFailure>[]).any(
                  (f) => f.canResetTransport,
                ))
                  AppButton(
                    text: 'Reset connection failure retries',
                    variant: ButtonVariant.secondary,
                    onPressed: busy ? null : _resetChangeRetries,
                  ),
                if (_message != null)
                  FcOfflineNotice(message: _message!, error: _failed),
                if ((summary?.failedPhotoCount ?? 0) > 0)
                  AppButton(
                    text: 'Reset failed photo retries',
                    variant: ButtonVariant.secondary,
                    isLoading: _resetting,
                    onPressed: busy ? null : _resetPhotoRetries,
                  ),
                AppButton(
                  text: 'Commit changes',
                  isLoading: _committing || state.phase == FcSyncPhase.syncing,
                  onPressed:
                      busy ||
                          pending.isLoading ||
                          pending.hasError ||
                          summary == null ||
                          summary.isEmpty ||
                          settings.syncBlocked ||
                          !allowed
                      ? null
                      : _commit,
                ),
                if (state.lastMutationResult != null ||
                    state.lastPhotoResult != null)
                  FcLastSyncResultCard(state: state),
                const FcConflictSummary(),
                FcSyncPreferencesCard(locked: busy),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
