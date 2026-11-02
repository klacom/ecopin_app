import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kRouteCardCollapsed = 'fc_route_card_collapsed';

/// Whether the Route screen's next-job card is minimized, remembered on this
/// device so a crew member who prefers the map keeps it.
class FcRouteCardNotifier extends Notifier<bool> {
  FcRouteCardNotifier({Future<SharedPreferences> Function()? preferences})
    : _preferences = preferences ?? SharedPreferences.getInstance;
  final Future<SharedPreferences> Function() _preferences;
  bool _chosen = false;

  @override
  bool build() {
    Future.microtask(_load);
    return false;
  }

  Future<void> _load() async {
    try {
      final stored = (await _preferences()).getBool(_kRouteCardCollapsed);
      if (!ref.mounted || _chosen) return;
      state = stored ?? false;
    } catch (error) {
      debugPrint('[ROUTE] Saved card state unavailable: $error');
    }
  }

  /// Applies the choice immediately; failing to remember it only means the
  /// next launch starts with the card open.
  Future<void> set(bool collapsed) async {
    _chosen = true;
    state = collapsed;
    try {
      await (await _preferences()).setBool(_kRouteCardCollapsed, collapsed);
    } catch (error) {
      debugPrint('[ROUTE] Could not save card state: $error');
    }
  }
}

final fcRouteCardCollapsedProvider =
    NotifierProvider<FcRouteCardNotifier, bool>(FcRouteCardNotifier.new);
