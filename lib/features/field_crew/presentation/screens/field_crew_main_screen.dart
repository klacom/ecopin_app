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
    final selectedIndex = _calculateSelectedIndex(context);
    final isDetail = _isDetailRoute(context);
    final profileAsync = ref.watch(profileProvider);
    final fullName = profileAsync.value?['full_name'] as String?;
    final avatarUrl = profileAsync.value?['avatar_url'] as String?;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Navbar visual settings matching Citizen style
    final navBgColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final navActiveColor = AppColors.primaryDark; // Neon Lime for Field Crew
    final navInactiveColor = isDark ? Colors.grey.shade500 : Colors.grey.shade400;

    return Scaffold(
      // Only extend body behind the navbar on primary tabs so detail screens
      // use the full viewport without any bottom inset reserved for the bar.
      extendBody: !isDetail,
      body: widget.child,
      bottomNavigationBar: isDetail
          ? null
          : SafeArea(
        child: Container(
          height: 84, // Increased height for labels
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          decoration: BoxDecoration(
            color: navBgColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildAnimatedNavItem(0, Icons.dashboard_outlined, Icons.dashboard, 'Command Center', selectedIndex, navActiveColor, navInactiveColor),
              _buildAnimatedNavItem(1, Icons.route_outlined, Icons.route, 'My Route', selectedIndex, navActiveColor, navInactiveColor),
              _buildAnimatedNavItem(2, Icons.handyman_outlined, Icons.handyman, 'Operations', selectedIndex, navActiveColor, navInactiveColor),
              _buildAnimatedNavItem(3, Icons.table_chart_outlined, Icons.table_chart, 'Raw Data', selectedIndex, navActiveColor, navInactiveColor),
              _buildProfileNavItem(4, selectedIndex, avatarUrl, fullName, navActiveColor, navInactiveColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileNavItem(int index, int selectedIndex, String? avatarUrl, String? fullName, Color activeColor, Color inactiveColor) {
    final isSelected = index == selectedIndex;

    return Tooltip(
      message: 'Profile',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onItemTapped(index, context),
        child: Container(
          width: 56,
          height: 84,
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: EdgeInsets.all(isSelected ? 2 : 0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? activeColor : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  key: ValueKey(avatarUrl),
                  radius: 12,
                  backgroundColor: inactiveColor,
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
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? activeColor : inactiveColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedNavItem(int index, IconData outlineIcon, IconData filledIcon, String label, int selectedIndex, Color activeColor, Color inactiveColor) {
    final isSelected = index == selectedIndex;
    final color = isSelected ? activeColor : inactiveColor;

    return Tooltip(
      message: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onItemTapped(index, context),
        child: Container(
          width: 64,
          height: 84,
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                child: Icon(
                  isSelected ? filledIcon : outlineIcon,
                  key: ValueKey<bool>(isSelected),
                  color: color,
                  size: 24, // Slightly smaller to fit label
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
