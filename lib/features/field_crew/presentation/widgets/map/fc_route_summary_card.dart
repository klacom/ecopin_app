import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/core/theme/typography.dart';
import 'package:ecopin_app/features/field_crew/data/models/route_model.dart';

class FcRouteSummaryCard extends StatelessWidget {
  final RouteModel route;
  final int taskStopsCount;

  const FcRouteSummaryCard({
    super.key,
    required this.route,
    required this.taskStopsCount,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? Colors.white10 : Colors.grey.shade100;
    final textColor = isDark ? AppColors.textPrimaryDark : Colors.black87;

    return Container(
      padding: const EdgeInsets.all(AppColors.spaceMD),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        border: Border.all(color: borderColor),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Route Summary', style: AppTypography.h5.copyWith(color: textColor)),
          const SizedBox(height: AppColors.spaceSM),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStat('STOPS', taskStopsCount.toString(), textColor),
              _buildStat('ETA', _formatDuration(route.totalDurationMin), textColor),
              _buildStat('DIST', _formatDistance(route.totalDistanceMeters), textColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: Colors.grey,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.body.copyWith(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _formatDistance(num? meters) {
    if (meters == null) return '—';
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.round()} m';
  }

  String _formatDuration(num? minutes) {
    if (minutes == null) return '—';
    final h = (minutes / 60).floor();
    final m = (minutes % 60).round();
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}
