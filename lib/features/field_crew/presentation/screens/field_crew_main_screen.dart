import 'package:flutter/material.dart';
import 'package:ecopin_app/routes/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/shared/profile/providers/profile_provider.dart';
import 'package:ecopin_app/core/theme/colors.dart';

class FieldCrewMainScreen extends ConsumerStatefulWidget {
  final Widget child;
  const FieldCrewMainScreen({super.key, required this.child});

  @override
  ConsumerState<FieldCrewMainScreen> createState() => _FieldCrewMainScreenState();
}

class _FieldCrewMainScreenState extends ConsumerState<FieldCrewMainScreen> {
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
    if (location.startsWith(FieldCrewAppRoutes.dashboard)) return 0;
    if (location.startsWith(FieldCrewAppRoutes.map)) return 1;
    if (location.startsWith(FieldCrewAppRoutes.tasks)) return 2;
    if (location.startsWith(FieldCrewAppRoutes.reports)) return 3;
    if (location.startsWith(FieldCrewAppRoutes.profile)) return 4;
    return 0;
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
    final selectedIndex = _calculateSelectedIndex(context);
    final profileAsync = ref.watch(profileProvider);
    final fullName = profileAsync.value?['full_name'] as String?;
    final avatarUrl = profileAsync.value?['avatar_url'] as String?;

    return Scaffold(
      extendBody: true,
      body: widget.child,
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark ? AppColors.surfaceDark : AppColors.surfaceLight,
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowCard,
                blurRadius: 16,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: BottomAppBar(
            elevation: 0,
            color: Colors.transparent,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildNavItem(0, Icons.dashboard_outlined, Icons.dashboard, 'Dashboard', selectedIndex),
                  _buildNavItem(1, Icons.map_outlined, Icons.map, 'Map', selectedIndex),
                  _buildNavItem(2, Icons.task_outlined, Icons.task, 'Tasks', selectedIndex),
                  _buildNavItem(3, Icons.report_outlined, Icons.report, 'Reports', selectedIndex),
                  _buildProfileNavItem(4, selectedIndex, avatarUrl, fullName),
                ],
              ),
            ),
          ),
        ),
    );
  }

  Widget _buildProfileNavItem(int index, int selectedIndex, String? avatarUrl, String? fullName) {
    final isSelected = index == selectedIndex;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isSelected ? (isDark ? AppColors.primaryLight : Colors.black) : Colors.grey;

    return InkWell(
      onTap: () => _onItemTapped(index, context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircleAvatar(
              key: ValueKey(avatarUrl),
              radius: 12,
              backgroundColor: color,
              foregroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null || avatarUrl.isEmpty
                  ? Text(
                      _getInitials(fullName),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Profile',
            style: TextStyle(color: color, fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label, int selectedIndex) {
    final isSelected = index == selectedIndex;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isSelected ? (isDark ? AppColors.primaryLight : Colors.black) : Colors.grey;

    return InkWell(
      onTap: () => _onItemTapped(index, context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isSelected ? activeIcon : icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
          ),
        ],
      ),
    );
  }
}
