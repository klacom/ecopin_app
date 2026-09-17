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

class CitizenMainScreen extends ConsumerStatefulWidget {
  final Widget child;
  const CitizenMainScreen({super.key, required this.child});

  @override
  ConsumerState<CitizenMainScreen> createState() => _CitizenMainScreenState();
}

class _CitizenMainScreenState extends ConsumerState<CitizenMainScreen> {
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
    final avatarUrl = profileAsync.value?['avatar_url'] as String?;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Navbar visual settings
    final navBgColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final navActiveColor = const Color(0xFF3300FF); // Accent requested by user
    final navInactiveColor = isDark
        ? Colors.grey.shade500
        : Colors.grey.shade400;

    return Scaffold(
      extendBody: true,
      body: widget.child,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Transform.translate(
        offset: const Offset(0, 20), // Push the FAB perfectly into the notch
        child: FloatingActionButton(
          onPressed: () async {
            final location = await LocationService.getCurrentLocation();
            if (context.mounted) {
              context.push(
                ProtectedAppRoutes.createReport,
                extra: ReportPrefillData(location: location),
              );
            }
          },
          elevation: 8,
          backgroundColor: navActiveColor, // 3300FF
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, size: 32),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CustomPaint(
                size: const Size(double.infinity, 72),
                painter: _CurvedNavbarPainter(
                  color: navBgColor,
                  shadowColor: Colors.black.withValues(alpha: 0.15),
                ),
              ),
              SizedBox(
                height: 72,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildAnimatedIcon(
                      0,
                      Icons.explore_outlined,
                      Icons.explore,
                      selectedIndex,
                      navActiveColor,
                      navInactiveColor,
                    ),
                    _buildAnimatedIcon(
                      1,
                      Icons.analytics_outlined,
                      Icons.analytics,
                      selectedIndex,
                      navActiveColor,
                      navInactiveColor,
                    ),
                    const SizedBox(width: 72), // Space for the cutout and FAB
                    _buildNotificationIcon(
                      2,
                      Icons.notifications_none_outlined,
                      Icons.notifications,
                      selectedIndex,
                      navActiveColor,
                      navInactiveColor,
                    ),
                    _buildProfileIcon(
                      3,
                      selectedIndex,
                      avatarUrl,
                      navActiveColor,
                      navInactiveColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon(
    int index,
    IconData outlineIcon,
    IconData filledIcon,
    int selectedIndex,
    Color activeColor,
    Color inactiveColor,
  ) {
    final isSelected = index == selectedIndex;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onItemTapped(index, context),
      child: Container(
        width: 48,
        height: 72, // Full height of navbar for easy tapping
        alignment: Alignment.center,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: Icon(
            isSelected ? filledIcon : outlineIcon,
            key: ValueKey<bool>(isSelected),
            color: isSelected ? activeColor : inactiveColor,
            size: 26,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(
    int index,
    IconData outlineIcon,
    IconData filledIcon,
    int selectedIndex,
    Color activeColor,
    Color inactiveColor,
  ) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider).value ?? 0;
    final isSelected = index == selectedIndex;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onItemTapped(index, context),
      child: Container(
        width: 48,
        height: 72,
        alignment: Alignment.center,
        child: badges.Badge(
          showBadge: unreadCount > 0,
          badgeContent: Text(
            unreadCount.toString(),
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
          position: badges.BadgePosition.topEnd(top: -5, end: -5),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOutBack,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Icon(
              isSelected ? filledIcon : outlineIcon,
              key: ValueKey<bool>(isSelected),
              color: isSelected ? activeColor : inactiveColor,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileIcon(
    int index,
    int selectedIndex,
    String? avatarUrl,
    Color activeColor,
    Color inactiveColor,
  ) {
    final isSelected = index == selectedIndex;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onItemTapped(index, context),
      child: Container(
        width: 48,
        height: 72,
        alignment: Alignment.center,
        child: AnimatedContainer(
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
            radius: 12,
            backgroundColor: inactiveColor,
            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                ? NetworkImage(avatarUrl)
                : null,
            child: avatarUrl == null || avatarUrl.isEmpty
                ? const Icon(Icons.person, size: 16, color: Colors.white)
                : null,
          ),
        ),
      ),
    );
  }
}

class _CurvedNavbarPainter extends CustomPainter {
  final Color color;
  final Color shadowColor;

  _CurvedNavbarPainter({required this.color, required this.shadowColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = shadowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    final path = Path();

    // Smooth Cutout parameters
    const double radius = 24.0; // Corner radius of the entire bar
    final double center = size.width / 2;
    const double cutoutRadius = 36.0; // Radius for the FAB cutout

    path.moveTo(0, radius);
    path.quadraticBezierTo(0, 0, radius, 0); // Top left corner

    // Draw the top line and cutout
    // We use a cubic bezier to make the dip very smooth and elegant
    path.lineTo(center - cutoutRadius - 20, 0);
    path.cubicTo(
      center - cutoutRadius,
      0,
      center - cutoutRadius + 10,
      cutoutRadius,
      center,
      cutoutRadius,
    );
    path.cubicTo(
      center + cutoutRadius - 10,
      cutoutRadius,
      center + cutoutRadius,
      0,
      center + cutoutRadius + 20,
      0,
    );

    path.lineTo(size.width - radius, 0);
    path.quadraticBezierTo(
      size.width,
      0,
      size.width,
      radius,
    ); // Top right corner
    path.lineTo(size.width, size.height - radius);
    path.quadraticBezierTo(
      size.width,
      size.height,
      size.width - radius,
      size.height,
    ); // Bottom right
    path.lineTo(radius, size.height);
    path.quadraticBezierTo(
      0,
      size.height,
      0,
      size.height - radius,
    ); // Bottom left
    path.close();

    // Draw shadow first
    canvas.drawPath(path, shadowPaint);
    // Draw actual background
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CurvedNavbarPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.shadowColor != shadowColor;
  }
}
