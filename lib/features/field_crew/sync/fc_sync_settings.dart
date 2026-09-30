import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum FcSyncMode { automatic, manualCommit, offlineOnly }

extension FcSyncModeLabel on FcSyncMode {
  String get title => switch (this) {
        FcSyncMode.automatic    => 'Automatic Sync',
        FcSyncMode.manualCommit => 'Manual Commit',
        FcSyncMode.offlineOnly  => 'Offline Only',
      };

  String get description => switch (this) {
        FcSyncMode.automatic =>
          'Pending work uploads automatically when a suitable network is available.',
        FcSyncMode.manualCommit =>
          'Changes are saved locally and only uploaded when you tap "Commit Changes".',
        FcSyncMode.offlineOnly =>
          'No uploads or downloads until you change this setting or commit manually.',
      };
}

class FcSyncSettings {
  final FcSyncMode mode;
  final bool syncOverWifi;
  final bool syncOverMobileData;

  const FcSyncSettings({
    this.mode               = FcSyncMode.automatic,
    this.syncOverWifi       = true,
    this.syncOverMobileData = false,
  });

  FcSyncSettings copyWith({FcSyncMode? mode, bool? syncOverWifi, bool? syncOverMobileData}) =>
      FcSyncSettings(
        mode:               mode               ?? this.mode,
        syncOverWifi:       syncOverWifi       ?? this.syncOverWifi,
        syncOverMobileData: syncOverMobileData ?? this.syncOverMobileData,
      );

  bool get autoSyncEnabled => mode == FcSyncMode.automatic;
  bool get syncBlocked     => mode == FcSyncMode.offlineOnly;
}

const _kMode   = 'fc_sync_mode';
const _kWifi   = 'fc_sync_over_wifi';
const _kMobile = 'fc_sync_over_mobile';

class FcSyncSettingsNotifier extends Notifier<FcSyncSettings> {
  @override
  FcSyncSettings build() {
    Future.microtask(_load);
    return const FcSyncSettings();
  }

  Future<void> _load() async {
    final prefs  = await SharedPreferences.getInstance();
    final idx    = prefs.getInt(_kMode)    ?? FcSyncMode.automatic.index;
    final wifi   = prefs.getBool(_kWifi)   ?? true;
    final mobile = prefs.getBool(_kMobile) ?? false;
    state = FcSyncSettings(
      mode:               FcSyncMode.values[idx.clamp(0, FcSyncMode.values.length - 1)],
      syncOverWifi:       wifi,
      syncOverMobileData: mobile,
    );
  }

  Future<void> setMode(FcSyncMode mode) async {
    state = state.copyWith(mode: mode);
    (await SharedPreferences.getInstance()).setInt(_kMode, mode.index);
  }

  Future<void> setSyncOverWifi(bool v) async {
    state = state.copyWith(syncOverWifi: v);
    (await SharedPreferences.getInstance()).setBool(_kWifi, v);
  }

  Future<void> setSyncOverMobileData(bool v) async {
    state = state.copyWith(syncOverMobileData: v);
    (await SharedPreferences.getInstance()).setBool(_kMobile, v);
  }
}

final fcSyncSettingsProvider =
    NotifierProvider<FcSyncSettingsNotifier, FcSyncSettings>(FcSyncSettingsNotifier.new);
