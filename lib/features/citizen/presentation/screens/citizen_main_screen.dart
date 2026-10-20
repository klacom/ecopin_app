import 'package:ecopin_app/shared/notifications/providers/notifications_provider.dart';
import 'package:ecopin_app/core/services/location_service.dart';
import 'package:ecopin_app/shared/reports/data/models/report_prefill_data.dart';
import '../widgets/citizen_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:ecopin_app/routes/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final unreadAsync = ref.watch(unreadNotificationsCountProvider);
    final unread = unreadAsync.value ?? 0;
    return Scaffold(
      extendBody: true,
      body: widget.child,
      bottomNavigationBar: CitizenNavigationBar(
        selectedIndex: selectedIndex,
        onSelected: (index) => _onItemTapped(index, context),
        onReport: _beginReport,
        isReporting: _findingLocation,
        unreadCount: unread,
        unreadLabel: unreadAsync.hasError
            ? 'Unread count unavailable'
            : unreadAsync.isLoading
            ? 'Loading unread count'
            : '$unread unread notifications',
      ),
    );
  }
}
