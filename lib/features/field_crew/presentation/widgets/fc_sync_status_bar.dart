import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_gate.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_settings.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_trigger.dart';
import 'package:ecopin_app/routes/app_routes.dart';
import '../controllers/fc_sync_ui_providers.dart';

class FcSyncStatusBar extends ConsumerWidget {
  const FcSyncStatusBar({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(fcSyncStateProvider);
    final queue = ref.watch(fcPendingSummaryProvider);
    final network = ref.watch(fcSyncNetworkProvider);
    final settings = ref.watch(fcSyncSettingsProvider);
    ref.listen<FcSyncState>(fcSyncStateProvider, (previous, next) {
      if (previous?.phase == FcSyncPhase.syncing &&
          next.phase != FcSyncPhase.syncing) {
        ref.invalidate(fcPendingSummaryProvider);
      }
    });
    final count = queue.hasValue
        ? queue.value!.mutationCount +
              queue.value!.photoCount +
              queue.value!.pendingDeleteCount
        : null;
    final label = state.phase == FcSyncPhase.syncing
        ? 'Syncing queued work'
        : state.phase == FcSyncPhase.error ||
              state.phase == FcSyncPhase.partialFailure
        ? 'Sync needs attention'
        : queue.hasError
        ? 'Queue could not be checked'
        : queue.isLoading
        ? 'Checking local queue'
        : count == 0
        ? 'No queued crew work'
        : '$count ${count == 1 ? 'item' : 'items'} waiting to sync';
    final connection = network.hasError
        ? 'Connection unavailable'
        : network.isLoading
        ? 'Checking connection'
        : switch (network.value) {
            FcNetworkType.wifi => 'Wi-Fi',
            FcNetworkType.mobile => 'Mobile data',
            _ => 'No Wi-Fi or mobile connection',
          };
    final blocked =
        settings.syncBlocked ||
        network.value == FcNetworkType.none ||
        (network.value == FcNetworkType.wifi && !settings.syncOverWifi) ||
        (network.value == FcNetworkType.mobile && !settings.syncOverMobileData);
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.linkDark
            : AppColors.accent,
        side: BorderSide(
          color:
              Theme.of(context).dividerTheme.color ??
              Theme.of(context).dividerColor,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusCard),
        ),
      ),
      onPressed: () => context.push(FieldCrewAppRoutes.syncCenter),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Icon(
                state.phase == FcSyncPhase.syncing
                    ? Icons.sync
                    : state.phase == FcSyncPhase.error ||
                          state.phase == FcSyncPhase.partialFailure
                    ? Icons.sync_problem
                    : Icons.cloud_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$connection · ${settings.mode.title}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (queue.hasError && count != null)
                    Text(
                      'Last loaded count: $count. Open Sync Center to retry.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  if (blocked)
                    Text(
                      fcSyncPolicy(
                        settings,
                        network.hasError ? null : network.value,
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  const SizedBox(height: 4),
                  Text(
                    'Open Sync Center',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
