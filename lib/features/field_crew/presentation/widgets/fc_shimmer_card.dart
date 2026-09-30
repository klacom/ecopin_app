import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:ecopin_app/core/theme/colors.dart';

class FcShimmerCard extends StatelessWidget {
  final double height;

  const FcShimmerCard({super.key, this.height = 160});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceDark,
      highlightColor: AppColors.surfaceDark.withValues(alpha: 0.5),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppColors.radiusCard),
        ),
      ),
    );
  }
}
