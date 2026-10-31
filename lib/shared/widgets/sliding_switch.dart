import 'package:ecopin_app/core/theme/colors.dart';
import 'package:flutter/material.dart';

class SlidingSwitchOption {
  const SlidingSwitchOption({
    required this.label,
    this.icon,
    this.badge,
    this.semanticsLabel,
    this.liveRegion = false,
  });
  final String label;
  final IconData? icon;

  /// Count or progress shown beside the label.
  final Widget? badge;

  /// Accessible name when it should say more than [label].
  final String? semanticsLabel;
  final bool liveRegion;
}

/// Two-option switch: one track, a thumb that slides to the active option and
/// regular Outfit labels like the citizen navigation bar. Used for Map/List and
/// the Alerts All/Unread filter so the app has a single switch style.
class SlidingSwitch extends StatelessWidget {
  const SlidingSwitch({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onChanged,
  }) : assert(options.length == 2);

  final List<SlidingSwitchOption> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: dark ? scheme.surfaceContainerLowest : AppColors.tabCanvasLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            alignment: selectedIndex == 1
                ? Alignment.centerRight
                : Alignment.centerLeft,
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: FractionallySizedBox(
              widthFactor: .5,
              heightFactor: 1,
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: dark ? scheme.surfaceContainerHigh : Colors.white,
                    borderRadius: BorderRadius.circular(17),
                    boxShadow: dark
                        ? null
                        : const [
                            BoxShadow(
                              color: AppColors.shadowCard,
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ],
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (var i = 0; i < 2; i++)
                Expanded(child: _option(context, i, options[i])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _option(BuildContext context, int index, SlidingSwitchOption option) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final selected = selectedIndex == index;
    final accent = dark ? AppColors.linkDark : AppColors.primary;
    final color = selected
        ? accent
        : dark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final roomy = MediaQuery.textScalerOf(context).scale(14) <= 18.2;
    return Semantics(
      button: true,
      selected: selected,
      label: option.semanticsLabel ?? option.label,
      liveRegion: option.liveRegion,
      excludeSemantics: true,
      onTap: () => onChanged(index),
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: () => onChanged(index),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (roomy && option.icon != null) ...[
                Icon(option.icon, size: 18, color: color),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  option.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                    letterSpacing: 0,
                    color: color,
                  ),
                ),
              ),
              if (option.badge != null) ...[
                const SizedBox(width: 6),
                option.badge!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Small tinted count that sits beside a [SlidingSwitchOption] label.
class SwitchCountBadge extends StatelessWidget {
  const SwitchCountBadge(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = dark ? AppColors.linkDark : AppColors.primary;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
            color: accent,
          ),
        ),
      ),
    );
  }
}
