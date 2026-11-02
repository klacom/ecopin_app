import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_gate.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_settings.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_trigger.dart';
import 'package:ecopin_app/features/field_crew/providers/fc_local_repository_provider.dart';
import 'package:ecopin_app/shared/widgets/app_button.dart';
import '../controllers/fc_sync_center_presentation.dart';
import '../controllers/fc_sync_ui_providers.dart';
import '../widgets/fc_offline_ui.dart';
import '../widgets/fc_sync_status_card.dart';
import '../widgets/fc_sync_preferences_card.dart';
import '../widgets/fc_sync_failure_card.dart';
import '../widgets/fc_sync_section.dart';
import '../widgets/fc_conflict_summary.dart';

/// “Send your work”: one status card that says what to do now, then the items
/// that need attention, then three closed rows for the details.
class FieldCrewSyncCenterScreen extends ConsumerStatefulWidget {
  const FieldCrewSyncCenterScreen({super.key});
  @override
  ConsumerState<FieldCrewSyncCenterScreen> createState() =>
      _FieldCrewSyncCenterScreenState();
}

class _FieldCrewSyncCenterScreenState
    extends ConsumerState<FieldCrewSyncCenterScreen> {
  bool _committing = false, _resetting = false, _failed = false;
  bool _showAllFailures = false;
  bool _waitingOpen = false, _lastOpen = false, _settingsOpen = false;
  final _settingsKey = GlobalKey();
  String? _message;

  /// Opens “How your work is sent” and brings it into view.
  void _openSettings() {
    setState(() => _settingsOpen = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _settingsKey.currentContext;
      if (target != null && target.mounted) {
        Scrollable.ensureVisible(
          target,
          duration: MediaQuery.disableAnimationsOf(target)
              ? Duration.zero
              : const Duration(milliseconds: 250),
        );
      }
    });
  }

  Future<void> _refresh() async {
    ref.invalidate(fcSyncNetworkProvider);
    try {
      ref.invalidate(fcPendingSummaryProvider);
      await ref.read(fcPendingSummaryProvider.future);
    } catch (_) {
      /* The status card shows the failure and offers Check again. */
    }
  }

  String _mobileDialogText(FcPendingSummary? summary) {
    if (summary == null) {
      return 'This sends your work using mobile data. Your plan may charge you.';
    }
    final parts = [
      if (summary.mutationCount > 0)
        '${summary.mutationCount} ${summary.mutationCount == 1 ? 'update' : 'updates'}',
      if (summary.photoCount > 0)
        '${summary.photoCount} ${summary.photoCount == 1 ? 'photo' : 'photos'}',
      if (summary.pendingDeleteCount > 0)
        '${summary.pendingDeleteCount} photo ${summary.pendingDeleteCount == 1 ? 'removal' : 'removals'}',
    ];
    final size = summary.estimatedBytes > 0
        ? ' (photos are about ${summary.formattedSize})'
        : '';
    return 'This sends ${parts.isEmpty ? 'your work' : parts.join(', ')}$size using mobile data. Your plan may charge you.';
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
              'Sending is not allowed on this connection right now. Check how your work is sent.';
          _failed = true;
        });
        return;
      }
      if (decision.requiresConfirmation) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            scrollable: true,
            title: const Text('Send using mobile data?'),
            content: Text(
              _mobileDialogText(ref.read(fcPendingSummaryProvider).value),
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
              'Sending did not start. Check your connection and how your work is sent.';
          _failed = true;
        });
      }
      await _refresh();
    } catch (_) {
      if (mounted) {
        setState(() {
          _message =
              'Sending could not start. Your work is still saved on this phone. Try again.';
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
        _message = 'Photos can try again. They have not been sent yet.';
        _failed = false;
      });
      await _refresh();
    } catch (_) {
      if (mounted) {
        setState(() {
          _message =
              'Could not allow another try for the photos. Nothing was sent. Try again.';
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
              'Updates can try again. They have not been sent yet. Tap Send now.';
          _failed = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _message =
              'Could not allow another try. Your work is still saved on this phone.';
          _failed = true;
        });
      }
    } finally {
      if (mounted) setState(() => _resetting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
    final queued = failures.value ?? const <FcQueuedFailure>[];
    final status = fcSendStatus(
      state: state,
      settings: settings,
      summary: summary,
      queueFailed: pending.hasError,
      network: network.hasError ? null : network.value,
      networkLoading: network.isLoading,
      networkFailed: network.hasError,
      failureCount: queued.length,
      busy: busy,
    );
    final waiting = fcWaitingCount(summary);
    final shown = _showAllFailures ? queued : queued.take(3).toList();
    final canResetUpdates = queued.any((f) => f.canResetTransport);
    final canResetPhotos = (summary?.failedPhotoCount ?? 0) > 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Send your work')),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                FcSyncStatusCard(
                  status: status,
                  onAction: switch (status.action) {
                    FcSendAction.send => _commit,
                    FcSendAction.checkAgain => () {
                      ref.invalidate(fcSyncNetworkProvider);
                      _refresh();
                    },
                    FcSendAction.changeSettings => _openSettings,
                    FcSendAction.none => null,
                  },
                ),
                if (_message != null)
                  FcOfflineNotice(message: _message!, error: _failed),
                if (failures.hasError)
                  FcOfflineNotice(
                    message:
                        'The list of items that did not send could not load.',
                    action: TextButton(
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                      onPressed: () => ref.invalidate(fcQueuedFailuresProvider),
                      child: const Text('Try again'),
                    ),
                  ),
                if (queued.isNotEmpty || canResetPhotos) ...[
                  Text('Needs attention', style: theme.textTheme.titleMedium),
                  for (final failure in shown)
                    FcSyncFailureCard(failure: failure),
                  if (queued.isEmpty && canResetPhotos)
                    Text(
                      '${summary!.failedPhotoCount} ${summary.failedPhotoCount == 1 ? 'photo is' : 'photos are'} on hold after a failed try.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  if (queued.length > shown.length)
                    TextButton(
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                      onPressed: () => setState(() => _showAllFailures = true),
                      child: Text('Show ${queued.length - shown.length} more'),
                    ),
                  if (canResetUpdates)
                    AppButton(
                      text: 'Allow another try for updates',
                      variant: ButtonVariant.secondary,
                      onPressed: busy ? null : _resetChangeRetries,
                    ),
                  if (canResetPhotos)
                    AppButton(
                      text: 'Allow another try for photos',
                      variant: ButtonVariant.secondary,
                      isLoading: _resetting,
                      onPressed: busy ? null : _resetPhotoRetries,
                    ),
                  if (canResetUpdates || canResetPhotos)
                    Text(
                      'This lets the phone try again. It does not mean anything was sent.',
                      style: theme.textTheme.bodySmall,
                    ),
                ],
                const FcConflictSummary(),
                FcOfflineCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FcSyncSection(
                        icon: Icons.list_alt_outlined,
                        title: 'What is waiting',
                        summary: summary == null
                            ? 'Not checked yet'
                            : waiting == 0
                            ? 'Nothing'
                            : fcItemCount(waiting),
                        open: _waitingOpen,
                        onToggle: () =>
                            setState(() => _waitingOpen = !_waitingOpen),
                        child: _WaitingDetails(summary: summary),
                      ),
                      const Divider(height: 1),
                      FcSyncSection(
                        icon: Icons.history,
                        title: 'Last send',
                        summary: state.lastSyncAt == null
                            ? 'None yet'
                            : fcShortTime(state.lastSyncAt!),
                        open: _lastOpen,
                        onToggle: () => setState(() => _lastOpen = !_lastOpen),
                        child: FcLastSendDetails(state: state),
                      ),
                      const Divider(height: 1),
                      KeyedSubtree(
                        key: _settingsKey,
                        child: FcSyncSection(
                          icon: Icons.settings_outlined,
                          title: 'How your work is sent',
                          summary: fcSendingSummary(settings),
                          open: _settingsOpen,
                          onToggle: () =>
                              setState(() => _settingsOpen = !_settingsOpen),
                          child: FcSyncPreferences(locked: busy),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The counts behind “N items waiting”, with the zero rows left out.
class _WaitingDetails extends StatelessWidget {
  const _WaitingDetails({required this.summary});
  final FcPendingSummary? summary;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final summary = this.summary;
    if (summary == null) {
      return Text('The counts are not available yet.', style: text.bodyMedium);
    }
    if (summary.isEmpty) {
      return Text('Nothing is waiting on this phone.', style: text.bodyMedium);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (summary.mutationCount > 0)
          FcOfflineFact(
            'Updates to jobs and reports',
            '${summary.mutationCount}',
          ),
        if (summary.photoCount > 0)
          FcOfflineFact('Photos to send', '${summary.photoCount}'),
        if (summary.pendingDeleteCount > 0)
          FcOfflineFact('Photos to remove', '${summary.pendingDeleteCount}'),
        if (summary.failedPhotoCount > 0)
          Text(
            '${summary.failedPhotoCount} of the photos ${summary.failedPhotoCount == 1 ? 'is' : 'are'} on hold after a failed try. See Needs attention.',
            style: text.bodySmall,
          ),
        if (summary.estimatedBytes > 0)
          FcOfflineFact('Photos are about', summary.formattedSize),
      ],
    );
  }
}
