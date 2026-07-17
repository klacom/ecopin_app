import 'package:flutter/material.dart';
import 'package:ecopin_app/routes/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/features/profile/providers/profile_provider.dart';

class LguMainScreen extends ConsumerStatefulWidget {
  final Widget child;
  const LguMainScreen({super.key, required this.child});

  @override
  ConsumerState<LguMainScreen> createState() => _LguMainScreenState();
}

class _LguMainScreenState extends ConsumerState<LguMainScreen> {
  String _getInitials(String? fullName) {
    if (fullName == null || fullName.isEmpty) return '?';
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    } else {
      return parts[0][0].toUpperCase();
    }
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(LguAppRoutes.dashboard)) return 0;
    if (location.startsWith(LguAppRoutes.clusters)) return 1;
    if (location.startsWith(LguAppRoutes.cleanupTasks)) return 2;
    if (location.startsWith(LguAppRoutes.reports)) return 3;
    // More menu items don't affect index since they open a menu
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(LguAppRoutes.dashboard);
        break;
      case 1:
        context.go(LguAppRoutes.clusters);
        break;
      case 2:
        context.go(LguAppRoutes.cleanupTasks);
        break;
      case 3:
        context.go(LguAppRoutes.reports);
        break;
      case 4:
        _showMoreMenu(context);
        break;
    }
  }

  void _showMoreMenu(BuildContext context) {
    final profileAsync = ref.read(profileProvider);
    final fullName = profileAsync.value?['full_name'] as String?;
    final avatarUrl = profileAsync.value?['avatar_url'] as String?;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMoreMenuItem(
              icon: Icons.map_outlined,
              activeIcon: Icons.map,
              label: 'Map',
              route: LguAppRoutes.maps,
            ),
            const Divider(height: 1),
            _buildMoreMenuItem(
              icon: Icons.history_outlined,
              activeIcon: Icons.history,
              label: 'Logs',
              route: LguAppRoutes.responseLogs,
            ),
            const Divider(height: 1),
            _buildProfileMoreMenuItem(avatarUrl, fullName),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreMenuItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required String route,
  }) {
    final currentLocation = GoRouterState.of(context).matchedLocation;
    final isSelected = currentLocation.startsWith(route);
    final color = isSelected
        ? Theme.of(context).colorScheme.primary
        : Colors.grey;

    return InkWell(
      onTap: () {
        Navigator.pop(context);
        context.go(route);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Icon(isSelected ? activeIcon : icon, color: color, size: 24),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileMoreMenuItem(String? avatarUrl, String? fullName) {
    final currentLocation = GoRouterState.of(context).matchedLocation;
    final isSelected = currentLocation.startsWith(LguAppRoutes.profile);
    final color = isSelected
        ? Theme.of(context).colorScheme.primary
        : Colors.grey;

    return InkWell(
      onTap: () {
        Navigator.pop(context);
        context.go(LguAppRoutes.profile);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircleAvatar(
                key: ValueKey(avatarUrl),
                radius: 12,
                backgroundColor: color,
                foregroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl == null || avatarUrl.isEmpty
                    ? Text(
                        _getInitials(fullName),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Profile',
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);
    final profileAsync = ref.watch(profileProvider);
    final fullName = profileAsync.value?['full_name'] as String?;
    final avatarUrl = profileAsync.value?['avatar_url'] as String?;

    return Scaffold(
      extendBody: true,
      body: widget.child,
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          height: 70,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BottomAppBar(
              elevation: 0,
              color: Theme.of(context).colorScheme.surface,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildNavItem(
                    0,
                    Icons.dashboard_outlined,
                    Icons.dashboard,
                    'Dashboard',
                    selectedIndex,
                  ),
                  _buildNavItem(
                    1,
                    Icons.group_work_outlined,
                    Icons.group_work,
                    'Clusters',
                    selectedIndex,
                  ),
                  _buildNavItem(
                    2,
                    Icons.task_outlined,
                    Icons.task,
                    'Tasks',
                    selectedIndex,
                  ),
                  _buildNavItem(
                    3,
                    Icons.report_outlined,
                    Icons.report,
                    'Reports',
                    selectedIndex,
                  ),
                  _buildNavItem(
                    4,
                    Icons.menu_outlined,
                    Icons.menu,
                    'More',
                    selectedIndex,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
    int selectedIndex,
  ) {
    final isSelected = index == selectedIndex;
    final color = isSelected
        ? Theme.of(context).colorScheme.primary
        : Colors.grey;

    return InkWell(
      onTap: () => _onItemTapped(index, context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isSelected ? activeIcon : icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
