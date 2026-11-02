import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum FcSyncMode { automatic, manualCommit, offlineOnly }

extension FcSyncModeLabel on FcSyncMode {
  String get title => switch (this) {
    FcSyncMode.automatic => 'Send on its own',
    FcSyncMode.manualCommit => 'I will send it myself',
    FcSyncMode.offlineOnly => 'Pause sending',
  };

  String get description => switch (this) {
    FcSyncMode.automatic =>
      'Recommended. Your work sends when the signal is good.',
    FcSyncMode.manualCommit =>
      'Your work waits on this phone until you tap Send now.',
    FcSyncMode.offlineOnly =>
      'Nothing is sent. Your work stays on this phone.',
  };
}

class FcSyncSettings {
  final FcSyncMode mode;
  final bool syncOverWifi;
  final bool syncOverMobileData;

  const FcSyncSettings({
    this.mode = FcSyncMode.automatic,
    this.syncOverWifi = true,
    this.syncOverMobileData = false,
  });

  FcSyncSettings copyWith({
    FcSyncMode? mode,
    bool? syncOverWifi,
    bool? syncOverMobileData,
  }) => FcSyncSettings(
    mode: mode ?? this.mode,
    syncOverWifi: syncOverWifi ?? this.syncOverWifi,
    syncOverMobileData: syncOverMobileData ?? this.syncOverMobileData,
  );

  bool get autoSyncEnabled => mode == FcSyncMode.automatic;
  bool get syncBlocked => mode == FcSyncMode.offlineOnly;
}

const _kMode = 'fc_sync_mode';
const _kWifi = 'fc_sync_over_wifi';
const _kMobile = 'fc_sync_over_mobile';

class FcSyncSettingsNotifier extends Notifier<FcSyncSettings> {
  FcSyncSettingsNotifier({Future<SharedPreferences> Function()? preferences})
    : _preferences = preferences ?? SharedPreferences.getInstance;
  final Future<SharedPreferences> Function() _preferences;
  late Future<void> _initialLoad;
  @override
  FcSyncSettings build() {
    _initialLoad = Future.microtask(_load);
    return const FcSyncSettings();
  }

  Future<void> get ready => _initialLoad;

  Future<void> _load() async {
    final prefs = await _preferences();
    if (!ref.mounted) return;
    final idx = prefs.getInt(_kMode) ?? FcSyncMode.automatic.index;
    final wifi = prefs.getBool(_kWifi) ?? true;
    final mobile = prefs.getBool(_kMobile) ?? false;
    state = FcSyncSettings(
      mode: FcSyncMode.values[idx.clamp(0, FcSyncMode.values.length - 1)],
      syncOverWifi: wifi,
      syncOverMobileData: mobile,
    );
  }

  Future<void> setMode(FcSyncMode mode) async {
    await _initialLoad;
    final saved = await (await _preferences()).setInt(_kMode, mode.index);
    if (!saved) throw StateError('Sync preference could not save');
    if (!ref.mounted) return;
    state = state.copyWith(mode: mode);
  }

  Future<void> setSyncOverWifi(bool v) async {
    await _initialLoad;
    final saved = await (await _preferences()).setBool(_kWifi, v);
    if (!saved) throw StateError('Sync preference could not save');
    if (!ref.mounted) return;
    state = state.copyWith(syncOverWifi: v);
  }

  Future<void> setSyncOverMobileData(bool v) async {
    await _initialLoad;
    final saved = await (await _preferences()).setBool(_kMobile, v);
    if (!saved) throw StateError('Sync preference could not save');
    if (!ref.mounted) return;
    state = state.copyWith(syncOverMobileData: v);
  }
}

final fcSyncSettingsProvider =
    NotifierProvider<FcSyncSettingsNotifier, FcSyncSettings>(
      FcSyncSettingsNotifier.new,
    );
