import 'package:flutter/material.dart';
import 'package:ecopin_app/routes/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/shared/profile/providers/profile_provider.dart';

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
    if (location.startsWith(FieldCrewAppRoutes.tasks)) return 1;
    if (location.startsWith(FieldCrewAppRoutes.reports)) return 2;
    if (location.startsWith(ProtectedAppRoutes.profile)) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(FieldCrewAppRoutes.dashboard);
        break;
      case 1:
        context.go(FieldCrewAppRoutes.tasks);
        break;
      case 2:
        context.go(FieldCrewAppRoutes.reports);
        break;
      case 3:
        context.go(ProtectedAppRoutes.profile);
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
              color: Colors.transparent,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildNavItem(0, Icons.dashboard_outlined, Icons.dashboard, 'Dashboard', selectedIndex),
                  _buildNavItem(1, Icons.task_outlined, Icons.task, 'Tasks', selectedIndex),
                  _buildNavItem(2, Icons.report_outlined, Icons.report, 'Reports', selectedIndex),
                  _buildProfileNavItem(3, selectedIndex, avatarUrl, fullName),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileNavItem(int index, int selectedIndex, String? avatarUrl, String? fullName) {
    final isSelected = index == selectedIndex;
    final color = isSelected ? Theme.of(context).colorScheme.primary : Colors.grey;

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
    final color = isSelected ? Theme.of(context).colorScheme.primary : Colors.grey;

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
