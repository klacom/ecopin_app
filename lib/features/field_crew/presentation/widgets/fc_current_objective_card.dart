import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/core/theme/typography.dart';
import 'package:ecopin_app/features/field_crew/data/models/cleanup_task_model.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:logging/logging.dart';

final _log = Logger('FcCurrentObjectiveCard');

class FcCurrentObjectiveCard extends ConsumerWidget {
  final CleanupTask task;

  const FcCurrentObjectiveCard({super.key, required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String locationText = task.location.isNotEmpty ? task.location : 'Location not specified';
    LatLng? coordToGeocode;

    if (task.reports != null && task.reports!.isNotEmpty) {
      final loc = task.reports!.first.location;
      if (loc.latitude != 0 || loc.longitude != 0) {
        coordToGeocode = loc;
      }
    } else if (task.location.startsWith('POINT(')) {
      try {
        final parts = task.location.replaceAll('POINT(', '').replaceAll(')', '').split(' ');
        coordToGeocode = LatLng(double.parse(parts[1]), double.parse(parts[0]));
      } catch (_) {}
    }

    if (task.streetAddress != null && task.streetAddress!.isNotEmpty) {
      _log.info('Task ${task.id} has streetAddress: ${task.streetAddress}');
      locationText = task.streetAddress!;
    } else if (coordToGeocode != null) {
      _log.warning('Task ${task.id} streetAddress is missing. Falling back to coordinates.');
      locationText = '${coordToGeocode.latitude.toStringAsFixed(4)}, ${coordToGeocode.longitude.toStringAsFixed(4)}';
    } else {
      _log.warning('Task ${task.id} streetAddress AND coordinates are missing. Falling back to location: ${task.location}');
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primaryDark.withValues(alpha: 0.3)),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowFloating,
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildPriorityDot(task.priority),
                  const SizedBox(width: 8),
                  Text(
                    'Current Objective',
                    style: AppTypography.body.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            locationText,
            style: AppTypography.caption.copyWith(color: Colors.grey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            task.title,
            style: AppTypography.h4.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 24),
          InkWell(
            onTap: () => context.push('/field-crew/tasks/${task.id}'),
            child: Row(
              children: [
                Text(
                  'Start Task',
                  style: AppTypography.body.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: AppColors.primaryDark, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityDot(String priority) {
    final isHigh = priority.toLowerCase() == 'high' || priority.toLowerCase() == 'urgent';
    final color = isHigh ? AppColors.error : AppColors.info;
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
