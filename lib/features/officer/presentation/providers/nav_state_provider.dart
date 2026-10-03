import 'package:flutter_riverpod/flutter_riverpod.dart';

class NavState {
  final int intelHubLastTab;
  final int analyticsHubLastTab;

  NavState({
    this.intelHubLastTab = 0,
    this.analyticsHubLastTab = 0,
  });

  NavState copyWith({
    int? intelHubLastTab,
    int? analyticsHubLastTab,
  }) {
    return NavState(
      intelHubLastTab: intelHubLastTab ?? this.intelHubLastTab,
      analyticsHubLastTab: analyticsHubLastTab ?? this.analyticsHubLastTab,
    );
  }
}

class NavStateNotifier extends Notifier<NavState> {
  @override
  NavState build() => NavState();

  void updateIntelHubTab(int index) {
    if (state.intelHubLastTab != index) {
      Future.microtask(() {
        state = state.copyWith(intelHubLastTab: index);
      });
    }
  }

  void updateAnalyticsHubTab(int index) {
    if (state.analyticsHubLastTab != index) {
      Future.microtask(() {
        state = state.copyWith(analyticsHubLastTab: index);
      });
    }
  }
}

final navStateProvider = NotifierProvider<NavStateNotifier, NavState>(NavStateNotifier.new);
