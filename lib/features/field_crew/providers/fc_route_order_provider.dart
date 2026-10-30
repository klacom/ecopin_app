import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecopin_app/features/field_crew/presentation/controllers/fc_route_order.dart';

const _kRouteOrder = 'fc_route_order';

/// The crew's chosen route ordering, remembered on this device.
class FcRouteOrderNotifier extends Notifier<CrewRouteOrder> {
  FcRouteOrderNotifier({Future<SharedPreferences> Function()? preferences})
    : _preferences = preferences ?? SharedPreferences.getInstance;
  final Future<SharedPreferences> Function() _preferences;
  bool _chosen = false;

  @override
  CrewRouteOrder build() {
    Future.microtask(_load);
    return CrewRouteOrder.priority;
  }

  Future<void> _load() async {
    try {
      final stored = (await _preferences()).getString(_kRouteOrder);
      // A choice made while this was loading wins over the stored value.
      if (!ref.mounted || _chosen) return;
      state = CrewRouteOrder.values.firstWhere(
        (order) => order.name == stored,
        orElse: () => CrewRouteOrder.priority,
      );
    } catch (error) {
      debugPrint('[ROUTE] Saved route order unavailable: $error');
    }
  }

  /// Applies the choice immediately; failing to remember it only means the
  /// next launch starts from Priority again.
  Future<void> select(CrewRouteOrder order) async {
    _chosen = true;
    state = order;
    try {
      await (await _preferences()).setString(_kRouteOrder, order.name);
    } catch (error) {
      debugPrint('[ROUTE] Could not save route order: $error');
    }
  }
}

final fcRouteOrderProvider =
    NotifierProvider<FcRouteOrderNotifier, CrewRouteOrder>(
      FcRouteOrderNotifier.new,
    );
