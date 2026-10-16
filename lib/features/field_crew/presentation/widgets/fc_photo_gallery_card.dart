import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/core/theme/typography.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import 'package:ecopin_app/shared/widgets/private_media_image.dart';

class FcPhotoGalleryCard extends StatelessWidget {
  final List<ReportModel> reports;

  const FcPhotoGalleryCard({super.key, required this.reports});

  @override
  Widget build(BuildContext context) {
    final List<String> beforePhotos = reports.map((r) => r.beforePhotoUrl).whereType<String>().toList();
    final List<String> afterPhotos = reports.map((r) => r.afterPhotoUrl).whereType<String>().toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? Colors.white10 : Colors.grey.shade100;
    final textColor = isDark ? AppColors.textPrimaryDark : Colors.black87;

    if (beforePhotos.isEmpty && afterPhotos.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppColors.spaceLG),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(AppColors.radiusCard),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
          border: Border.all(color: borderColor),
        ),
        child: Center(
          child: Text('No photos uploaded yet.', style: AppTypography.body.copyWith(color: Colors.grey)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppColors.spaceLG),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Task Gallery', style: AppTypography.h5.copyWith(color: textColor)),
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
              ),
              clipBehavior: Clip.antiAlias,
              child: PrivateMediaImage(
                url,
                fit: BoxFit.cover,
                width: 100,
                height: 100,
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
              child: PrivateMediaImage(
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
