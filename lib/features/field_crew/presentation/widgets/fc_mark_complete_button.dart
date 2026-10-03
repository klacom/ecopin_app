import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';
import 'package:ecopin_app/core/theme/typography.dart';
import 'package:ecopin_app/features/field_crew/data/models/cleanup_task_model.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FcMarkCompleteButton extends StatelessWidget {
  final CleanupTask task;
  final List<ReportModel> reports;
  final VoidCallback onComplete;

  const FcMarkCompleteButton({
    super.key,
    required this.task,
    required this.reports,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isAssigned = currentUserId != null && task.assignedCrewIds.contains(currentUserId);
    
    if (!isAssigned) {
      return const SizedBox.shrink();
    }

    if (task.status == 'completed') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.check_circle, color: AppColors.success),
          label: Text('Task Completed', style: AppTypography.button.copyWith(color: AppColors.success)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.surfaceDark,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppColors.radiusButton)),
            disabledBackgroundColor: AppColors.surfaceDark,
          ),
        ),
      );
    }

    bool allReportsResolved = true;
    bool hasBefore = task.beforePhotoUrl != null;
    bool hasAfter = task.afterPhotoUrl != null;

    for (var r in reports) {
      bool isScouting = r.issueType == 'scouting' || r.issueType == 'acknowledge_only';
      bool isResolved = r.status.toLowerCase() == 'resolved' || r.status.toLowerCase() == 'closed';
      
      if (isScouting) {
        if (r.validationStatus.toLowerCase() != 'validated' && !isResolved) {
          allReportsResolved = false;
        }
      } else {
        if (!isResolved) {
          allReportsResolved = false;
        }
      }
      
      if (r.beforePhotoUrl != null) hasBefore = true;
      if (r.afterPhotoUrl != null) hasAfter = true;
    }

    bool canComplete = allReportsResolved && hasBefore && hasAfter;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canComplete ? onComplete : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: AppColors.backgroundDark,
          disabledBackgroundColor: AppColors.surfaceDark,
          disabledForegroundColor: Colors.grey,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppColors.radiusButton)),
        ),
        child: Text(
          canComplete ? 'Mark Task Complete' : 'Cannot Complete Yet',
          style: AppTypography.button,
        ),
      ),
    );
  }
}
