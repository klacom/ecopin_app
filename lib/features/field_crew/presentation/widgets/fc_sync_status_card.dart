import 'package:flutter/material.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_trigger.dart';
import '../controllers/fc_sync_center_presentation.dart';
import 'fc_offline_ui.dart';
import 'fc_status_card.dart';

/// The send screen's status card: the shared [FcStatusCard] with this
/// screen's states and their colours.
class FcSyncStatusCard extends StatelessWidget {
  const FcSyncStatusCard({super.key, required this.status, this.onAction});

  final FcSendStatus status;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final tone = switch (status.kind) {
      FcSendKind.sent => FcStatusTone.success,
      FcSendKind.problem => FcStatusTone.error,
      FcSendKind.paused ||
      FcSendKind.noSignal ||
      FcSendKind.networkOff ||
      FcSendKind.couldNotCheck => FcStatusTone.warning,
      _ => FcStatusTone.accent,
    };
    return FcStatusCard(
      tone: tone,
      icon: status.icon,
      title: status.title,
      detail: status.detail,
      showProgress:
          status.kind == FcSendKind.sending ||
          status.kind == FcSendKind.checking,
      actionLabel: status.action == FcSendAction.none
          ? null
          : status.actionLabel,
      actionIcon: status.action == FcSendAction.send ? Icons.send : null,
      primary: status.action == FcSendAction.send,
      onAction: onAction,
    );
  }
}

/// What the last send did, in plain words. Zero counts are left out, so a clean
/// run reads as one short line.
class FcLastSendDetails extends StatelessWidget {
  const FcLastSendDetails({super.key, required this.state});
  final FcSyncState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final changes = state.lastMutationResult;
    final photos = state.lastPhotoResult;
    final facts = <(String, String)>[
      if (changes != null) ...[
        if (changes.succeeded > 0) ('Updates sent', '${changes.succeeded}'),
        if (changes.merged > 0)
          ('Updates combined with others', '${changes.merged}'),
        if (changes.retryable > 0)
          ('Updates that will try again', '${changes.retryable}'),
        if (changes.permanent > 0)
          ('Updates not accepted', '${changes.permanent}'),
      ],
      if (photos != null) ...[
        if (photos.uploadAttempted > 0)
          (
            'Photos sent',
            '${photos.uploadSucceeded} of ${photos.uploadAttempted}',
          ),
        if (photos.uploadFailed > 0)
          ('Photos that did not send', '${photos.uploadFailed}'),
        if (photos.uploadSkipped > 0)
          ('Photos on hold', '${photos.uploadSkipped}'),
        if (photos.deleteAttempted > 0)
          (
            'Photos removed',
            '${photos.deleteSucceeded} of ${photos.deleteAttempted}',
          ),
        if (photos.deleteFailed > 0)
          ('Photo removals that did not finish', '${photos.deleteFailed}'),
      ],
    ];
    final flagged = changes?.conflicted ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          state.lastSyncAt == null
              ? 'Nothing has been sent since you opened the app.'
              : 'Last send: ${fcLocalTime(state.lastSyncAt!)}',
          style: theme.textTheme.bodySmall,
        ),
        if (state.lastSyncAt != null && facts.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Nothing was sent in that run.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        for (final (label, value) in facts) FcOfflineFact(label, value),
        if (flagged > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '$flagged ${flagged == 1 ? 'update was' : 'updates were'} flagged for review. ${flagged == 1 ? 'It is' : 'They are'} already counted above.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        if (state.lastSyncAt != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'An update that was received does not always close a report. Open the job to see what to do next.',
              style: theme.textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}
