import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:ecopin_app/core/theme/colors.dart';

class FcShimmerList extends StatelessWidget {
  final int itemCount;

  const FcShimmerList({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppColors.spaceLG, vertical: AppColors.spaceMD),
      itemCount: itemCount,
      separatorBuilder: (context, index) => const SizedBox(height: AppColors.spaceMD),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: AppColors.surfaceDark,
          highlightColor: AppColors.surfaceDark.withValues(alpha: 0.5),
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppColors.radiusCard),
            ),
          ),
        );
      },
    );
  }
}
