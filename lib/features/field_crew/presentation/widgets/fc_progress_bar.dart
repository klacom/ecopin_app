import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/core/theme/typography.dart';

class FcProgressBar extends StatelessWidget {
  final int current;
  final int total;
  final String label;

  const FcProgressBar({
    super.key,
    required this.current,
    required this.total,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = total == 0 ? 0 : current / total;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.caption.copyWith(color: AppColors.textPrimaryDark)),
            Text('$current/$total', style: AppTypography.caption.copyWith(color: AppColors.primaryDark)),
          ],
        ),
        const SizedBox(height: AppColors.spaceSM),
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            FractionallySizedBox(
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryDark.withValues(alpha: 0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
