import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/core/theme/typography.dart';
import 'package:ecopin_app/features/field_crew/data/models/route_model.dart';
import 'package:ecopin_app/features/field_crew/data/models/waypoint_model.dart';
import 'package:ecopin_app/features/field_crew/data/models/cleanup_task_model.dart';
import 'package:go_router/go_router.dart';

class FcRouteTimelinePanel extends StatelessWidget {
  final RouteModel route;
  final List<CleanupTask> assignedTasks;

  const FcRouteTimelinePanel({
    super.key,
    required this.route,
    required this.assignedTasks,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: route.waypoints.length,
      itemBuilder: (context, index) {
        final wp = route.waypoints[index];
        final isLast = index == route.waypoints.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Timeline line and dot
              SizedBox(
                width: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (!isLast)
                      Positioned(
                        top: 24,
                        bottom: -24,
                        child: Container(
                          width: 2,
                          color: AppColors.dividerDark,
                        ),
                      ),
                    Positioned(
                      top: 0,
                      child: _buildWaypointMarker(wp),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppColors.spaceMD),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppColors.spaceLG),
                  child: _buildWaypointContent(context, wp),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWaypointMarker(WaypointModel wp) {
    if (wp.waypointType == 'depot_start' || wp.waypointType == 'depot_end') {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.dividerDark, width: 2),
        ),
        child: const Center(child: Text('🏢', style: TextStyle(fontSize: 16))),
      );
    }

    final taskInfo = _getTask(wp.cleanupTaskId);
    final isCompleted = taskInfo?.status == 'completed';
    final inProgress = taskInfo?.status == 'in_progress';

    Color bgColor = AppColors.primaryDark;
    Color textColor = Colors.black;

    if (isCompleted) {
      bgColor = AppColors.success;
      textColor = Colors.white;
    } else if (inProgress) {
      bgColor = AppColors.warning;
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.surfaceDark, width: 2),
      ),
      child: Center(
        child: Text(
          isCompleted ? '✓' : wp.sequenceOrder.toString(),
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildWaypointContent(BuildContext context, WaypointModel wp) {
    if (wp.waypointType == 'depot_start' || wp.waypointType == 'depot_end') {
      return Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SWMO Depot', style: AppTypography.body.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimaryDark)),
            Text(wp.waypointType == 'depot_start' ? 'Start shift' : 'End shift', style: AppTypography.caption.copyWith(color: Colors.grey)),
          ],
        ),
      );
    }

    final taskInfo = _getTask(wp.cleanupTaskId);
    final isCompleted = taskInfo?.status == 'completed';
    final inProgress = taskInfo?.status == 'in_progress';

    return Container(
      padding: const EdgeInsets.all(AppColors.spaceMD),
      decoration: BoxDecoration(
        color: isCompleted ? AppColors.success.withValues(alpha: 0.05) : (inProgress ? AppColors.warning.withValues(alpha: 0.05) : AppColors.surfaceDark),
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        border: Border.all(
          color: isCompleted ? AppColors.success.withValues(alpha: 0.3) : (inProgress ? AppColors.warning.withValues(alpha: 0.5) : AppColors.dividerDark),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            taskInfo?.title ?? 'Task #${wp.sequenceOrder}',
            style: AppTypography.body.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimaryDark),
          ),
          const SizedBox(height: AppColors.spaceSM),
          Row(
            children: [
              const Icon(Icons.route, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(_formatDistance(wp.distanceFromPreviousMeters), style: AppTypography.caption.copyWith(color: Colors.grey)),
              const SizedBox(width: AppColors.spaceMD),
              const Icon(Icons.timer, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(_formatDuration(wp.estimatedTimeFromPreviousMin), style: AppTypography.caption.copyWith(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: AppColors.spaceMD),
          if (taskInfo?.reports != null && taskInfo!.reports!.isNotEmpty) ...[
            const SizedBox(height: AppColors.spaceSM),
            const Divider(color: AppColors.dividerDark),
            const SizedBox(height: AppColors.spaceSM),
            Text('MICRO-ROUTE SEQUENCE', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: AppColors.spaceSM),
            ..._buildMicroRouteSequence(taskInfo, wp.sequenceOrder),
            const SizedBox(height: AppColors.spaceMD),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isCompleted ? AppColors.surfaceDark : AppColors.backgroundDark,
                foregroundColor: isCompleted ? Colors.grey : Colors.white,
                side: BorderSide(color: isCompleted ? AppColors.dividerDark : Colors.transparent),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppColors.radiusButton)),
              ),
              onPressed: isCompleted ? null : () {
                if (wp.cleanupTaskId != null) {
                  context.push('/field-crew/tasks/${wp.cleanupTaskId}');
                }
              },
              child: Text(
                isCompleted ? 'COMPLETED' : (inProgress ? 'RESUME TASK' : 'START TASK'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  CleanupTask? _getTask(String? id) {
    if (id == null) return null;
    try {
      return assignedTasks.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Widget> _buildMicroRouteSequence(CleanupTask task, int sequenceOrder) {
    if (task.reports == null) return [];
    
    // Sort reports according to reportSequence
    final sortedReports = List.of(task.reports!);
    sortedReports.sort((a, b) {
      int idxA = task.reportSequence.indexOf(a.id);
      int idxB = task.reportSequence.indexOf(b.id);
      if (idxA == -1) idxA = 999;
      if (idxB == -1) idxB = 999;
      return idxA.compareTo(idxB);
    });

    return sortedReports.asMap().entries.map((entry) {
      final idx = entry.key;
      final report = entry.value;
      final isPending = report.validationStatus == 'pending';
      final isResolved = report.status == 'resolved';

      return Padding(
        padding: const EdgeInsets.only(bottom: AppColors.spaceSM),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: isPending ? AppColors.info : AppColors.success,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '$sequenceOrder.${idx + 1}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
              ),
            ),
            const SizedBox(width: AppColors.spaceSM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (report.issueType ?? '').replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      color: isResolved ? Colors.grey : AppColors.textPrimaryDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      decoration: isResolved ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: isPending ? AppColors.info.withValues(alpha: 0.1) : AppColors.success.withValues(alpha: 0.1),
                      border: Border.all(color: isPending ? AppColors.info.withValues(alpha: 0.3) : AppColors.success.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isPending ? '🔍 Acknowledge & Validate' : '🧹 Start Cleanup',
                      style: TextStyle(
                        color: isPending ? AppColors.info : AppColors.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  String _formatDistance(num? meters) {
    if (meters == null) return '—';
    if (meters >= 1000) return '${(meters / 1000).toStringAsFixed(1)} km';
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
