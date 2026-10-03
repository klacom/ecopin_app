import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/features/officer/presentation/screens/officer_analytics_reports_screen.dart';
import 'package:ecopin_app/features/officer/presentation/screens/officer_analytics_metrics_screen.dart';
import 'package:ecopin_app/features/officer/presentation/screens/officer_analytics_optimization_screen.dart';
import 'package:ecopin_app/features/officer/presentation/providers/nav_state_provider.dart';

class OfficerAnalyticsHubScreen extends ConsumerStatefulWidget {
  const OfficerAnalyticsHubScreen({super.key});

  @override
  ConsumerState<OfficerAnalyticsHubScreen> createState() => _OfficerAnalyticsHubScreenState();
}

class _OfficerAnalyticsHubScreenState extends ConsumerState<OfficerAnalyticsHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final initialIndex = ref.read(navStateProvider).analyticsHubLastTab;
    _tabController = TabController(length: 3, vsync: this, initialIndex: initialIndex);
    _tabController.addListener(_handleTabSelection);
  }

  void _handleTabSelection() {
    ref.read(navStateProvider.notifier).updateAnalyticsHubTab(_tabController.index);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          elevation: 2,
          child: TabBar(
            controller: _tabController,
            tabs: [
              Tab(child: Semantics(label: 'Reports tab', child: const Text('Reports'))),
              Tab(child: Semantics(label: 'Metrics tab', child: const Text('Metrics'))),
              Tab(child: Semantics(label: 'Optimization tab', child: const Text('Optimization'))),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              OfficerAnalyticsReportsScreen(),
              OfficerAnalyticsMetricsScreen(),
              OfficerAnalyticsOptimizationScreen(),
            ],
          ),
        ),
      ],
    );
  }
}
