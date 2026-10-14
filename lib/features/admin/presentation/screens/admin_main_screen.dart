import 'package:flutter/material.dart';
import 'package:ecopin_app/routes/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/shared/profile/providers/profile_provider.dart';
import 'package:ecopin_app/shared/widgets/app_navigation_bar.dart';

class AdminMainScreen extends ConsumerStatefulWidget {
  final Widget child;
  const AdminMainScreen({super.key, required this.child});

  @override
  ConsumerState<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends ConsumerState<AdminMainScreen> {
  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(AdminAppRoutes.dashboard)) return 0;
    if (location.startsWith(AdminAppRoutes.users)) return 1;
    if (location.startsWith(AdminAppRoutes.settings)) return 2;
    if (location.startsWith(AdminAppRoutes.auditLogs)) return 3;
    if (location.startsWith(AdminAppRoutes.profile)) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(AdminAppRoutes.dashboard);
        break;
      case 1:
        context.go(AdminAppRoutes.users);
        break;
      case 2:
        context.go(AdminAppRoutes.settings);
        break;
      case 3:
        context.go(AdminAppRoutes.auditLogs);
        break;
      case 4:
        context.go(AdminAppRoutes.profile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final avatar = profile.value?['avatar_url'] as String?;
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: AppNavigationBar(
        selectedIndex: _calculateSelectedIndex(context),
        onSelected: (index) => _onItemTapped(index, context),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Users',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
          const NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Logs',
          ),
          NavigationDestination(
            icon: AppNavAvatar(source: avatar),
            selectedIcon: AppNavAvatar(source: avatar),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
