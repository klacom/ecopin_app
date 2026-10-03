import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/core/theme/typography.dart';
import 'package:ecopin_app/features/field_crew/data/models/cleanup_task_model.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:logging/logging.dart';

final _log = Logger('FcTaskQueueCard');

class FcTaskQueueCard extends ConsumerWidget {
  final CleanupTask task;

  const FcTaskQueueCard({super.key, required this.task});

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

    return InkWell(
      onTap: () => context.push('/field-crew/tasks/${task.id}'),
      borderRadius: BorderRadius.circular(AppColors.radiusCard),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppColors.spaceSM),
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: Colors.transparent,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.cleaning_services, color: AppColors.primaryDark, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: AppTypography.body.copyWith(color: AppColors.textPrimaryDark, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    locationText,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildStatusText(task.status),
                const SizedBox(height: 4),
                Text(
                  task.id.length > 8 ? task.id.substring(0, 8).toUpperCase() : task.id.toUpperCase(),
                  style: const TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 0.5),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusText(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'completed':
        color = AppColors.success;
        break;
      case 'in_progress':
        color = AppColors.info;
        break;
      default:
        color = Colors.grey;
    }
    
    return Text(
      status.length > 1 ? status[0].toUpperCase() + status.substring(1).toLowerCase() : status,
      style: TextStyle(
        color: color, 
        fontSize: 12, 
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
