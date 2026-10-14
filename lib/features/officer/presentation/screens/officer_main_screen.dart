import 'package:flutter/material.dart';
import 'package:ecopin_app/routes/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/shared/profile/providers/profile_provider.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/shared/widgets/app_navigation_bar.dart';

class OfficerMainScreen extends ConsumerStatefulWidget {
  final Widget child;
  const OfficerMainScreen({super.key, required this.child});

  @override
  ConsumerState<OfficerMainScreen> createState() => _OfficerMainScreenState();
}

class _OfficerMainScreenState extends ConsumerState<OfficerMainScreen> {
  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(OfficerAppRoutes.dashboard)) return 0;
    if (location.startsWith(OfficerAppRoutes.clusters)) return 1;
    if (location.startsWith(OfficerAppRoutes.cleanupTasks)) return 2;
    if (location.startsWith(OfficerAppRoutes.reports)) return 3;
    // Secondary destinations remain associated with More.
    return 4;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(OfficerAppRoutes.dashboard);
        break;
      case 1:
        context.go(OfficerAppRoutes.clusters);
        break;
      case 2:
        context.go(OfficerAppRoutes.cleanupTasks);
        break;
      case 3:
        context.go(OfficerAppRoutes.reports);
        break;
      case 4:
        _showMoreMenu(context);
        break;
    }
  }

  void _showMoreMenu(BuildContext context) {
    final profile = ref.read(profileProvider).value;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              header: true,
              child: Text(
                'Officer tools',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 16),
            for (final item in [
              (Icons.map_outlined, 'Map', OfficerAppRoutes.maps),
              (Icons.radar, 'Spatial scan', OfficerAppRoutes.spatialScan),
              (
                Icons.analytics_outlined,
                'Analytics',
                OfficerAppRoutes.analytics,
              ),
              (
                Icons.route_outlined,
                'Dispatch planning',
                OfficerAppRoutes.optimization,
              ),
              (
                Icons.groups_outlined,
                'Crew management',
                OfficerAppRoutes.crewManagement,
              ),
              (Icons.history, 'Response logs', OfficerAppRoutes.responseLogs),
            ])
              ListTile(
                leading: Icon(item.$1),
                title: Text(item.$2),
                selected: GoRouterState.of(
                  context,
                ).matchedLocation.startsWith(item.$3),
                selectedColor: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.linkDark
                    : AppColors.accent,
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.go(item.$3);
                },
              ),
            ListTile(
              leading: AppNavAvatar(source: profile?['avatar_url'] as String?),
              title: const Text('Account'),
              subtitle: profile?['full_name'] == null
                  ? null
                  : Text(profile!['full_name'].toString()),
              onTap: () {
                Navigator.pop(sheetContext);
                context.go(OfficerAppRoutes.profile);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: widget.child,
    bottomNavigationBar: AppNavigationBar(
      selectedIndex: _calculateSelectedIndex(context),
      onSelected: (index) => _onItemTapped(index, context),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.group_work_outlined),
          selectedIcon: Icon(Icons.group_work),
          label: 'Clusters',
        ),
        NavigationDestination(
          icon: Icon(Icons.task_outlined),
          selectedIcon: Icon(Icons.task),
          label: 'Tasks',
        ),
        NavigationDestination(
          icon: Icon(Icons.description_outlined),
          selectedIcon: Icon(Icons.description),
          label: 'Reports',
        ),
        NavigationDestination(icon: Icon(Icons.more_horiz), label: 'More'),
      ],
    ),
  );
}
