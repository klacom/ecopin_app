import 'package:ecopin_app/features/field_crew/sync/crew_heartbeat.dart';
import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/routes/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/shared/profile/providers/profile_provider.dart';
import 'package:ecopin_app/shared/widgets/app_navigation_bar.dart';

class FieldCrewMainScreen extends ConsumerStatefulWidget {
  final Widget child;
  const FieldCrewMainScreen({super.key, required this.child});

  @override
  ConsumerState<FieldCrewMainScreen> createState() =>
      _FieldCrewMainScreenState();
}

class _FieldCrewMainScreenState extends ConsumerState<FieldCrewMainScreen> {
  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(FieldCrewAppRoutes.dashboard)) return 0;
    if (location.startsWith(FieldCrewAppRoutes.map)) return 1;
    if (location.startsWith(FieldCrewAppRoutes.tasks)) return 2;
    if (location.startsWith(FieldCrewAppRoutes.reports)) return 3;
    if (location.startsWith(FieldCrewAppRoutes.profile)) return 4;
    return 0;
  }

  /// Returns true when the current route is a secondary/detail screen that
  /// should NOT display the bottom navigation bar.
  bool _isDetailRoute(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    // /field-crew/tasks/:id  (and any deeper nesting like /tasks/:id/reports/:reportId)
    final taskDetailPattern = RegExp(r'^/field-crew/tasks/[^/]+');
    // /field-crew/reports/:reportId
    final reportDetailPattern = RegExp(r'^/field-crew/reports/[^/]+');
    return taskDetailPattern.hasMatch(location) ||
        reportDetailPattern.hasMatch(location);
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(FieldCrewAppRoutes.dashboard);
        break;
      case 1:
        context.go(FieldCrewAppRoutes.map);
        break;
      case 2:
        context.go(FieldCrewAppRoutes.tasks);
        break;
      case 3:
        context.go(FieldCrewAppRoutes.reports);
        break;
      case 4:
        context.go(FieldCrewAppRoutes.profile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(crewHeartbeatProvider);
    final profile = ref.watch(profileProvider);
    final avatar = profile.value?['avatar_url'] as String?;
    final theme = Theme.of(context);
    final canvas = theme.brightness == Brightness.light
        ? AppColors.tabCanvasLight
        : theme.scaffoldBackgroundColor;
    return Scaffold(
      backgroundColor: canvas,
      body: Theme(
        data: theme.copyWith(
          scaffoldBackgroundColor: canvas,
          appBarTheme: theme.appBarTheme.copyWith(backgroundColor: canvas),
        ),
        child: widget.child,
      ),
      bottomNavigationBar: _isDetailRoute(context)
          ? null
          : AppNavigationBar(
              key: const Key('crew-navigation'),
              compact: true,
              selectedIndex: _calculateSelectedIndex(context),
              onSelected: (index) => _onItemTapped(index, context),
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: 'Home',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.map_outlined),
                  selectedIcon: Icon(Icons.map),
                  label: 'Route',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.task_outlined),
                  selectedIcon: Icon(Icons.task),
                  label: 'Tasks',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.description_outlined),
                  selectedIcon: Icon(Icons.description),
                  label: 'Reports',
                ),
                NavigationDestination(
                  icon: AppNavAvatar(source: avatar),
                  selectedIcon: AppNavAvatar(source: avatar),
                  label: 'Profile',
                ),
              ],
            ),
    );
  }
}
