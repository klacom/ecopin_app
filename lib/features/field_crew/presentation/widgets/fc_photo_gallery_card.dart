import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/core/theme/typography.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
// import 'package:cached_network_image/cached_network_image.dart';

class FcPhotoGalleryCard extends StatelessWidget {
  final List<ReportModel> reports;

  const FcPhotoGalleryCard({super.key, required this.reports});

  @override
  Widget build(BuildContext context) {
    final List<String> beforePhotos = reports.map((r) => r.beforePhotoUrl).whereType<String>().toList();
    final List<String> afterPhotos = reports.map((r) => r.afterPhotoUrl).whereType<String>().toList();

    if (beforePhotos.isEmpty && afterPhotos.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppColors.spaceLG),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(AppColors.radiusCard),
          border: Border.all(color: AppColors.dividerDark),
        ),
        child: Center(
          child: Text('No photos uploaded yet.', style: AppTypography.body.copyWith(color: Colors.grey)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppColors.spaceLG),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        border: Border.all(color: AppColors.dividerDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Task Gallery', style: AppTypography.h5.copyWith(color: AppColors.textPrimaryDark)),
          const SizedBox(height: AppColors.spaceMD),
          if (beforePhotos.isNotEmpty) ...[
            Text('Before', style: AppTypography.label.copyWith(color: Colors.grey)),
            const SizedBox(height: AppColors.spaceSM),
            _buildPhotoGrid(context, beforePhotos),
            const SizedBox(height: AppColors.spaceMD),
          ],
          if (afterPhotos.isNotEmpty) ...[
            Text('After', style: AppTypography.label.copyWith(color: Colors.grey)),
            const SizedBox(height: AppColors.spaceSM),
            _buildPhotoGrid(context, afterPhotos),
          ],
        ],
      ),
    );
  }

  Widget _buildPhotoGrid(BuildContext context, List<String> urls) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        itemBuilder: (context, index) {
          final url = urls[index];
          return GestureDetector(
            onTap: () => _showLightbox(context, url),
            child: Container(
              margin: const EdgeInsets.only(right: AppColors.spaceSM),
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppColors.radiusCard),
                image: DecorationImage(
                  image: NetworkImage(url),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showLightbox(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
