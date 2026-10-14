import 'package:ecopin_app/features/field_crew/sync/fc_sync_settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SyntheticSyncPreferences extends Fake implements SharedPreferences {
  bool writable = false;
  final values = <String, Object>{
    'fc_sync_mode': FcSyncMode.manualCommit.index,
  };
  @override
  int? getInt(String key) => values[key] as int?;
  @override
  bool? getBool(String key) => values[key] as bool?;
  @override
  Future<bool> setInt(String key, int value) async {
    if (writable) values[key] = value;
    return writable;
  }

  @override
  Future<bool> setBool(String key, bool value) async {
    if (writable) values[key] = value;
    return writable;
  }
}

void main() {
  test(
    'settings only change after storage confirms the existing keys were saved',
    () async {
      final prefs = SyntheticSyncPreferences();
      final container = ProviderContainer(
        overrides: [
          fcSyncSettingsProvider.overrideWith(
            () => FcSyncSettingsNotifier(preferences: () async => prefs),
          ),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(fcSyncSettingsProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      await expectLater(
        notifier.setMode(FcSyncMode.offlineOnly),
        throwsStateError,
      );
      expect(
        container.read(fcSyncSettingsProvider).mode,
        FcSyncMode.manualCommit,
      );
      await expectLater(notifier.setSyncOverMobileData(true), throwsStateError);
      expect(container.read(fcSyncSettingsProvider).syncOverMobileData, false);
      prefs.writable = true;
      await notifier.setMode(FcSyncMode.offlineOnly);
      await notifier.setSyncOverMobileData(true);
      await notifier.setSyncOverWifi(false);
      expect(prefs.values, {
        'fc_sync_mode': FcSyncMode.offlineOnly.index,
        'fc_sync_over_mobile': true,
        'fc_sync_over_wifi': false,
      });
      expect(
        container.read(fcSyncSettingsProvider).mode,
        FcSyncMode.offlineOnly,
      );
    },
  );
}
