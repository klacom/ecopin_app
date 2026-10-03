import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ecopin_app/routes/app_routes.dart';
import 'package:ecopin_app/features/officer/presentation/providers/nav_state_provider.dart';

const double largeScreenMinWidth = 600.0;

class OfficerScaffold extends ConsumerWidget {
  const OfficerScaffold({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  void _onItemTapped(int index, BuildContext context) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  String _getTitle(int index, WidgetRef ref) {
    final navState = ref.watch(navStateProvider);
    switch (index) {
      case 0:
        return 'Command Center';
      case 1:
        if (navState.intelHubLastTab == 0) return 'Hotzone Intel';
        if (navState.intelHubLastTab == 1) return 'Map Grid';
        if (navState.intelHubLastTab == 2) return 'Spatial Scan';
        return 'Intel Hub';
      case 2:
        return 'Operations';
      case 3:
        if (navState.analyticsHubLastTab == 0) return 'Reports';
        if (navState.analyticsHubLastTab == 1) return 'Metrics';
        if (navState.analyticsHubLastTab == 2) return 'Optimization';
        return 'Analytics Hub';
      default:
        return 'Ecopin Officer';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > largeScreenMinWidth) {
          return _buildLargeScreenLayout(context, ref);
        } else {
          return _buildSmallScreenLayout(context, ref);
        }
      },
    );
  }

  Widget _buildSmallScreenLayout(BuildContext context, WidgetRef ref) {
    final int currentIndex = navigationShell.currentIndex;
    final String title = _getTitle(currentIndex, ref);

    return Scaffold(
      appBar: AppBar(
        leading: Semantics(
          label: 'Ecopin App Logo',
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(Icons.eco), // Placeholder for AppLogo
          ),
        ),
        title: Semantics(
          header: true,
          child: Text(title),
        ),
        actions: [
          Semantics(
            label: 'Notifications',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {},
              tooltip: 'Notifications',
            ),
          ),
          Semantics(
            label: 'Officer Profile',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.account_circle),
              onPressed: () {
                context.push(OfficerAppRoutes.profile);
              },
              tooltip: 'Open profile',
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: navigationShell,
      bottomNavigationBar: Semantics(
        label: 'Bottom Navigation',
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) => _onItemTapped(index, context),
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: Semantics(label: 'Command Center tab', child: const Icon(Icons.home)),
              label: 'Command Center',
            ),
            BottomNavigationBarItem(
              icon: Semantics(label: 'Intel Hub tab', child: const Icon(Icons.satellite_alt)),
              label: 'Intel',
            ),
            BottomNavigationBarItem(
              icon: Semantics(label: 'Operations tab', child: const Icon(Icons.settings)),
              label: 'Ops',
            ),
            BottomNavigationBarItem(
              icon: Semantics(label: 'Analytics Hub tab', child: const Icon(Icons.bar_chart)),
              label: 'Analytics',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLargeScreenLayout(BuildContext context, WidgetRef ref) {
    final int currentIndex = navigationShell.currentIndex;
    final String title = _getTitle(currentIndex, ref);

    return Scaffold(
      appBar: AppBar(
        leading: Semantics(
          label: 'Ecopin App Logo',
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(Icons.eco), // Placeholder for AppLogo
          ),
        ),
        title: Semantics(
          header: true,
          child: Text(title),
        ),
        actions: [
          Semantics(
            label: 'Notifications',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {},
              tooltip: 'Notifications',
            ),
          ),
          Semantics(
            label: 'Officer Profile',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.account_circle),
              onPressed: () {
                context.push(OfficerAppRoutes.profile);
              },
              tooltip: 'Open profile',
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          Semantics(
            label: 'Side Navigation Rail',
            child: NavigationRail(
              selectedIndex: currentIndex,
              onDestinationSelected: (index) => _onItemTapped(index, context),
              labelType: NavigationRailLabelType.all,
              destinations: [
                NavigationRailDestination(
                  icon: Semantics(label: 'Command Center tab', child: const Icon(Icons.home)),
                  label: const Text('Command Center'),
                ),
                NavigationRailDestination(
                  icon: Semantics(label: 'Intel Hub tab', child: const Icon(Icons.satellite_alt)),
                  label: const Text('Intel'),
                ),
                NavigationRailDestination(
                  icon: Semantics(label: 'Operations tab', child: const Icon(Icons.settings)),
                  label: const Text('Ops'),
                ),
                NavigationRailDestination(
                  icon: Semantics(label: 'Analytics Hub tab', child: const Icon(Icons.bar_chart)),
                  label: const Text('Analytics'),
                ),
              ],
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}
