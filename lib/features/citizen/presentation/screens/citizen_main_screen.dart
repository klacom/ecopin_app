import 'package:ecopin_app/shared/notifications/providers/notifications_provider.dart';
import 'package:ecopin_app/shared/profile/providers/profile_provider.dart';
import 'package:ecopin_app/core/services/location_service.dart';
import 'package:ecopin_app/shared/reports/data/models/report_prefill_data.dart';
import 'package:ecopin_app/shared/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:ecopin_app/routes/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/shared/widgets/app_navigation_bar.dart';

class CitizenMainScreen extends ConsumerStatefulWidget {
  final Widget child;
  const CitizenMainScreen({super.key, required this.child});

  @override
  ConsumerState<CitizenMainScreen> createState() => _CitizenMainScreenState();
}

class _CitizenMainScreenState extends ConsumerState<CitizenMainScreen> {
  bool _findingLocation = false;

  Future<void> _beginReport() async {
    if (_findingLocation) return;
    setState(() => _findingLocation = true);
    try {
      final location = await LocationService.getCurrentLocation();
      if (!mounted) return;
      if (location == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Your current location could not be found. Choose the concern’s location on the next map.',
            ),
          ),
        );
      }
      context.push(
        ProtectedAppRoutes.createReport,
        extra: ReportPrefillData(location: location),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location could not load. Try again or check your location settings.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _findingLocation = false);
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
    final unreadAsync = ref.watch(unreadNotificationsCountProvider);
    final unread = unreadAsync.value ?? 0;
    Widget alertsIcon(IconData icon) => Semantics(
      label: unreadAsync.hasError
          ? 'Unread count unavailable'
          : unreadAsync.isLoading
          ? 'Loading unread count'
          : '$unread unread notifications',
      excludeSemantics: true,
      child: Badge(
        isLabelVisible: unread > 0,
        label: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.3,
          child: Text(
            unread > 99 ? '99+' : '$unread',
            style: const TextStyle(fontSize: 12),
          ),
        ),
        child: Icon(icon),
      ),
    );
    return Scaffold(
      body: widget.child,
      floatingActionButton: Tooltip(
        message: 'Report an environmental concern',
        child: AppButton(
          width: (MediaQuery.sizeOf(context).width - 32)
              .clamp(0.0, 360.0)
              .toDouble(),
          text: _findingLocation ? 'Finding location…' : 'Report a concern',
          icon: Icons.add_a_photo_outlined,
          isLoading: _findingLocation,
          onPressed: _findingLocation ? null : _beginReport,
        ),
      ),
      bottomNavigationBar: AppNavigationBar(
        selectedIndex: selectedIndex,
        onSelected: (index) => _onItemTapped(index, context),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
            tooltip: 'Explore map',
          ),
          const NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: 'My reports',
          ),
          NavigationDestination(
            icon: alertsIcon(Icons.notifications_outlined),
            selectedIcon: alertsIcon(Icons.notifications),
            label: 'Alerts',
            tooltip: 'Notifications',
          ),
          NavigationDestination(
            icon: AppNavAvatar(
              source: profileAsync.value?['avatar_url'] as String?,
            ),
            selectedIcon: AppNavAvatar(
              source: profileAsync.value?['avatar_url'] as String?,
            ),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
