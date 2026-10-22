import 'package:connectivity_plus/connectivity_plus.dart';
import '../../sync/fc_sync_trigger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_gate.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_settings.dart';
import 'package:ecopin_app/features/field_crew/providers/fc_local_repository_provider.dart';
import '../../sync/fc_sync_error.dart';

// Display the same network categories recognized by the existing sync gate.
FcNetworkType _network(List<ConnectivityResult> values) =>
    values.contains(ConnectivityResult.wifi)
    ? FcNetworkType.wifi
    : values.contains(ConnectivityResult.mobile)
    ? FcNetworkType.mobile
    : FcNetworkType.none;

final fcSyncNetworkProvider = StreamProvider.autoDispose<FcNetworkType>((
  ref,
) async* {
  final connectivity = Connectivity();
  yield _network(await connectivity.checkConnectivity());
  yield* connectivity.onConnectivityChanged.map(_network).distinct();
});

final fcPendingSummaryProvider = FutureProvider.autoDispose<FcPendingSummary>((
  ref,
) async {
  final gate = ref.watch(fcSyncGateProvider);
  await ref.watch(fcPendingWritesProvider.future);
  return gate.getPendingSummary();
});

class FcQueuedFailure {
  const FcQueuedFailure(
    this.label,
    this.entityId,
    this.reason,
    this.retries, {
    this.canResetTransport = false,
  });
  final String label, entityId, reason;
  final int retries;
  final bool canResetTransport;
}

final fcQueuedFailuresProvider =
    FutureProvider.autoDispose<List<FcQueuedFailure>>((ref) async {
      ref.watch(fcPendingSummaryProvider);
      final local = ref.watch(fcLocalRepositoryProvider);
      final photos = ref.watch(fcLocalPhotoRepositoryProvider);
      final issues = <FcQueuedFailure>[];
      for (final item in await local.getAllOutboxItems()) {
        if (item.operationType.startsWith('fc.photo.') ||
            item.lastError == null) {
          continue;
        }
        issues.add(
          FcQueuedFailure(
            item.operationType == 'fc.note.add'
                ? 'Response log'
                : 'Report or task update',
            item.entityId,
            item.lastError!,
            item.retryCount,
            canResetTransport:
                item.retryCount >= 5 &&
                fcCanResetTransportError(item.lastError!),
          ),
        );
      }
      for (final photo in [
        ...await photos.getPendingUploads(),
        ...await photos.getPendingDeletes(),
      ]) {
        if (photo.lastError == null) continue;
        issues.add(
          FcQueuedFailure(
            '${photo.photoType == 'before' ? 'Before' : 'After'} photo',
            photo.entityId,
            photo.lastError!,
            photo.retryCount,
          ),
        );
      }
      return issues;
    });

String fcSyncPolicy(FcSyncSettings settings, FcNetworkType? network) {
  if (settings.mode == FcSyncMode.offlineOnly) {
    return 'Offline Only pauses syncing. Change mode below before committing queued work.';
  }
  if (network == null) {
    return 'Connection status is unavailable. Check the connection before committing.';
  }
  if (network == FcNetworkType.none) {
    return 'Waiting for a Wi-Fi or mobile connection. Local queued work stays on this device.';
  }
  if (network == FcNetworkType.wifi && !settings.syncOverWifi) {
    return 'Wi-Fi sync is disabled. Enable it below or use allowed mobile data.';
  }
  if (network == FcNetworkType.mobile && !settings.syncOverMobileData) {
    return 'Mobile data sync is disabled. Use Wi-Fi or enable mobile data below.';
  }
  return settings.mode == FcSyncMode.manualCommit
      ? 'Manual Commit is selected. Choose Commit changes to upload queued work on this allowed connection.'
      : 'Automatic sync is enabled on this connection. Queued work uploads when the sync service runs.';
}
