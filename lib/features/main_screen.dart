import 'package:ecopin_app/features/notifications/providers/notifications_provider.dart';
import 'package:ecopin_app/core/services/location_service.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import 'package:ecopin_app/features/maps/presentation/screens/maps_screen.dart';
import 'package:ecopin_app/routes/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:badges/badges.dart' as badges;

// The layout that houses all the components that also goes wherever the user navigates to. It currently contains the NavBar.

class MainScreen extends ConsumerStatefulWidget {
  final Widget child;
  const MainScreen({super.key, required this.child});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
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

    return Scaffold(
      extendBody: true,
      body: widget.child,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      // Floating Action Button in the Center
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Fetch current GPS location
          final location = await LocationService.getCurrentLocation();
          if (context.mounted) {
            // If location is null, the CreateReportScreen will fallback to default coordinates
            context.push(ProtectedAppRoutes.createReport, extra: location);
          }
        },
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white,
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
              shape: const CircularNotchedRectangle(),
              notchMargin: 8,
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
                  const SizedBox(width: 40), // Space for FAB
                  _buildNotificationNavItem(
                    2,
                    Icons.notifications_outlined,
                    Icons.notifications,
                    'Alerts',
                    selectedIndex,
                  ),
                  _buildNavItem(
                    3,
                    Icons.person_outline,
                    Icons.person,
                    'Profile',
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

  Widget _buildNotificationNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
    int selectedIndex,
  ) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider).value ?? 0;
    final isSelected = index == selectedIndex;
    final color = isSelected ? Theme.of(context).primaryColor : Colors.grey;

    return InkWell(
      onTap: () => _onItemTapped(index, context),
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
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
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
    final color = isSelected ? Theme.of(context).primaryColor : Colors.grey;

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
