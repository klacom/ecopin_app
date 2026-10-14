import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_gate.dart';
import 'package:ecopin_app/features/field_crew/sync/fc_sync_settings.dart';

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

final fcPendingSummaryProvider = FutureProvider.autoDispose<FcPendingSummary>(
  (ref) => ref.watch(fcSyncGateProvider).getPendingSummary(),
);

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
