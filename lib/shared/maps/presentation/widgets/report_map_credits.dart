import 'package:ecopin_app/core/theme/colors.dart';
import 'package:flutter/material.dart';

class ReportMapCredits extends StatelessWidget {
  const ReportMapCredits({super.key, required this.openSource});
  final void Function(Uri) openSource;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = TextButton.styleFrom(
      foregroundColor: theme.brightness == Brightness.dark
          ? AppColors.linkDark
          : AppColors.accent,
      textStyle: theme.textTheme.labelSmall,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      minimumSize: const Size(48, 48),
    );
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TextButton(
              style: style,
              onPressed: () => openSource(
                Uri.parse('https://www.openstreetmap.org/copyright'),
              ),
              child: const Text('© OpenStreetMap contributors'),
            ),
            TextButton(
              style: style,
              onPressed: () =>
                  openSource(Uri.parse('https://carto.com/attributions')),
              child: const Text('© CARTO'),
            ),
          ],
        ),
      ),
    );
  }
}
