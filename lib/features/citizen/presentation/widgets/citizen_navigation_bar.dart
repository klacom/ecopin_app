import 'package:ecopin_app/core/theme/colors.dart';
import 'package:flutter/material.dart';

// icons_plus 5.0.0 subclasses the now-final IconData. Use its bundled font
// directly until the package supports this SDK (Bootstrap codepoints from 5.0.0).
const _mapIcon = IconData(
  0xee30,
  fontFamily: 'Bootstrap',
  fontPackage: 'icons_plus',
);
const _reportsIcon = IconData(
  0xecb8,
  fontFamily: 'Bootstrap',
  fontPackage: 'icons_plus',
);
const _alertsIcon = IconData(
  0xe9dc,
  fontFamily: 'Bootstrap',
  fontPackage: 'icons_plus',
);
const _profileIcon = IconData(
  0xeea9,
  fontFamily: 'Bootstrap',
  fontPackage: 'icons_plus',
);
const _reportIcon = IconData(
  0xeaa2,
  fontFamily: 'Bootstrap',
  fontPackage: 'icons_plus',
);

/// Citizen destinations flank the raised report action; indices stay route-based.
class CitizenNavigationBar extends StatelessWidget {
  const CitizenNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.onReport,
    required this.isReporting,
    required this.unreadCount,
    required this.unreadLabel,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onReport;
  final bool isReporting;
  final int unreadCount;
  final String unreadLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final surface = theme.colorScheme.surface;
    final selected = dark ? AppColors.linkDark : AppColors.primary;
    final muted = dark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final bottom = MediaQuery.paddingOf(context).bottom;
    const labels = ['Map', 'Reports', 'Alerts', 'Profile'];
    const icons = [_mapIcon, _reportsIcon, _alertsIcon, _profileIcon];

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: SizedBox(
        key: const Key('citizen-navigation'),
        width: double.infinity,
        height: 104 + bottom,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Positioned.fill(
              top: 24,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
              ),
            ),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: surface, shape: BoxShape.circle),
            ),
            Positioned(
              top: 24,
              left: 0,
              right: 0,
              height: 80,
              child: Row(
                children: [
                  for (var slot = 0; slot < 5; slot++)
                    if (slot == 2)
                      Expanded(
                        child: ExcludeSemantics(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 36),
                            child: Text(
                              'Report',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: muted,
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            final index = slot < 2 ? slot : slot - 1;
                            Widget icon = Icon(icons[index], size: 24);
                            if (index == 2) {
                              icon = Badge(
                                isLabelVisible: unreadCount > 0,
                                label: Text(
                                  unreadCount > 99 ? '99+' : '$unreadCount',
                                ),
                                child: icon,
                              );
                            }
                            return _Destination(
                              label: labels[index],
                              hint: index == 2 ? unreadLabel : null,
                              selected: selectedIndex == index,
                              color: selectedIndex == index ? selected : muted,
                              icon: icon,
                              onPressed: () => onSelected(index),
                            );
                          },
                        ),
                      ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              child: Semantics(
                liveRegion: isReporting,
                child: SizedBox.square(
                  dimension: 56,
                  child: FloatingActionButton(
                    heroTag: null,
                    tooltip: isReporting
                        ? 'Finding location…'
                        : 'Report an environmental concern',
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: const CircleBorder(),
                    onPressed: isReporting ? null : onReport,
                    child: ExcludeSemantics(
                      child: isReporting
                          ? const SizedBox.square(
                              dimension: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(_reportIcon, size: 26),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Destination extends StatelessWidget {
  const _Destination({
    required this.label,
    this.hint,
    required this.selected,
    required this.color,
    required this.icon,
    required this.onPressed,
  });
  final String label;
  final String? hint;
  final bool selected;
  final Color color;
  final Widget icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Semantics(
      selected: selected,
      label: label,
      hint: hint,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: color,
          minimumSize: const Size(48, 80),
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: ExcludeSemantics(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 16,
                height: 2,
                decoration: BoxDecoration(
                  color: selected ? color : Colors.transparent,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              const SizedBox(height: 6),
              icon,
              const SizedBox(height: 4),
              Text(
                label,
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
  );
}
