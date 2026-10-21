import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'private_media_image.dart';

class AppNavigationBar extends StatelessWidget {
  const AppNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.destinations,
    this.compact = false,
  });
  final bool compact;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<NavigationDestination> destinations;
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final selected = dark ? AppColors.linkDark : AppColors.accent;
    final muted = dark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    if (compact) {
      return MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                for (var i = 0; i < destinations.length; i++)
                  Expanded(
                    child: Semantics(
                      selected: selectedIndex == i,
                      child: TextButton(
                        onPressed: () => onSelected(i),
                        style: TextButton.styleFrom(
                          foregroundColor: selectedIndex == i
                              ? selected
                              : muted,
                          minimumSize: const Size(48, 80),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 16,
                              height: 2,
                              decoration: BoxDecoration(
                                color: selectedIndex == i
                                    ? selected
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                            const SizedBox(height: 6),
                            IconTheme(
                              data: IconThemeData(
                                size: 24,
                                color: selectedIndex == i ? selected : muted,
                              ),
                              child: selectedIndex == i
                                  ? destinations[i].selectedIcon ??
                                        destinations[i].icon
                                  : destinations[i].icon,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              destinations[i].label,
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                height: 1.3,
                                letterSpacing: 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        indicatorColor: selected.withValues(alpha: .12),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: 'Outfit',
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
            color: states.contains(WidgetState.selected) ? selected : muted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected) ? selected : muted,
          ),
        ),
      ),
      child: NavigationBar(
        height: math.max(
          80,
          MediaQuery.textScalerOf(
                    context,
                  ).clamp(maxScaleFactor: 1.3).scale(14) *
                  2 +
              48,
        ),
        animationDuration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 200),
        selectedIndex: selectedIndex,
        onDestinationSelected: onSelected,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: destinations,
      ),
    );
  }
}

class AppNavAvatar extends StatelessWidget {
  const AppNavAvatar({super.key, this.source});
  final String? source;
  @override
  Widget build(BuildContext context) => source == null || source!.trim().isEmpty
      ? const Icon(Icons.person_outline)
      : ClipOval(
          child: PrivateMediaImage(
            source!,
            width: 28,
            height: 28,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) =>
                const Icon(Icons.person_outline),
            placeholder: (context, url) => const Icon(Icons.person_outline),
            errorWidget: (context, url, error) =>
                const Icon(Icons.person_outline),
          ),
        );
}
