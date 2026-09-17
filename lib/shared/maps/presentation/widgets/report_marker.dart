import 'package:flutter/material.dart';
import 'package:ecopin_app/core/theme/colors.dart';

class ReportMarker extends StatelessWidget {
  final String status;

  const ReportMarker({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toLowerCase()) {
      case 'resolved':
      case 'closed':
        color = AppColors.success;
        break;
      case 'in progress':
      case 'acknowledged':
      case 'waiting_for_feedback':
        color = AppColors.warning;
        break;
      case 'pending_owner_consent':
        color = AppColors.info;
        break;
      default:
        color = AppColors.error;
        break;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Transform.rotate(
      angle: -0.2,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          border: Border.all(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight, 
            width: 3
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? color : AppColors.shadowCard,
              offset: const Offset(4, 4),
            ),
          ],
        ),
        child: const Icon(Icons.center_focus_strong, color: Colors.black, size: 20),
      ),
    );
  }
}
