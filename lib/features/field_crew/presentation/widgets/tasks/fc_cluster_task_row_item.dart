import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/core/theme/typography.dart';

class FcClusterTaskRowItem extends StatelessWidget {
  final String title;
  final String location;
  final String distance;
  final VoidCallback onTrack;
  final VoidCallback? onTap;

  const FcClusterTaskRowItem({
    super.key,
    required this.title,
    required this.location,
    required this.distance,
    required this.onTrack,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppColors.radiusCard),
      child: Container(
        padding: const EdgeInsets.all(AppColors.spaceMD),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(AppColors.radiusCard),
          border: Border.all(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowCard,
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon Placeholder
            Container(
              padding: const EdgeInsets.all(AppColors.spaceSM),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppColors.radiusButton),
              ),
              child: Icon(
                Icons.location_on,
                color: theme.colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: AppColors.spaceMD),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppColors.spaceXS),
                  Row(
                    children: [
                      Icon(
                        Icons.navigation,
                        size: 14,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '$distance • $location',
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppColors.spaceMD),
            // Track Button
            OutlinedButton.icon(
              onPressed: onTrack,
              icon: const Icon(Icons.map, size: 16),
              label: const Text('Track'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppColors.spaceMD,
                  vertical: AppColors.spaceSM,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
