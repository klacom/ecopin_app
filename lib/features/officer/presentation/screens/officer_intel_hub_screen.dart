import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/features/officer/presentation/screens/officer_intel_hotzone_screen.dart';
import 'package:ecopin_app/features/officer/presentation/screens/officer_intel_map_grid_screen.dart';
import 'package:ecopin_app/features/officer/presentation/screens/officer_intel_spatial_scan_screen.dart';
import 'package:ecopin_app/features/officer/presentation/providers/nav_state_provider.dart';

class OfficerIntelHubScreen extends ConsumerStatefulWidget {
  const OfficerIntelHubScreen({super.key});

  @override
  ConsumerState<OfficerIntelHubScreen> createState() => _OfficerIntelHubScreenState();
}

class _OfficerIntelHubScreenState extends ConsumerState<OfficerIntelHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final initialIndex = ref.read(navStateProvider).intelHubLastTab;
    _tabController = TabController(length: 3, vsync: this, initialIndex: initialIndex);
    _tabController.addListener(_handleTabSelection);
  }

  void _handleTabSelection() {
    ref.read(navStateProvider.notifier).updateIntelHubTab(_tabController.index);
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
              Tab(child: Semantics(label: 'Hotzone Intel tab', child: const Text('Hotzone Intel'))),
              Tab(child: Semantics(label: 'Map Grid tab', child: const Text('Map Grid'))),
              Tab(child: Semantics(label: 'Spatial Scan tab', child: const Text('Spatial Scan'))),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              OfficerIntelHotzoneScreen(),
              OfficerIntelMapGridScreen(),
              OfficerIntelSpatialScanScreen(),
            ],
          ),
        ),
      ],
    );
  }
}
