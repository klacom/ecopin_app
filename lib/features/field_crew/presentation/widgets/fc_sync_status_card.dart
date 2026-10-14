import 'package:flutter/material.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_gate.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_trigger.dart';
import 'fc_offline_ui.dart';

class FcSyncStatusCard extends StatelessWidget {
  const FcSyncStatusCard({
    super.key,
    required this.state,
    this.summary,
    required this.connection,
    required this.policy,
  });
  final FcSyncState state;
  final FcPendingSummary? summary;
  final String connection, policy;
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final phase = switch (state.phase) {
      FcSyncPhase.idle => 'Sync status',
      FcSyncPhase.syncing => 'Sync in progress',
      FcSyncPhase.success => 'Last sync attempt finished',
      FcSyncPhase.partialFailure => 'Some items need attention',
      FcSyncPhase.error => 'Sync could not finish',
    };
    return FcOfflineCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            liveRegion: true,
            child: Text(phase, style: text.titleMedium),
          ),
          if (state.phase == FcSyncPhase.syncing) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(semanticsLabel: 'Sync in progress'),
          ],
          const SizedBox(height: 12),
          if (summary == null)
            Text('Queue counts unavailable.', style: text.bodyMedium)
          else ...[
            Text(
              summary!.isEmpty
                  ? 'No local items waiting to sync.'
                  : 'Items waiting to sync',
              style: text.titleSmall,
            ),
            FcOfflineFact('Changes', '${summary!.mutationCount}'),
            FcOfflineFact('Photo uploads', '${summary!.photoCount}'),
            FcOfflineFact('Photo removals', '${summary!.pendingDeleteCount}'),
            if (summary!.failedPhotoCount > 0)
              Text(
                '${summary!.failedPhotoCount} photo uploads are paused after repeated failures. Reset their retries below.',
                style: text.bodyMedium,
              ),
            if (summary!.estimatedBytes > 0)
              FcOfflineFact(
                'Estimated photo upload size',
                summary!.formattedSize,
              ),
          ],
          const Divider(height: 32),
          FcOfflineFact('Connection', connection),
          Text(policy, style: text.bodyMedium),
          const SizedBox(height: 12),
          Text(
            state.lastSyncAt == null
                ? 'No completed sync attempt recorded in this session.'
                : 'Last result received: ${fcLocalTime(state.lastSyncAt!)}',
            style: text.bodySmall,
          ),
        ],
      ),
    );
  }
}

class FcLastSyncResultCard extends StatelessWidget {
  const FcLastSyncResultCard({super.key, required this.state});
  final FcSyncState state;
  @override
  Widget build(BuildContext context) {
    final changes = state.lastMutationResult, photos = state.lastPhotoResult;
    return FcOfflineCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Last received results',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          if (changes != null) ...[
            FcOfflineFact(
              'Changes acknowledged by the server',
              '${changes.succeeded}',
            ),
            FcOfflineFact('Merged changes', '${changes.merged}'),
            FcOfflineFact('Changes awaiting retry', '${changes.retryable}'),
            FcOfflineFact('Changes not applied', '${changes.permanent}'),
            if (changes.conflicted > 0)
              Text(
                '${changes.conflicted} review or conflict flags refer to changes in the totals above. See response updates for the instructions.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
          ],
          if (photos != null) ...[
            const Divider(height: 32),
            FcOfflineFact(
              'Photos uploaded',
              '${photos.uploadSucceeded} of ${photos.uploadAttempted} attempted',
            ),
            FcOfflineFact(
              'Photo uploads that failed',
              '${photos.uploadFailed}',
            ),
            FcOfflineFact(
              'Photo removals completed',
              '${photos.deleteSucceeded} of ${photos.deleteAttempted} attempted',
            ),
            FcOfflineFact(
              'Photo removals that failed',
              '${photos.deleteFailed}',
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'A server acknowledgement does not always close a report. Open the task for its current response status and instructions.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
