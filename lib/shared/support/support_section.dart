import 'package:ecopin_app/core/theme/colors.dart';
import 'package:flutter/material.dart';

class SupportSection extends StatelessWidget {
  const SupportSection({
    super.key,
    required this.title,
    required this.children,
    this.quiet = false,
    this.icon,
  });

  final String title;
  final List<Widget> children;
  final bool quiet;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Card(
      margin: EdgeInsets.zero,
      color: quiet
          ? dark
                ? AppColors.quietSurfaceDark
                : AppColors.quietSurfaceLight
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        side: quiet
            ? BorderSide.none
            : BorderSide(
                color: dark ? AppColors.dividerDark : AppColors.dividerLight,
              ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppColors.spaceMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  ExcludeSemantics(
                    child: Icon(
                      icon,
                      color: dark ? AppColors.linkDark : AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(title, style: theme.textTheme.titleMedium),
                  ),
                ),
              ],
            ),
            for (final child in children) ...[
              const SizedBox(height: 12),
              child,
            ],
          ],
        ),
      ),
    );
  }
}
