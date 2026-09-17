import 'package:ecopin_app/shared/notifications/providers/notifications_provider.dart';
import 'package:ecopin_app/shared/profile/providers/profile_provider.dart';
import 'package:ecopin_app/core/services/location_service.dart';
import 'package:ecopin_app/shared/reports/data/models/report_prefill_data.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:ecopin_app/routes/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:badges/badges.dart' as badges;

// The layout that houses all the components that also goes wherever the user navigates to.
// It currently contains the NavBar.

class CitizenMainScreen extends ConsumerStatefulWidget {
  final Widget child;
  const CitizenMainScreen({super.key, required this.child});

  @override
  ConsumerState<CitizenMainScreen> createState() => _CitizenMainScreenState();
}

class _CitizenMainScreenState extends ConsumerState<CitizenMainScreen> {
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
    if (location.startsWith(ProtectedAppRoutes.maps)) return 0;
    if (location.startsWith(ProtectedAppRoutes.reports)) return 1;
    if (location.startsWith(ProtectedAppRoutes.notifications)) return 2;
    if (location.startsWith(ProtectedAppRoutes.profile)) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(ProtectedAppRoutes.maps);
        break;
      case 1:
        context.go(ProtectedAppRoutes.reports);
        break;
      case 2:
        context.go(ProtectedAppRoutes.notifications);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      body: widget.child,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      // Floating Action Button in the Center
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Fetch current GPS location, then open Create Report screen.
          final location = await LocationService.getCurrentLocation();
          if (context.mounted) {
            context.push(
              ProtectedAppRoutes.createReport,
              extra: ReportPrefillData(location: location),
            );
          }
        },
        elevation: 4,
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.black,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 28),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 72,
          margin: const EdgeInsets.symmetric(
            horizontal: AppColors.spaceMD,
            vertical: AppColors.spaceSM,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppColors.radiusCard),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildNavItem(
                0,
                Icons.map_outlined,
                Icons.map,
                'Maps',
                selectedIndex,
              ),
              _buildNavItem(
                1,
                Icons.location_on_outlined,
                Icons.location_on,
                'Reports',
                selectedIndex,
              ),
              const SizedBox(width: 56), // Space for FAB
              _buildNotificationNavItem(
                2,
                Icons.notifications_outlined,
                Icons.notifications,
                'Alerts',
                selectedIndex,
              ),
              _buildProfileNavItem(3, selectedIndex, avatarUrl, fullName),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileNavItem(
    int index,
    int selectedIndex,
    String? avatarUrl,
    String? fullName,
  ) {
    final isSelected = index == selectedIndex;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isSelected
        ? AppColors.accent
        : (isDark ? Colors.grey.shade600 : Colors.grey);

    return InkWell(
      onTap: () => _onItemTapped(index, context),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 26,
              height: 26,
              child: CircleAvatar(
                key: ValueKey(avatarUrl),
                radius: 13,
                backgroundColor: color,
                foregroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl == null || avatarUrl.isEmpty
                    ? Text(
                        _getInitials(fullName),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Profile',
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
    int selectedIndex,
  ) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider).value ?? 0;
    final isSelected = index == selectedIndex;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isSelected
        ? AppColors.accent
        : (isDark ? Colors.grey.shade600 : Colors.grey);

    return InkWell(
      onTap: () => _onItemTapped(index, context),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            badges.Badge(
              showBadge: unreadCount > 0,
              badgeContent: Text(
                unreadCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
              position: badges.BadgePosition.topEnd(top: -10, end: -10),
              child: Icon(isSelected ? activeIcon : icon, color: color, size: 24),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isSelected
        ? AppColors.accent
        : (isDark ? Colors.grey.shade600 : Colors.grey);

    return InkWell(
      onTap: () => _onItemTapped(index, context),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
