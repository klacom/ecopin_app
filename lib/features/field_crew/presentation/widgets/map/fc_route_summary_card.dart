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
    return Container(
      padding: const EdgeInsets.all(AppColors.spaceMD),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        border: Border.all(color: AppColors.dividerDark),
        boxShadow: const [
          BoxShadow(
            color: AppColors.dividerDark,
            offset: Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Route Summary', style: AppTypography.h5.copyWith(color: AppColors.textPrimaryDark)),
          const SizedBox(height: AppColors.spaceSM),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStat('STOPS', taskStopsCount.toString()),
              _buildStat('ETA', _formatDuration(route.totalDurationMin)),
              _buildStat('DIST', _formatDistance(route.totalDistanceMeters)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
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
            color: AppColors.textPrimaryDark,
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
